# Collection of depackers

The example [picture](startrek_voyager.bmp) courtesy of Daniel Korican:
https://brainbox78.artstation.com/

The number shown is the time to depack the `unpacked` sprite data (sprpck -u).

* File sizes (in bytes)

| Original | lz4 -12 | zx0 -c | Turbopacker | Exomizer | upkr |
| :-:      | :-:     | :-:    | :-:         | :-:      | :-:  |
| 7381     | 3959    | 3074   | 3741        | 2927     | 2778 |

* Depacker sizes (in bytes)

| unlz4 | unlz4 fast | zx0 | zx0 fast | tp  | exo | upkr |
| :-:   | :-:        | :-: | :-:      | :-: | :-: | :-:  |
| 154   | 190        | 183 | 231/319  | 110 | 270 | 352  |

* Depack speed (in ms) (memory to memory)

| unlz4 | unlz4 fast | zx0 | zx0 fast | tp  | exo | upkr |memcpy |
| :-:   | :-:        | :-: | :-:      | :-: | :-: | :-:  | :-: |
| 150   | 84         | 270 | 211/183  | 113 | 303 | 1629 | 53  |

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

Pack with `exomizer.exe level -P0 -f infile -o outfile.exo`

*Note*: First two bytes are skipped (!?), so either add two dummy bytes before the packed data, or write those directly to the destination.

Depacker from: https://github.com/bspruck/exolynx

Packer: https://bitbucket.org/magli143/exomizer/src/master/

## upkr

Pack with standard options.

Packer: https://github.com/exoticorn/upkr
