//
// make_lnx2
//
// K.Wilkins July97
//
// V1 - Creation
// V2 - Added fill to cart end if LYX is not padded
// V3 - A little more user friendly
// V4 - Fixed missing command line params
// V5 - Added image rotation flag to header & command line
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>

typedef struct
{
  uint8_t magic[4]; /* LNX2 */
  uint8_t bank0;    /* FCB2 */
  uint8_t bank1;    /* FCB2 + AUDIN */
  uint8_t bank2;    /* FCB3 */
  uint8_t bank3;    /* FCB3 + AUDIN */
  uint16_t version;
  char cartname[32];
  char manufacturer[16];
  uint8_t rotation;
  uint8_t flags;
  uint8_t eeprom;
  uint8_t reserved;
  uint8_t custom[2];
} lnx2_header;

enum EEPROM  {
    EEPROM_NONE  = 0,
    EEPROM_93C46 = 1,
    EEPROM_93C56 = 2,
    EEPROM_93C66 = 3,
    EEPROM_93C76 = 4,
    EEPROM_93C86 = 5,
    EEPROM_SD    = 0x40,
    EEPROM_8BIT  = 0x80
};

/* bit 7..6 => type
   bit 5..3 => num blocks
   bit 2..0 => block size
*/
enum BANK_TYPE {
  BANK_ROM            = 3,
  BANK_RAM            = 2,
  BANK_RAM_PERSISTENT = 1,
  BANK_UNUSED         = 0
};

const char * const typeString[4] = {
  "unused",
  "RAM / persistent",
  "RAM",
  "ROM"
};

enum BANK_NUM_BLOCKS {
  BANK_2_BLOCKS    = 0,
  BANK_4_BLOCKS    = 1,
  BANK_8_BLOCKS    = 2,
  BANK_16_BLOCKS   = 3,
  BANK_32_BLOCKS   = 4,
  BANK_64_BLOCKS   = 5,
  BANK_128_BLOCKS  = 6,
  BANK_256_BLOCKS  = 7
};

enum BANK_BLOCK_SIZE  {
  BANK_BLOCK_16B   = 0,
  BANK_BLOCK_32B   = 1,
  BANK_BLOCK_64B   = 2,
  BANK_BLOCK_128B  = 3,
  BANK_BLOCK_256B  = 4,
  BANK_BLOCK_512B  = 5,
  BANK_BLOCK_1KB   = 6,
  BANK_BLOCK_2KB   = 7,
};

enum FLAGS {
  FLAGS_LYNXII_ONLY = 1,
  FLAGS_CUSTOM_INFO_PRESENT = 2
};

enum ROTATE {
  CART_NO_ROTATE    = 0,
  CART_ROTATE_LEFT  = 1,
  CART_ROTATE_RIGHT = 2
};

//->typedef struct
//->{
//->  UBYTE   magic[4];
//->  UWORD   page_size_bank0;
//->  UWORD   page_size_bank1;
//->  UWORD   version;
//->  char   cartname[32];
//->  char   manufname[16];
//->  char   rotation;
//->  UBYTE   spare[5];
//->}LYNX_HEADER_NEW;

