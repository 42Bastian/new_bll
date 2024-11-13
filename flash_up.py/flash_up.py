#
# Send BLL .o file to the Lynx
#
import serial
import sys
from time import sleep
from os.path import exists,dirname
from struct import *

class LNXheader:
    def __init__(self,ps = 1024, name = 'empty'):
        self.magic = b'LYNX'
        self.page_size_bank0 = ps
        self.page_size_bank1 = 0
        self.version = 1
        self.cartname = name
        self.manufname = b'BS42'
        self.rotation = 0

    def fromFile(self,data):
        (self.magic,
         self.page_size_bank0,
         self.page_size_bank1,
         self.version,
         self.cartname,
         self.manufname,
         self.rotation,
         b,h0,h1) = unpack("<4s hhh 32s 16s b bhh",data)

    def bytes(self) -> bytearray:
        return pack("<4s hhh 32s 16s b bhh",
                    self.magic,
                    self.page_size_bank0,
                    self.page_size_bank1,
                    1,
                    self.cartname.encode(),
                    self.manufname,
                    self.rotation,
                    0,0,0)

verbose=True
erase=False
getcrc=False
force=False
blocksize=1024
sendloader=False
readimage=False
flashimage=False

baud=1000000
port='/dev/cu.usbserial-FT63V37G'
imhd=bytearray(10)
flashcode=bytearray()
image=bytearray(512*1024)
sectorbuffer=bytearray()
crctab=bytearray(256)
imagecrc=bytearray(256)
lynxcrc=bytearray(256)
filename=""

def sendByte(byte: int):
    tmo = 10
    if isinstance(byte,int):
        _b = bytearray([byte])
    else:
        _b = byte

    while tmo > 0:
        ser.write(_b)
        byte1 = ser.read(1)
        if _b == byte1:
            break
        tmo -= 1

    if _b != byte1:
        print("Error sending")
        exit(1)

def getByte() -> int:
    byte = ser.read(1)
    if  len(byte) == 1:
        return byte[0]
    else:
        return -1

def sendFile(dev, buffer, hd):
    size = len(buffer)

    sendByte(0x81)
    sendByte(b'P')
    sendByte(hd[2])
    sendByte(hd[3])
    sendByte(int((size >> 8) ^ 0xff))
    sendByte(int((size & 0xff) ^ 0xff))

    dev.write(buffer)
    image=dev.read(size)

def initCrcTab():
    for i in range(0,256):
        a = i
        for o in range(0,8):
            if a & 128:
                a = (a << 1) ^ 0x95
            else:
                a <<= 1
        crctab[i] = a & 255

#    for i in range(0,16):
#        print(crctab[i*16:(i+1)*16].hex(' '))

def getLynxCRC(verbose):
    global lynxcrc
    sendByte(b'C')
    sendByte(b'0')
    sendByte(int(blocksize/256))
    lynxcrc.clear()
    while len(lynxcrc) != 256:
        try:
            lynxcrc+=ser.read(256-len(lynxcrc))
        except:
            print("Error reading CRCs")
            exit(1)
    if verbose:
        print("CRCs on Lynx")
        for i in range(0,16):
            print(lynxcrc[i*16:(i+1)*16].hex(' '))

def readBlock(block, verbose):
    global sectorbuffer
    if verbose:
        print("Reading block: ",block)

    sendByte(b'C')
    sendByte(b'4')
    sendByte(int(blocksize/256))
    sendByte(block)
    sectorbuffer.clear()
    while len(sectorbuffer) != blocksize:
        try:
            sectorbuffer+=ser.read(blocksize-len(sectorbuffer))
        except:
            print("Error reading CRCs")
            exit(1)
    if verbose and False:
        for i in range(0,blocksize>>4):
            print(sectorbuffer[i*16:(i+1)*16].hex(' '))
    return sectorbuffer

def checkBlock(block) -> bool:
    for i in range(0,blocksize):
        if image[block*blocksize+i] != 0xff:
            break

    if i == blocksize-1:
        return False

    readBlock(block, False)

    for i in range(0,blocksize):
        if image[block*blocksize+i] != sectorbuffer[i]:
            return True

    return False


def sendBlock(block, verbose):
    global sectorbuffer
    sleep(0.1)
    sendByte(b'C')
    sendByte(b'1')
    sendByte(int(blocksize/256))
    sendByte(block)
    sleep(0.1)
    print(" %02x %02x %02x " %
          (block, lynxcrc[block], imagecrc[block]),end='',flush=True)

    sectorbuffer.clear()
    c = b'E'
    while c != 0x41 and c != 42:
        sectorbuffer = image[block*blocksize:(block+1)*blocksize]

        sent = ser.write(sectorbuffer)
        sectorbuffer.clear()
        sectorbuffer+= ser.read(blocksize)

#        while len(sectorbuffer) != blocksize:
#            try:
#                sectorbuffer+=ser.read(blocksize-len(sectorbuffer))
#            except:
#                print("Error reading CRCs")
#                exit(1)

        sendByte(imagecrc[block])
        c = 0
        while (c != 0x14) and (c != 0x41) and (c != 42):
            c = getByte()
            if c != -1:
                print("(%02x) " % (c), end='', flush=True)
            else:
                c = 42

    if (c == 0x41):
        print("... ",end='',flush=True)
        sleep(2)

    while c != 0x42 and c != 42 and c != 0x14:
        c = getByte()
        if c != -1:
            print("%02x " % (c), end='', flush=True)

    print('')
    return c == 0x42

def writeImage(image, filename, verbose):
    header=LNXheader(blocksize, filename)
    try:
        fd = open(filename,"wb")
        fd.write(header.bytes())
        fd.write(image)
        fd.close
    except:
        print("Error writing dump")
        exit(1)

