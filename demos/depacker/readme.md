# Collection of depackers

The example picture courtesy of Daniel Korican:
https://brainbox78.artstation.com/

The number shown is the time to depack the `unpacked` sprite data (sprpck -u).

* empty.spr is an sprite of all $ff

## [unlz4](unlz4.asm)

Pack with `lz4 -l` and skip first 8 bytes.

Unpacker size: 154 bytes

Speed for 7K sprite (RAM to RAM): 150ms

## [unlz4_fast](unlz4_fast.asm)

Pack with `lz4 -l` and skip first 8 bytes.

Unpacker size: 160 bytes

Speed for 7K sprite (RAM to RAM): 103ms

## [unzx0](unzx0.asm)

Unpacker size: 183 bytes

Speed for 7K sprite (RAM to RAM): 270ms

## [unzx0_fast](unzx0_fast.asm)

Unpacker size: 195 bytes

Speed for 7K sprite (RAM to RAM): 225ms

## [untp](untp.asm)

Pack with: `tp -d` to pack without header.

Unpacker size: 115 bytes

Speed for 7K sprite (RAM to RAM): 159ms
