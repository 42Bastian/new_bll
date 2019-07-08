* RANDOM2.INC
*
* Offered by Rob Nicholson.
* It works great _and_ is fast !
*
*
* Random
random_seed     dc.w 0
last_random     dc.b 35

Random
InitRandom::    phx
                lda random_seed+1                               ; havn't a clue what this does
                tax
                eor #$80
                rol
                rol random_seed+2
                ror random_seed+1
                lda random_seed
                sta random_seed+1

                ror
                eor random_seed+2
                stx random_seed+2
                sta random_seed
                plx                                              ; restore X
                rts
*