def calcCRC(block, size):
    crc : int
    crc = 0
    for i in range(0,size):
        crc ^= image[block*size+i]
        crc = crctab[ crc ];
    return crc

def loadImage(filename, verbose) -> bytearray:
    global image
    image.clear()
    lnxhead=LNXheader()
    try:
        fd = open(filename,'rb')
        lnxhead.fromFile(fd.read(64))
        image = bytearray(fd.read())
        fd.close
    except:
        print("Error reading ",filename)
        exit(1)

    for blk in range(0,256):
        imagecrc[blk] = calcCRC(blk,lnxhead.page_size_bank0)

    if verbose:
        print("Image CRCs")
        for i in range(0,16):
            print(imagecrc[i*16:(i+1)*16].hex(' '))

    return lnxhead

def eraseFlash(verbose):
    global getcrc
    if verbose:
        print("Erasing ...",end='',flush=True)
    while True:
        sendByte(b'C')
        sendByte(b'5')
        sleep(1)
        result = getByte()
        if result == -1:
            print("Error Erasing")
            exit(1)

        if result == 0x43:
            getLynxCRC(False)
            cnt = 0
            for i in range(0,256):
                if lynxcrc[i] == int(0xd):
                   cnt += 1
            if cnt == 256:
                break
            else:
                print("Not erased, retry:",cnt)
    if verbose:
        print("done")
    getcrc = False

##################################

n = len(sys.argv)

if  n == 1:
    print("flash_up -h")
    print("flash_up [-p <device>] [-b baud] [-x] [-l] [-e] -f file")
    print("flash_up [-p <device>] [-b baud] [-l] -r file")
    exit(1)


flashcard_o = dirname(sys.argv[0])


if flashcard_o == "":
    flashcard_o = "."

flashcard_o += "/"

flashcard_o += 'flashcard.o'


p=1
while p < n:
    if sys.argv[p] == '-h':
        print("Flasher for Karri's flash cards\n"
              "-b - Baudrate\n"
              "-p - port\n"
              "-g - Get block CRCs\n"
              "-s - Block size 512,1024 or 2048\n"
              "-e - erase entire flash\n"
              "-l - force loading of flashcard.o\n"
              "-x - flash all blocks no matter if CRCs are identical\n"
              "-f <file> - flash file\n"
              "-r <file> - dump file\n")
        exit(1)

    if sys.argv[p] == '-b':
        baud = sys.argv[p+1]
        p += 2
        continue

    if sys.argv[p] == '-p':
        port = sys.argv[p+1]
        p += 2
        continue

    if sys.argv[p] == '-q':
        verbose=False
        p += 1
        continue

    if sys.argv[p] == '-l':
        sendloader=True
        p += 1
        continue

    if sys.argv[p] == '-x':
        force=True
        p += 1
        continue

    if sys.argv[p] == '-g':
        getcrc=True
        p += 1
        continue

    if sys.argv[p] == '-e':
        erase=True
        p += 1
        continue

    if sys.argv[p] == '-f':
        if readimage :
            print("-r already set")
            exit(1)
        flashimage=True
        if p+1 == n or sys.argv[p+1] == '-':
            print("Missing file")
            exit(1)
        filename=sys.argv[p+1]
        p += 2
        continue

    if sys.argv[p] == '-r':
        if flashimage :
            print("-f already set")
            exit(1)
        readimage=True
        if p+1 == n or sys.argv[p+1] == '-':
            print("Missing file")
            exit(1)
        filename=sys.argv[p+1]
        p += 2
        continue

    if sys.argv[p] == '-s':
        blocksize = int(sys.argv[p+1])
        p += 2
        if blocksize != 512 and blocksize != 1024 and blocksize != 2048:
            print("Wrong blocksize, must be 512,1024 or 2048")
            exit(1)
        continue

    print("Wrong argument:",sys.argv[p])
    exit(1)


if not flashimage  and not readimage and not getcrc and not erase:
    print("Missing -f or -r parameter")
    exit(1)

try:
    ser = serial.Serial(port,baud,parity='E',timeout=.1)
except:
    print("Could not open: ",port)
    exit(1)

try:
    fd = open(flashcard_o,'rb')
    imhd = fd.read(10)
    flashcode = fd.read()
    fd.close()
except:
    print("Error loading ",flashcard_o)
    exit(1)

initCrcTab()

if flashimage:
    lnxhead = loadImage(filename, verbose)
    blocksize = lnxhead.page_size_bank0

if verbose :
    print("Port:", port,"\nBaud:",baud)
    if flashimage:
        print("Flashing: ",filename)
    if readimage:
        print("Dumping to ",filename)
    print("Blocksize:",blocksize)

if not sendloader:
    sendByte(b'C')
    sendByte(b'3')
    c = getByte()
    if c != 48+6:
        sendloader=True
    else:
        if verbose:
            print("Flasher found")

if sendloader :
    if verbose :
        print("Sending Flasher")

    sendFile(ser, flashcode, imhd)
    while getByte() != -1:
        pass

if erase:
    eraseFlash(verbose)
else:
    if getcrc :
        getLynxCRC(True)
    else:
        getLynxCRC(verbose)

if flashimage:
    print("Flashing")
    for block in range(0,256):
        localforce = force

        if imagecrc[block] == 0xd or imagecrc[block] == 0x46:
            localforce = localforce or checkBlock(block)

        if lynxcrc[block] != imagecrc[block] or localforce:
            if not sendBlock(block, verbose):
                break

    if block == 255:
        print("Success")

if readimage:
    image=bytearray()
    for block in range(0,256):
        image += readBlock(block,False)

    writeImage(image, filename, verbose)
