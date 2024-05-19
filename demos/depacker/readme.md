# Collection of depackers

The example [picture](bmp/startrek_voyager.bmp) courtesy of Daniel Korican:
https://brainbox78.artstation.com/

The number shown is the time to depack the `unpacked` sprite data (sprpck -u).

* File sizes (in bytes)

| Original | lz4 -12 | zx0 -c | Turbopacker | Exomizer | Exomizer RAW | upkr | upkr 255 | TSCrunch
| :-:      | :-:     | :-:    | :-:         | :-:      | :-:          | :-:  | :-:  | :-: |
| 7381     | 3959    | 3074   | 3741        | 2927     | 2924         | 2778 | 2803 | 3534

* Depacker sizes (in bytes)

| unlz4 | unlz4 fast | zx0 | zx0 fast | tp  | exo | exo RAW | upkr | upkr 255 | TSCrunch | TSC small
| :-:   | :-:        | :-: | :-:      | :-: | :-: | :-:     | :-:  | :-:  | :-: | :-: |
| 131   | 178        | 167 | 232/314  | 108 | 270 | 308     | 352  | 303 | 187 | 158 |

* Depack speed (in ms) (memory to memory)

| unlz4 | unlz4 fast | zx0 | zx0 fast | tp  | exo | exo RAW | upkr |upkr 255 | TSCrunch | TSC - small| memcpy |
| :-:   | :-:        | :-: | :-:      | :-: | :-: | :-:     | :-: | :-: | :-: | :-: |:-: |
| 156   | 84         | 262 | 209/166  | 107 | 303 | 280     |1629 | 1669  | 60 | 63  | 53  |

## unlz4/unlz4_fast

Pack with `lz4 -l` and skip first 8 bytes.

Packer: https://github.com/lz4/lz4

Speed improvement if match/literal length <= 255.

## unzx0/unzx0_fast

Pack with `zx0 -c`

Packer: https://github.com/einar-saukas/ZX0

Speed improvemnt in `zx0_fast` with inlining bit reading.

## untp

Pack with: `tp +d` to pack without header.

Packer: https://github.com/42Bastian/tp

## Exomizer

Packer: https://bitbucket.org/magli143/exomizer/src/master/

### sage's version

Pack with `exomizer.exe level -P0 -f infile -o outfile.exo`

*Note*: First two bytes are skipped (!?), so either add two dummy bytes before the packed data, or write those directly to the destination.

Original depacker from: https://github.com/bspruck/exolynx

### RAW unpacker

Pack with `exomizer raw -c -P-32 infile -o outfile.exoraw`

See `unexo.var` for the `-P` or `-c` option.

This is clean-room implementation based on unpack.c from the Exomizer repo. No byte skipping!!

## upkr

Pack with standard options.

Packer: https://github.com/exoticorn/upkr

## upkr_255

Pack with --max-offset 255 --max-length 255

## TSCrunch

Depacker for [TSCrunch](https://github.com/tonysavon/TSCrunch)

Pack w/o any options.

Small version has a minimal speed impact.