void usage(void)
{
  fprintf(stderr,
          "Raw image to LNX2 image converter\n"
          "------------------------------------------\n"
          "Based on make_lnx from K.Wilkins July 1997\n\n"
          "USAGE:  make_lnx2 infile_b0 [-b0] [-b1 ] ...\n"
          " -o Output filename (Default=<infile0>.lnx)\n"
          " -i1 infile bank 1 (optional, else $ff will be written if b1 set)\n"
          " -i2 infile bank 2 (optional, else $ff will be written if b2 set)\n"
          " -i3 infile bank 3 (optional, else $ff will be written if b3 set)\n"
          " -m Manufacturer (Default=Atari)\n"
          " -r Left/Right (Default=No rotate)\n"
          " -g Game name (Default=<infile>.lnx)\n"
          " -b0 Bank0 definition\n"
          " -b1 Bank1 definition (AUDIN for select)\n"
          " -b2 Bank2 definition (using CART1/ select\n"
          " -b3 Bank2 definition (using AUDIN and CART1/ select\n"
          " -l2 Lynx II only game\n"
          "\n"
          "Bankdefinition:\n"
          " If no definition is given, it defaults to -b0 1024,256\n"
          "-bx [<blocksize>[,<blockcount>[,W[P]]]]\n"
          "   blocksize = 16,32,64,128,256,512,1024,2048, default 1024\n"
          "   blockcount = 2,4,8,16,32,64,128,256, default 256\n"
          "   W (optional) = writable\n"
          "   P (optional) = persisent\n"
          " Example:\n"
          " -b0                        => Typical 256KB game\n"
          " -b0 512                    => Typical 128KB game\n"
          " -b0 1024,256               => Typical 256KB game\n"
          " -b0 1024,128 -b1 1024,128  => 256KB game with two banks\n"
          );
}

int checkBank(const char *bankInfo,
              int * blsize,
              int * blcount,
              int * type)
{
  char bi_cpy[256];
  int error = 1;
  char * comma;
  int value;
  int temp;
  strcpy(bi_cpy, bankInfo);
  bankInfo = bi_cpy;

  *blsize = BANK_BLOCK_1KB;
  *blcount = BANK_256_BLOCKS;

  if ( bankInfo[0] == 0 ){
    *type = BANK_ROM;
    return 0;
  }
  comma = strchr(bankInfo, ',');
  if ( comma != NULL ) {
    *comma = 0;
  }
  error = sscanf(bankInfo,"%d",&value);
  if ( error == 0 ) return 1;

  temp = value & (-value);
  if ( temp != value ) return 1;
  if ( value < 16 || value > 2048 ) return 1;
  value >>= 5;
  for( temp = 0; value; ++temp, value >>= 1){
    /*empty*/
  }
  *blsize = temp;
  if ( comma == NULL ){
    *type = BANK_ROM;
    return 0;
  }

  bankInfo = comma+1;
  comma = strchr(bankInfo,',');
  if ( comma == NULL ){
    *type = BANK_ROM;
  } else {
    *comma = 0;
  }

  error = sscanf(bankInfo,"%d",&value);
  if ( error == 0 ) return 1;

  temp = value & (-value);
  if ( temp != value ) return 1;
  if ( value < 2 || value > 256 ) return 1;
  value >>= 2;
  for( temp = 0; value; ++temp, value >>= 1){
    /*empty*/
  }
  *blcount = temp;

  if ( comma == NULL ) return 0;

  bankInfo = comma+1;
  if ( bankInfo[0] != 'W' && bankInfo[0] != 'w' ) return 1;
  if ( bankInfo[1] == 0 ){
    *type = BANK_RAM;
    return 0;
  }
  if ( bankInfo[1] != 'P' && bankInfo[1] != 'p' ) return 1;
  *type = BANK_RAM_PERSISTENT;
  return bankInfo[2] != 0;
}

