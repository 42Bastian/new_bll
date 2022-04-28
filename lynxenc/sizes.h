/* Atari Lynx Encryption Tool
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

#ifndef _SIZES_H_
#define _SIZES_H_

#define ENCRYPTED_BLOCK_SIZE        (51)
#define PLAINTEXT_BLOCK_SIZE        (50)

#define LYNX_RSA_KEY_SIZE           (51)

#define MAX_BLOCKS_PER_FRAME        (5)

#define ENCRYPTED_FRAME_SIZE(x)     (1 + (x * ENCRYPTED_BLOCK_SIZE))
#define MAX_ENCRYPTED_FRAME_SIZE    (1 + (MAX_BLOCKS_PER_FRAME * ENCRYPTED_BLOCK_SIZE))

#define PLAINTEXT_FRAME_SIZE(x)     (x * PLAINTEXT_BLOCK_SIZE)

/* this is 256 bytes */
#define MAX_PLAINTEXT_FRAME_SIZE    (6 + (MAX_BLOCKS_PER_FRAME * PLAINTEXT_BLOCK_SIZE))

#endif

