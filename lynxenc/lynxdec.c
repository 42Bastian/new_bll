/* Atari Lynx Decryption Tool
 * Copyright (C) 2009 David Huseby <dave@linuxprogrammer.org>
 *
 * NOTES:
 *
 * This software is original software written completely by me, but there are
 * pieces of data (e.g. the keys.h and loaders.h files) that I got from the
 * Atari Age Lynx Programming forum and from people in the Lynx community,
 * namely Karri Kaksonen.  Without their help, this would have never been
 * possible.  I was standing on the shoulders of giants.
 *
 * According to the documentation on RSA, the way the public/private
 * exponents are related is that encryption works like so:
 *
 * encrypted = (plaintext ^ private exponent) % public modulus
 *
 * decryption, which we already have working, works like this:
 *
 * plaintext = (encrypted ^ public exponent) % public modulus
 *
 * The keys.h file contains definitions for the Lynx public exponent,
 * private exponent and the public modulus.
 *
 * This app shows how to take an encrypted loader, decrypt it and un-pad
 * it, all using the C and the OpenSSL bignum library for the RSA step.
 *
 * The trick is knowing how to properly frame the encrypted blocks.
 * Harry's plaintext loader has two sections in it, one that starts at
 * offset 0 and is 150 bytes long, and another that starts at offset 256
 * and is 250 bytes long.
 *
 * What I discovered is that the encrypted loader is broken up into frames.
 * Each frame starts with a single byte that specifies how many blocks are
 * in the frame.  The frames are packed together without any padding between
 * them.  The block count byte has the value 256 - block count.
 *
 * Another thing I discovered was that the unencrypted data is processed in
 * 50 byte chunks.  Each chunk is padded out to 51 bytes before being
 * encrypted using the private exponent and public modulus.
 *
 * LICENSE:
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from the
 * use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 * claim that you wrote the original software. If you use this software in a
 * product, an acknowledgment in the product documentation would be appreciated
 * but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source distribution.
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/bn.h>
#include "sizes.h"
#include "keys.h"


typedef struct encrypted_frame_s
{
    int blocks;
    unsigned char data[MAX_ENCRYPTED_FRAME_SIZE];
} encrypted_frame_t;


#define min(x,y) ((x < y) ? x : y)
void print_data(const unsigned char * data, int size)
{
    int i = 0;
    int j, count;
    int left = size;

    while(i < size)
    {
        count = min(8, (size - i));

        printf("    ");
        for(j = 0; j < count; j++)
        {
            printf("0x%02x, ", data[i + j]);
        }
        printf("\n");
        i += count;
    }
}


/* This function reverses the block of data and loads it into a bignum. */
BIGNUM* load_reverse(const unsigned char* buf, const int length)
{
    BIGNUM* bn;
    int i;
    const unsigned char* ptr = buf;
    unsigned char* tmp = calloc(1, length);

    for(i = length - 1; i >= 0; i--)
    {
        tmp[i] = *ptr;
        ptr++;
    }

    bn = BN_bin2bn(tmp, length, 0);
    free(tmp);
    return bn;
}


/* This function decrypts and decodes a single block of encrypted data. */
int decrypt_block(unsigned char * plaintext,
                  const unsigned char * encrypted,
                  const int accumulator,
                  BIGNUM * exponent,
                  BIGNUM * modulus,
                  BN_CTX * ctx)
{
    int i;
    int acc = accumulator;
    unsigned char buf[ENCRYPTED_BLOCK_SIZE];
    unsigned char * d = plaintext;

    /* set up some bignums to work with */
    BIGNUM * result = BN_new();
    BIGNUM * block = load_reverse(encrypted, ENCRYPTED_BLOCK_SIZE);

    /* clear out the temporary buffer */
    memset(buf, 0, ENCRYPTED_BLOCK_SIZE);

    /* clear out the decrypted buffer */
    memset(plaintext, 0, PLAINTEXT_BLOCK_SIZE);

    /* do the RSA step */
    BN_mod_exp(result, block, exponent, modulus, ctx);

    /* unreverse the data out, and un-obfuscate/un-pad it */
    /* NOTE: we only take 50 bytes of output, not 51, the
     * byte as index 0 of the buffer is carry cruft. */
    BN_bn2bin(result, buf);

    for(i = PLAINTEXT_BLOCK_SIZE; i > 0; i--)
    {
        acc += buf[i];
        acc &= 0xFF;
        (*d) = (unsigned char)(acc);
        d++;
    }

    /* free the result */
    BN_free(result);

    return acc;
}


