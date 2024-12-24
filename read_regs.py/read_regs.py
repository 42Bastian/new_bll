#
# Read registers from BRKserver
#
import serial
import sys
from os.path import exists

verbose=0
baud=1000000
port='/dev/cu.usbserial-FT63V37G'

n = len(sys.argv)

para=1
while para < n-1:
    if sys.argv[para] == '-b':
        baud = sys.argv[para+1]
        para += 2
        continue

    if sys.argv[para] == '-p':
        port = sys.argv[para+1]
        para += 2
        continue

    if sys.argv[para] == '-v':
        verbose=1
        para += 1
        continue

    if sys.argv[para] == '-h':
        print("read_regs [-v] [-p <device>] [-b baud] file")
        print("Default: ",baud,"Bd Port:",port)
        exit(1)

if exists(port) == False:
    print("Error: cannot find:",port)
    exit(1)

command=bytearray(1)
result=bytearray(9+1)

if verbose == 1:
    print("Port:", port,"\nBaud:",baud)

# Prepare Command
command[0] = 0x86

ser = serial.Serial(port,baud,parity='E')
ser.write(command)
result=ser.read(9+1);
ser.close()

p=result[6]
print(f'A:{result[9]:02x}')
print(f'X:{result[8]:02x}')
print(f'Y:{result[7]:02x}')
print(f'P:{p:02x} : ',end="")
ps=""
if p & 0x80 == 0x80:
    ps += "N "
else:
    ps += "n "
if p & 0x40 == 0x40:
    ps += "V "
else:
    ps += "v "
ps += "- b "
if p & 0x8 == 0x8:
    ps += "D "
else:
    ps += "d "
if p & 0x4 == 0x4:
    ps += "I "
else:
    ps += "i "
if p & 0x2 == 0x2:
    ps += "Z "
else:
    ps += "z "
if p & 0x1 == 0x1:
    ps += "C "
else:
    ps += "c "

print(ps)
print(f'S:{result[5]:02x}')
print(f'PC:{result[3]*256+result[4]:04x}')
print(f'BRK:{result[2]:02x}')

exit(0)
