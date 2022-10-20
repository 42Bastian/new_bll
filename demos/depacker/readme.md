# Collection of depackers

The example picture courtesy of Daniel Korican:
https://brainbox78.artstation.com/

The number shown is the time to depack the `unpacked` sprite data (sprpck -u).

* empty.spr is an sprite of all $ff

## unlz4

Pack with `lz4 -l` and skip first 8 bytes.

Unpacker size: 154 bytes

Speed for 7K sprite (RAM to RAM): 155ms

## unzx0

Unpacker size: 195 bytes

Speed for 7K sprite (RAM to RAM): 284ms
