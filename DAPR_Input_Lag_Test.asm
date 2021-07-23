;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; @file MinZX.js
;
; @brief DAPR (David Programa) Input Lag Test
;
; @author David Crespo Tascon
;
; @copyright (c) 2021 David Crespo Tascon - github.com/dcrespo3d
;  This code is released under the MIT license,
;  a copy of which is available in the associated LICENSE file,
;  or at http://opensource.org/licenses/MIT
;  
;  This file is intended to measure input lag
;  on a ZX Spectrum machine, real or emulated
;  
;  When pressing any key, a sound tone is produced,
;  and a visual cue (border + column tally) is shown.
; 
;  A real spectrum should react almost immediately
;  (just the clock cycles between keypress detection
;  and sound and video reaction, which sould be really low;
;  due to the fact that keypresses are checked in a
;  high frequency loop, so the input lag for a real machine
;  should be below 100 us.
;  
;  For an FPGA or an emulator, your mileage may vary.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; run from non-contended memory for stable tone, not for 16K spectrums
    ORG $8000

    ; clear screen bitmap with zeros
    LD A, %00000000
    CALL FILL_SCRN_A

    ; clear screen attibute with white ink on black paper
    LD A, %00000111
    CALL FILL_ATTR_A

    ; draw logo
    CALL DRAW_DAPR_LOGO

    ; disable interrupts for stable tone
    DI

    ; enter main loop and never return
	JP MAIN_LOOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main application loop: checks for any keypress.
; when any key is pressed, a tone is produced
; and a visual cue (tally + border) is drawn.
MAIN_LOOP:
    LD BC, $00FE
    IN A, (C)
    AND $1F
    CP  $1F
    JR NZ, ANY_KEY_PRESSED

NO_KEY_PRESSED:
    ; draw inactive tally
    LD A, (INACT_ATT_COLOR)
    LD (TALLY_COLOR), A
    CALL DRAW_TALLY

    ; draw inactive border
    LD A, (INACT_BORDER_COLOR)
    OUT ($FE), A

    ; repeat loop
    JP MAIN_LOOP

ANY_KEY_PRESSED:
    ; draw active tally
    LD A, (ACTIV_ATT_COLOR)
    LD (TALLY_COLOR), A
    CALL DRAW_TALLY

    ; delay for half period of tone
    LD B, 100
WAIT_TONE:
    NOP
    DJNZ WAIT_TONE

    ; invert sound bit, compose (OR) it with border color
    ; and write to port $FE for sound and active border
    LD A, (SOUND_BIT)
    XOR $10
    LD (SOUND_BIT), A
    LD HL, ACTIV_BORDER_COLOR
    OR (HL)
    OUT ($FE), A

    ; repeat loop
    JP MAIN_LOOP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw tally: column of 24 attribute blocks, at col 15,
; filled with (TALLY_COLOR)
DRAW_TALLY:
    ; check if tally color has changed
    LD A, (PREV_TALLY_COLOR)
    LD B, A
    LD A, (TALLY_COLOR)
    CP B
    JR Z, DRAW_TALLY_SKIP ; not changed, skip

    ; annotate previous tally color for next call to this 
    LD (PREV_TALLY_COLOR), A

    ; actual tally drawing initialization and lop
    LD HL, $580F
    LD DE, 32
    LD B, 24
DRAW_TALLY_INNER_LOOP:
    LD (HL), A
    ADD HL, DE
    DJNZ DRAW_TALLY_INNER_LOOP

DRAW_TALLY_SKIP:
    ; avoiding redraw saves unnecesary draw cycles (good)
    ; but avoids writing to contended memory (attribute)
    ; which would cause unstable tone frequency
    ; due to 
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; current tally color
TALLY_COLOR:
    DEFB %00000000

; previous tally color
PREV_TALLY_COLOR:
    DEFB %11111111

; active tally color: yellow
ACTIV_ATT_COLOR:
    DEFB %00110000

; inative tally color: black
INACT_ATT_COLOR:
    DEFB %00000111

; active border color: yellow
ACTIV_BORDER_COLOR:
    DEFB %00000110

; inactive border color: black
INACT_BORDER_COLOR:
    DEFB 0

; sound bit (4) for alternating and generating tone
SOUND_BIT:
    DEFB 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw DAPR logo, all registers affected
DRAW_DAPR_LOGO:
    LD HL, $4088
    LD DE, DAPR

    LD C, 4
MLOOP1:
    CALL PUT_2_CH_ROWS
    LD A, L
    ADD A, $10
    LD L, A
    DEC C
    JR NZ, MLOOP1

    LD HL, $4808
    LD C, 8
MLOOP2:
    CALL PUT_2_CH_ROWS
    LD A, L
    ADD A, $10
    LD L, A
    DEC C
    JR NZ, MLOOP2

    LD HL, $5008
    LD C, 3
MLOOP3:
    CALL PUT_2_CH_ROWS
    LD A, L
    ADD A, $10
    LD L, A
    DEC C
    JR NZ, MLOOP3

    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fill screen bitmap with contents of A register
; ($4000 to $57FF)
FILL_SCRN_A:
    LD HL, $4000

    LD C, 128
FSA_OUTER_LOOP:
    LD B, 48
FSA_INNER_LOOP:
    LD (HL), A
    INC HL
    DJNZ FSA_INNER_LOOP
    DEC C
    JR NZ, FSA_OUTER_LOOP

    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fill screen attribute with contents of A register
; ($5800 to $5AFF)
FILL_ATTR_A:
    LD HL, $5800

    LD C, 32
FAA_OUTER_LOOP:
    LD B, 24
FAA_INNER_LOOP:
    LD (HL), A
    INC HL
    DJNZ FAA_INNER_LOOP
    DEC C
    JR NZ, FAA_OUTER_LOOP

    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; put 2 character rows, reading bytes pointed by DE,
; beginning at character position designated by HL
PUT_2_CH_ROWS:
    LD A, (DE)
    CALL FILL_BLOCKS_HL_A
    INC DE
    LD A, (DE)
    CALL FILL_BLOCKS_HL_A
    INC DE
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw a row of 8 blocks specified by byte at register A,
; into 8 character blocks position, starting at position
; designated by HL
FILL_BLOCKS_HL_A
    LD B, 8
FBHA_LOOP:
    RLCA
    JR NC, FBHA_SKIP
    CALL SET_BLOCK_HL
FBHA_SKIP: 
    INC L
    DJNZ FBHA_LOOP
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw pseudo circle block at character pos specified by HL
SET_BLOCK_HL:
    PUSH HL
    INC H
    LD (HL), $3C
    INC H
    LD (HL), $7E
    INC H
    LD (HL), $7E
    INC H
    LD (HL), $7E
    INC H
    LD (HL), $7E
    INC H
    LD (HL), $3C
    POP HL
    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; binary encoded DAPR logo, you should be able to see
; the pattern and change it as you like
DAPR:
    DEFB %11111000, %00111000
    DEFB %11001100, %01101100
    DEFB %11000110, %11000110
    DEFB %11000110, %11000110
    DEFB %11000110, %11111110
    DEFB %11001100, %11000110
    DEFB %11111000, %11000110
    DEFB %00000000, %00000000
    DEFB %11111100, %11111100
    DEFB %11000110, %11000110
    DEFB %11000110, %11000110
    DEFB %11000110, %11001110
    DEFB %11111100, %11111000
    DEFB %11000000, %11011100
    DEFB %11000000, %11001110
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


