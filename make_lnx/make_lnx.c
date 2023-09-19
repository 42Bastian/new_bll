//
// Make lynx V5
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

// Bytes should be 8-bits wide
typedef signed char SBYTE;
typedef unsigned char UBYTE;

// Words should be 16-bits wide
typedef signed short SWORD;
typedef unsigned short UWORD;

// Longs should be 32-bits wide
typedef long SLONG;
typedef unsigned long ULONG;

typedef struct
{
  UBYTE   magic[4];
  UWORD   page_size_bank0;
  UWORD   page_size_bank1;
  UWORD   version;
  char   cartname[32];
  char   manufname[16];
  char   rotation;
  UBYTE   spare[5];
}LYNX_HEADER_NEW;

#define CART_NO_ROTATE          0
#define CART_ROTATE_LEFT        1
#define CART_ROTATE_RIGHT       2

void usage(void)
{
  fprintf(stderr,"Raw image to LNX image convertor V5\n");
  fprintf(stderr,"-----------------------------------\n");
  fprintf(stderr,"K.Wilkins July 1997\n\n");
  fprintf(stderr,"USAGE:  make_lnx <infile> (Optional params)\n");
  fprintf(stderr,"           -o Output filename (Default=<infile>.lnx)\n");
  fprintf(stderr,"           -m Manufacturer (Default=Atari)\n");
  fprintf(stderr,"           -r Left/Right (Default=No rotate)\n");
  fprintf(stderr,"           -g Game name (Default=<infile>.lnx)\n");
  fprintf(stderr,"           -b0 Bank0 size (Default=Autocalc, options 0K,64K,128K,256K,512K)\n");
  fprintf(stderr,"           -b1 Bank1 size (Default=0K, options 0K,64K,128K,256K,512K)\n");
  fprintf(stderr,"\n");
  fprintf(stderr,"The default action (no optional params) is to convert the input filenama\n");
  fprintf(stderr,"from raw format to LNX format with the default options given above\n");
  fprintf(stderr,"\n");
  fprintf(stderr,"Examples:\n");
  fprintf(stderr,"make_lnx cgames.lyx                  (Converts cgames.lyx to cgames.lnx)\n");
  fprintf(stderr,"make_lnx cgames.lyx -o calgames.lnx  (Converts cgames.lyx to calgames.lnx)\n");
  fprintf(stderr,"\n");
}

