#
# Send BLL .o file to the Lynx
#
import serial
import sys
from os.path import exists

verbose=1
baud=1000000
port='/dev/cu.usbserial-FT63V37G'

n = len(sys.argv)

if  n == 1:
    print("sendobj [-q] [-p <device>] [-b baud] file")
    print("Default: ",baud,"Bd Port:",port)
    exit(1)

p=1
while p < n-1:
    if sys.argv[p] == '-b':
        baud = sys.argv[p+1]
        p += 2

    if sys.argv[p] == '-p':
        port = sys.argv[p+1]
        p += 2

    if sys.argv[p] == '-q':
        verbose=0
        p += 1

if p == n:
    print("Missing .o file")
    exit(1)

filename=sys.argv[n-1]

if exists(port) == False:
    print("Error: cannot find:",port)
    exit(1)

if exists(filename) == False:
    print("Error: No such file:",filename)
    exit(1)

image=bytearray()
imhd=bytearray(10)
header=bytearray(6)

fd = open(filename,"rb")
imhd = fd.read(10)
image = fd.read()
fd.close()
size = len(image)
if verbose == 1:
    print("Port:", port,"\nBaud:",baud)
    print("File:",filename,"(",size,")");

# Prepare transmit header
header[0] = 0x81
header[1] = 0x50
header[2] = imhd[2]
header[3] = imhd[3]
header[4] = (size >> 8) ^ 0xff;
header[5] = (size & 0xff) ^ 0xff;

ser = serial.Serial(port,baud,parity='E',timeout=2.)

ser.write(header)
header=ser.read(6); # read back to slow down
ser.write(image)
image=ser.read(size) # read back to prevent early close of device
ser.close()
