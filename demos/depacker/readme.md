# Collection of depackers

The example [picture](startrek_voyager.bmp) courtesy of Daniel Korican:
https://brainbox78.artstation.com/

The number shown is the time to depack the `unpacked` sprite data (sprpck -u).

* File sizes (in bytes)

| Original | lz4 -12 | zx0 -c | Turbopacker |
| :-:      | :-:     | :-:    | :-:         |
| 7381     | 3959    | 3074   | 3741        |

* Depacker sizes (in bytes)

| unlz4 | unlz4 fast | zx0 | zx0 fast | tp  |
| :-:   | :-:        | :-: | :-:      | :-: |
| 154   | 160        | 183 | 195      | 116 |

* Depack speed (in ms) (memory to memory)

| unlz4 | unlz4 fast | zx0 | zx0 fast | tp  | memcpy |
| :-:   | :-:        | :-: | :-:      | :-: | :-: |
| 150   | 103        | 270 | 225      | 113 | 53  |

## unlz4/unlz4_fast

Pack with `lz4 -l` and skip first 8 bytes.

Packer: https://github.com/lz4/lz4

## unzx0/unzx0_fast

Pack with `zx0 -c`

Packer: https://github.com/einar-saukas/ZX0

## untp

Pack with: `tp +d` to pack without header.

Packer: https://github.com/42Bastian/tp