int main(int argc, char *argv[])
{
  FILE *filein,*fileout;
  LYNX_HEADER_NEW newhead;
  UBYTE data=0;
  SLONG page_size0,page_size1,length;
  SLONG image_size;
  char infile[256],outfile[256];
  char game[256],manuf[256];
  char bank0[256],bank1[256];
  UBYTE rotation;
  char rotatestr[256];
  SLONG argno=0,loop=0;

  if(argc<2 || argc>12 || ((argc/2)*2)!=argc)
  {
    fprintf(stderr,"ERROR: Invalid number of arguments\n\n");
    usage();
    exit(-1);
  }

  *infile=0;
  *outfile=0;
  strncpy(manuf,"Atari",255);
  strncpy(game,argv[1],255);
  strncpy(bank0,"0K",255);
  strncpy(bank1,"0K",255);
  strncpy(rotatestr,"",255);

  page_size0=0;
  page_size1=0;
  rotation=CART_NO_ROTATE;

  argno=1;

  // 1st ARG MUST be infile

  strcpy(infile,argv[argno++]);

  // Prepare output filename default

  strcpy(outfile,infile);
  loop=0;
  while(outfile[loop]!='.' && outfile[loop]!=0x00) loop++;
  outfile[loop]=0x00;
  strcat(outfile,".lnx");

  while(argno!=argc)
  {
    if(argv[argno][0]=='-')
    {
      switch(argv[argno][1])
      {
      case 'o':
        argno++;
        strcpy(outfile,argv[argno++]);
        break;
      case 'm':
        argno++;
        strcpy(manuf,argv[argno++]);
        break;
      case 'g':
        argno++;
        strcpy(game,argv[argno++]);
        break;
      case 'r':
        argno++;
        strcpy(rotatestr,argv[argno++]);
        break;
      case 'b':
        switch(argv[argno][2])
        {
        case '0':
          argno++;
          strcpy(bank0,argv[argno++]);
          break;
        case '1':
          argno++;
          strcpy(bank1,argv[argno++]);
          break;
        default:
          fprintf(stderr,"ERROR: Invalid bank number (-b0 or -b1 only):%s\n\n",argv[argno]);
          usage();
          exit(-1);
          break;
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

  if(strlen(game)>31)
  {
    fprintf(stderr,"\nERROR: Game cart name is too long (max 32)\n");
    exit(-1);
  }

  if(strlen(manuf)>15)
  {
    fprintf(stderr,"\nERROR: Manufacturer name is too long (max 16)\n");
    exit(-1);
  }

  if(strcmp(infile,outfile)==0)
  {
    fprintf(stderr,"\nERROR: Filenames must be different\n");
    exit(-1);
  }

  if((filein=fopen(infile,"rb"))==NULL)
  {
    fprintf(stderr,"\nERROR: Couldn't open %s for reading\n",infile);
    exit(-1);
  }

  loop=0;
  while(rotatestr[loop])
  {
    rotatestr[loop]=toupper(rotatestr[loop]);
    loop++;
  }

  if(strcmp(rotatestr,"LEFT")==0) rotation=CART_ROTATE_LEFT;
  else if(strcmp(rotatestr,"RIGHT")==0) rotation=CART_ROTATE_RIGHT;
  else if(strcmp(rotatestr,"")!=0)
  {
    fprintf(stderr,"\nERROR: Invalid rotation paramter only LEFT/RIGHT are valid\n");
    exit(-1);
  }


  loop=0;
  while(bank0[loop])
  {
    bank0[loop]=toupper(bank0[loop]);
    loop++;
  }
  loop=0;
  while(bank1[loop])
  {
    bank1[loop]=toupper(bank1[loop]);
    loop++;
  }

  if(strcmp(bank0,"0K")==0) page_size0=0;
  else if(strcmp(bank0,"64K")==0) page_size0=256;
  else if(strcmp(bank0,"128K")==0) page_size0=512;
  else if(strcmp(bank0,"256K")==0) page_size0=1024;
  else if(strcmp(bank0,"512K")==0) page_size0=2048;
  else
  {
    fclose(filein);
    fprintf(stderr,"\nERROR: Command line bank0 size not recognised, please use:\n");
    fprintf(stderr,"\nERROR: 0K, 64K, 128K, 256K or 512K\n");
    exit(-1);
  }

  if(strcmp(bank1,"0K")==0) page_size1=0;
  else if(strcmp(bank1,"64K")==0) page_size1=256;
  else if(strcmp(bank1,"128K")==0) page_size1=512;
  else if(strcmp(bank1,"256K")==0) page_size1=1024;
  else if(strcmp(bank1,"512K")==0) page_size1=2048;
  else
  {
    fclose(filein);
    fprintf(stderr,"\nERROR: Command line bank1 size not recognised, please use:\n");
    fprintf(stderr,"\nERROR: 0K, 64K, 128K, 256K or 512K\n");
    exit(-1);
  }

#if 0
  printf("Infile       : %s\n",infile);
  printf("Outfile      : %s\n",outfile);
  printf("Manufacturer : %s\n",manuf);
  printf("Game         : %s\n",game);
  printf("Bank0        : %s\n",bank0);
  printf("Bank1        : %s\n",bank1);
  fclose(filein);
  exit(0);
#endif

  // Find out the length of the file

  fseek(filein,0,SEEK_END);
  length=ftell(filein);
  rewind(filein);

  if(!page_size0)
  {
    switch(length)
    {
    case 131072:
      page_size0=512;
      break;
    case 262144:
      page_size0=1024;
      break;
    case 524288:
      page_size0=2048;
      break;
    default:
      break;
    }
  }

  if(!page_size0)
  {
    fclose(filein);
    fprintf(stderr,"\nERROR: Could not determine page size, please set via command line\n");
    fprintf(stderr,"\nERROR: (Your file is not of the correct length, it may be corrupted)\n");
    exit(-1);
  }
  memset((void *)&newhead, 0, sizeof(newhead));

  newhead.version=1;
  newhead.magic[0]='L';
  newhead.magic[1]='Y';
  newhead.magic[2]='N';
  newhead.magic[3]='X';

  strncpy(newhead.cartname,game,31);
  newhead.cartname[31] = 0;
  strncpy(newhead.manufname,manuf,15);
  newhead.manufname[15] = 0;

  newhead.page_size_bank0=(UWORD)page_size0;
  newhead.page_size_bank1=(UWORD)page_size1;
  newhead.rotation=rotation;

  if((fileout=fopen(outfile,"wb"))==NULL)
  {
    fprintf(stderr,"\nERROR: Couldn't open %s for writing\n",outfile);
    fclose(filein);
    exit(-1);
  }

  fwrite(&newhead,sizeof(LYNX_HEADER_NEW),1,fileout);

  image_size=(256*newhead.page_size_bank0) + (256*newhead.page_size_bank1);

  while(fread(&data,sizeof(UBYTE),1,filein) && image_size)
  {
    fwrite(&data,sizeof(UBYTE),1,fileout);
    image_size--;
  }

  data=0;
  while(image_size)
  {
    fwrite(&data,sizeof(UBYTE),1,fileout);
    image_size--;
  }

  fprintf(stdout,"DONE: File converted\n");

  fclose(filein);
  fclose(fileout);
}