/* This function decrypts an entire frame of encrypted data */
void decrypt_frame(unsigned char * plaintext,
                   encrypted_frame_t * encrypted,
                   const unsigned char * public_exp,
                   const unsigned char * public_mod)
{
    int i;
    int accumulator = 0;
    unsigned char *d;
    unsigned char *e;

    /* set up the bignum variables */
    BIGNUM *exponent = BN_bin2bn(public_exp, LYNX_RSA_KEY_SIZE, 0);
    BIGNUM *modulus = BN_bin2bn(public_mod, LYNX_RSA_KEY_SIZE, 0);
    BN_CTX *ctx = BN_CTX_new();

    /* initialize the state */
    d = plaintext;
    e = encrypted->data;

    /* decrypt the blocks in the frame */
    for(i = 0; i < encrypted->blocks; i++)
    {
        /* decrypt a block */
        accumulator = decrypt_block(d, e, accumulator, exponent, modulus, ctx);

        /* move the pointers */
        d += PLAINTEXT_BLOCK_SIZE;
        e += ENCRYPTED_BLOCK_SIZE;
    }

    /* free the bignum variables */
    BN_free(modulus);
    BN_free(exponent);
    BN_CTX_free(ctx);
}


/* This function loads an entire encrypted frame by first reading in the block
 * count followed by that number of blocks of encrypted data. */
int read_encrypted_frame(FILE * const in,
                          encrypted_frame_t * frame)
{
    unsigned char blocks = 0;

    /* clear out the frame struct */
    memset(frame, 0, sizeof(encrypted_frame_t));

    /* read the block count */
    if(fread(&blocks, sizeof(unsigned char), 1, in) != 1)
        return 0;

    /* decode the block count */
    frame->blocks = 256 - blocks;

    /* read in the encrypted frame */
    if(fread(&frame->data, ENCRYPTED_BLOCK_SIZE, frame->blocks, in) != frame->blocks)
        return 0;

    return frame->blocks;
}


int main (int argc, const char * argv[])
{
    FILE *in;
    FILE *out;
    int blocks_decrypted;
    unsigned char plaintext_frame[MAX_PLAINTEXT_FRAME_SIZE];
    encrypted_frame_t encrypted_frame;

    if(argc < 3)
    {
        printf("usage: %s <encrypted.bin> <plaintext.bin>\n", argv[0]);
        return EXIT_FAILURE;
    }

    /* open the binary encrypted loader */
    in = fopen(argv[1], "r");
    out = fopen(argv[2], "wb+");

    /* check for successful opens */
    if(!in)
    {
        fprintf(stderr, "failed to open encrypted loader file: %s\n", argv[1]);
        return EXIT_FAILURE;
    }
    if(!out)
    {
        fprintf(stderr, "failed to open plaintext loader file for writing: %s\n", argv[2]);
        return EXIT_FAILURE;
    }

    while(!feof(in))
    {
        /* clear out the decrypted frame buffer */
        memset(plaintext_frame, 0, MAX_PLAINTEXT_FRAME_SIZE);

        /* read in the next encrypted frame of data */
        if(!read_encrypted_frame(in, &encrypted_frame))
            break;

        /* decrypt a single frame of the encrypted loader */
        decrypt_frame(plaintext_frame, &encrypted_frame, lynx_public_exp, lynx_public_mod);

        /* write the decrypted frame */
        fwrite(plaintext_frame, MAX_PLAINTEXT_FRAME_SIZE, 1, out);
    }

    fclose(in);
    fclose(out);

    return EXIT_SUCCESS;
}