int main(int argc, char *argv[])
{
  lnx2_header header;
  FILE *filein,*fileout;
  uint8_t data = 0;
  uint32_t length,loop;
  int32_t image_size;
  char infile[4][256] = {{0}};
  char outfile[256] = {0};
  char game[256],manuf[256];
  char bank[4][256] = {{0}};
  char rotatestr[256];

  int rotation;
  int blsize[4] = {0};
  int blcount[4] = {0};
  int bankType[4] = {0};
  int error;
  int argno;
  int inputfiles = 0;
  int usedbanks = 0;
  int index;
  int verbose;
  if( argc < 2 ){
    fprintf(stderr,"ERROR: Invalid number of arguments\n\n");
    usage();
    exit(-1);
  }

  strncpy(manuf,"Atari",255);
  strncpy(game,argv[1],255);
  strncpy(rotatestr,"",255);
  rotation = CART_NO_ROTATE;
  argno = 1;

  strcpy(infile[0],argv[argno++]);
  strcpy(outfile,infile[0]);

  char *slash = strrchr(outfile, '/');
  char save = 0;
  if ( slash == NULL ){
    slash = strrchr(outfile, '\\');
  }
  if ( slash ){
    save = *slash;
    *slash = 0;
  } else {
    slash = outfile;
  }
  char *ext = strrchr(slash+1,'.');
  if ( ext == NULL ){
    ext = strchr(outfile,0);
  }
  *ext = 0;
  if ( save ){
    *slash = save;
  }
  strcat(outfile,".lnx");
  inputfiles = 1;
  verbose = 0;
  while( argno != argc) {
    if(argv[argno][0] == '-') {
      switch(argv[argno][1]) {
      case 'v':
        ++argno;
        ++verbose;
        break;
      case 'i':
        if ( argno == argc-1 ){
          fprintf(stderr, "Not enough parameters");
          exit(-1);
        }
        index = argv[argno][2]-'0';
        if ( index < 1 || index > 3 ){
          fprintf(stderr,"Wrong index\n");
        }
        if ( inputfiles & (1<<index) ){
          fprintf(stderr,"%s already set\n",argv[argno]);
          exit(-1);
        }
        ++argno;
        if ( argno == argc ){
          fprintf(stderr, "Not enough parameters");
          exit(-1);
        }
        inputfiles |= (1<<index);
        strcpy(infile[index],argv[argno++]);
        break;
      case 'o':
        argno++;
        if ( argno == argc ){
          fprintf(stderr, "Not enough parameters");
          exit(-1);
        }
        strcpy(outfile,argv[argno++]);
        break;
      case 'm':
        argno++;
        if ( argno == argc ){
          fprintf(stderr, "Not enough parameters");
          exit(-1);
        }
        strcpy(manuf,argv[argno++]);
        break;
      case 'g':
        argno++;
        if ( argno == argc ){
          fprintf(stderr, "Not enough parameters");
          exit(-1);
        }
        strcpy(game,argv[argno++]);
        break;
      case 'r':
        argno++;
        if ( argno == argc ){
          fprintf(stderr, "Not enough parameters");
          exit(-1);
        }
        strcpy(rotatestr,argv[argno++]);
        break;
      case 'b':
        index = argv[argno][2]-'0';
        if ( index < 0 || index > 3 ){
          fprintf(stderr,"ERROR: Invalid bank number (-b0..3 only):%s\n",
                  argv[argno]);
          exit(-1);
        }
        if ( usedbanks & (1<<index) ){
          fprintf(stderr,"Bank %d already defined\n",index);
          exit(-1);
        }
        usedbanks |= 1<<index;
        argno++;
        if ( argno != argc && argv[argno][0] != '-' ){
          strcpy(bank[index],argv[argno++]);
        }
        break;
      default:
        fprintf(stderr,"ERROR: Unrecognised argument (%s)\n\n",argv[argno]);
        usage();
        exit(-1);
        break;
      }
    }
    else
    {
      fprintf(stderr,"ERROR: Unrecognised argument (%s)\n\n",argv[argno]);
      usage();
      exit(-1);
    }
  }
  if ( usedbanks == 0 ){
    usedbanks = 1;
  }

  if(strlen(game)>31)  {
    fprintf(stderr,"\nERROR: Game cart name is too long (max 32)\n");
    exit(-1);
  }

  if(strlen(manuf)>15) {
    fprintf(stderr,"\nERROR: Manufacturer name is too long (max 16)\n");
    exit(-1);
  }

  if(strcmp(infile[0],outfile) == 0)  {
    fprintf(stderr,"\nERROR: Filenames must be different\n");
    exit(-1);
  }

  loop = 0;
  while(rotatestr[loop]) {
    rotatestr[loop]=toupper(rotatestr[loop]);
    loop++;
  }

  if(strcmp(rotatestr,"LEFT") == 0) rotation=CART_ROTATE_LEFT;
  else if(strcmp(rotatestr,"RIGHT") == 0) rotation=CART_ROTATE_RIGHT;
  else if(strcmp(rotatestr,"") != 0)  {
    fprintf(stderr,"\nERROR: Invalid rotation paramter only LEFT/RIGHT are valid\n");
    exit(-1);
  }
  for(int i = 0; i < 4; ++i){
    if ( usedbanks & (1<<i) ){
      error = checkBank(bank[i], &blsize[i], &blcount[i], &bankType[i]);
      if ( error != 0 ){
        fprintf(stderr, "B%d: Wrong config: %s\n",i,bank[i]);
        usedbanks &= ~(1<<i);
      }
    }
  }
  if ( usedbanks == 0 ){
    exit(-1);
  }

  if ( verbose ){
    printf("Infile0      : %s\n",infile[0]);
    printf("Outfile      : %s\n",outfile);
    printf("Manufacturer : %s\n",manuf);
    printf("Game         : %s\n",game);
    for(int i = 0; i < 3; ++i){
      if ( bankType[i] != 0 ){
        printf("Bank%d        : %s\n",i,infile[i]);
        printf("   Type      : %s\n",typeString[bankType[i]]);
        printf("   Blocksize : %d\n",16<<blsize[i]);
        printf("   Blockcount: %d\n",2<<blcount[i]);
      }
    }
  }
#if 0
  exit(0);
#endif

  memset((void *)&header, 0, sizeof(header));

  header.version=1;
  header.magic[0]='L';
  header.magic[1]='N';
  header.magic[2]='X';
  header.magic[3]='2';
  header.bank0 = (bankType[0]<<6)|(blcount[0]<<3)|blsize[0];
  header.bank1 = (bankType[1]<<6)|(blcount[1]<<3)|blsize[1];
  header.bank2 = (bankType[2]<<6)|(blcount[2]<<3)|blsize[2];
  header.bank3 = (bankType[3]<<6)|(blcount[3]<<3)|blsize[3];

  strncpy(header.cartname,game,31);
  strncpy(header.manufacturer,manuf,15);
  header.rotation = rotation;

  if((fileout = fopen(outfile,"wb"))==NULL)  {
    fprintf(stderr,"\nERROR: Couldn't open %s for writing\n",outfile);
    fclose(filein);
    exit(-1);
  }
  fwrite(&header,sizeof(header),1,fileout);
  /* Bank 0 */
  index = 0;
  length = 1;
  while( inputfiles != 0 || usedbanks != 0 ){
    if ( inputfiles & 1 ){
      if((filein = fopen(infile[index],"rb"))==NULL)  {
        fprintf(stderr,"\nERROR: Couldn't open %d %s for reading\n",
                index,infile[index]);
        fclose(fileout);
        exit(-1);
      }

      fseek(filein,0,SEEK_END);
      length = ftell(filein);
      rewind(filein);
    }
    if ( usedbanks & 1 ){
      image_size = (2<<blcount[index])*(16<<blsize[index]);
      if ( verbose ){
        printf("%d:image size %d, length %d\n",index, image_size, length);
      }
      while(length > 0 && image_size) {
        fread(&data,sizeof(uint8_t),1,filein);
        fwrite(&data,sizeof(uint8_t),1,fileout);
        --image_size;
        --length;
      }
      data = 0xff;
      while(image_size)  {
        fwrite(&data,sizeof(uint8_t),1,fileout);
        --image_size;
      }
    }
    inputfiles >>= 1;
    usedbanks >>= 1;
    if ( length > 0 ){
      if ( (inputfiles & 1) != 0 ){
        fprintf(stderr, "Input file %d too long, overlaps bank %d\n",
                index,index+1);
        fclose(filein);
        fclose(fileout);
        exit(-1);
      }
    } else {
      fclose(filein);
    }
    ++index;
  }
  if ( length > 0 ) {
    fclose(fileout);
    fclose(filein);
    fprintf(stderr, "Input file truncated!\n");
    exit(-1);
  } else {
    if ( verbose ){
      fprintf(stdout,"DONE: File converted\n");
    }
  }
  fclose(fileout);
  return 0;
}
