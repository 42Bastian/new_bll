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
blocksize=1024

baud=115200*8
port='/dev/tty.usbmodem165120401'
imhd=bytearray(10)
image=bytearray(512*1024)
lnxhead=bytearray(64);
filename=""

def sendByte(byte: int):
    tmo = 10
    if isinstance(byte,int):
        _b = bytearray([byte])
    else:
        _b = byte

    ser.write(_b)

def getByte() -> int:
    byte = ser.read(1)
    if  len(byte) == 1:
        return byte[0]
    else:
        return -1

def loadImage(filename, verbose):
    global image
    global lnxhead
    image.clear()
#    lnxhead=LNXheader()
    try:
        fd = open(filename,'rb')
    except:
        print("Error opening ",filename)
        exit(1)
    try:
        lnxhead = bytearray(fd.read(64))
    except:
        print("Error reading header of",filename)
        exit(1)

    s =  (lnxhead[4]+lnxhead[5]*256)

    try:
        s *= 256
        image = bytearray(fd.read())
        l = len(image)
        if ( l != s ):
            if verbose :
                print("Size only ",len(image))
            for i in range(0,s-l):
                image.append(0xff)
    except:
        print("Error reading ",filename)
        exit(1)

    fd.close

##################################

n = len(sys.argv)

if  n == 1:
    print("SendCard -h")
    print("SendCard [-p <device>] [-b baud] file")
    exit(1)

p=1
while p < n-1:
    if sys.argv[p] == '-h' or sys.argv[p] == '--help':
        print("SendCard for peekb's EPROMEmu\n"
              "SendCard.py [-b|--baud <baudrate] [-p|--port <port>] filename")
        exit(1)

    if sys.argv[p] == '-b' or sys.argv[p] == '--baud':
        baud = sys.argv[p+1]
        p += 2
        continue

    if sys.argv[p] == '-p' or sys.argv[p] == '--port':
        port = sys.argv[p+1]
        p += 2
        continue

    if sys.argv[p] == '-q':
        verbose=False
        p += 1
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

filename = sys.argv[p]

try:
    ser = serial.Serial(port,baud,parity='E',timeout=.1)
except:
    print("Could not open: ",port)
    exit(1)


loadImage(filename, verbose)

if verbose :
    print("Port:", port,"\nBaud:",baud)
    print("Sending: ",filename)
    print("Size: ",len(image))

sendByte(b'c')
sendByte(b'l')
ser.write(lnxhead)
ser.flush()
ser.write(image)
ser.flush()
ser.close()
