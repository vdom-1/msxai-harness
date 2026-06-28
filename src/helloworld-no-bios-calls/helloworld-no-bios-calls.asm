;----------------------------------------------------------
; MSX1 Cartridge ROM (16 KB)
; Prints "HELLO WORLD" and loops forever
;----------------------------------------------------------

        org     04000h

;----------------------------------------------------------
; MSX cartridge header
;----------------------------------------------------------

        db      "AB"            ; Cartridge signature

        dw      INIT            ; Init routine
        dw      0               ; Statement handler
        dw      0               ; Device handler
        dw      0               ; Basic program

;----------------------------------------------------------
; RAM equates
;----------------------------------------------------------

CURSOR  equ     0C000h          ; Cursor position in VRAM
; CHGMOD removed - implemented custom routine


;----------------------------------------------------------
; Cartridge entry point
;----------------------------------------------------------

INIT:
        ; SCREEN 0 (40-column text mode)
        xor     a
        call    SETMODE0

        ; Initialize cursor to VRAM address 0
        ld      hl, 0
        ld      (CURSOR), hl

        ld      hl, MESSAGE

PRINT:
        ld      a, (hl)
        or      a
        jr      z, DONE

        call    CUSTOM_CHPUT
        inc     hl
        jr      PRINT

DONE:
        jr      DONE

;----------------------------------------------------------
; Custom Mode 0 (40-column text) setup
;----------------------------------------------------------
SETMODE0:
        ; The BIOS is likely in Screen 1 (Graphics mode) when it calls the cartridge.
        ; We must fully initialize the VDP for Screen 0 (Text mode).
        di
        
        ; CRITICAL: Reset VDP address flip-flop!
        ; The BIOS might have been interrupted or left the flip-flop in an unknown state.
        in      a, (099h)

        ; CRITICAL FOR MSX2: Set Register 14 to 0.
        ; This ensures all our VRAM writes go to the first 16KB bank.
        ; On MSX1, this safely mirrors to Reg 6 (Sprite Generator) which is ignored in Screen 0.
        ld      a, 0
        out     (099h), a
        ld      a, 14 | 080h    ; 8Eh
        out     (099h), a
        
        ; 1. Initialize VDP registers 0-8
        ld      hl, VDP_REG_DATA
        ld      b, 9
        ld      c, 0
.reg_loop:
        ld      a, (hl)
        out     (099h), a
        ld      a, c
        or      080h            ; Register Write Flag
        out     (099h), a
        inc     hl
        inc     c
        djnz    .reg_loop

        ; 2. Upload Custom Embedded Font characters to their ASCII slots
        ld      hl, FONT_SPACE
        ld      de, 0800h + (32 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_QMARK
        ld      de, 0800h + (63 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_D
        ld      de, 0800h + (68 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_E
        ld      de, 0800h + (69 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_H
        ld      de, 0800h + (72 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_L
        ld      de, 0800h + (76 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_O
        ld      de, 0800h + (79 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_R
        ld      de, 0800h + (82 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ld      hl, FONT_W
        ld      de, 0800h + (87 * 8)
        ld      bc, 8
        call    COPY_TO_VRAM

        ; 3. Clear Pattern Name Table (0000h - 03BFh) with spaces (20h)
        ld      hl, 0000h
        ld      bc, 960
        ld      a, 20h
        call    FILL_VRAM

        ; 4. Turn on the display (Reg 1 = F0h)
        ld      a, 0F0h
        out     (099h), a
        ld      a, 081h
        out     (099h), a
        
        ei
        ret

VDP_REG_DATA:
        db      000h            ; Reg 0: Mode 0
        db      0B0h            ; Reg 1: 16K, Display OFF, Int On, Text Mode
        db      000h            ; Reg 2: Name Table at 0000h
        db      000h            ; Reg 3: Color Table (Not used)
        db      001h            ; Reg 4: Pattern Generator at 0800h
        db      000h            ; Reg 5: Sprite Attributes (Not used)
        db      000h            ; Reg 6: Sprite Generator (Not used)
        db      0F4h            ; Reg 7: Text White (15), BG Dark Blue (4)
        db      000h            ; Reg 8: MSX2 VR=0 (16KB mode). Harmlessly overwrites Reg 0 on MSX1.

FONT_SPACE:
        db      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
FONT_QMARK:
        db      038h, 044h, 008h, 010h, 010h, 000h, 010h, 000h
FONT_D:
        db      0F0h, 088h, 088h, 088h, 088h, 088h, 0F0h, 000h
FONT_E:
        db      0F8h, 080h, 0F0h, 080h, 080h, 0F8h, 000h, 000h
FONT_H:
        db      088h, 088h, 088h, 0F8h, 088h, 088h, 088h, 000h
FONT_L:
        db      080h, 080h, 080h, 080h, 080h, 0F8h, 000h, 000h
FONT_O:
        db      070h, 088h, 088h, 088h, 088h, 070h, 000h, 000h
FONT_R:
        db      0F0h, 088h, 088h, 0F0h, 088h, 088h, 088h, 000h
FONT_W:
        db      088h, 088h, 088h, 0A8h, 0A8h, 050h, 000h, 000h

COPY_TO_VRAM:
        ; HL = Source (RAM/ROM), DE = Dest (VRAM), BC = Length
        ; Assumes interrupts are already disabled!
        ld      a, e
        out     (099h), a
        ld      a, d
        or      040h
        out     (099h), a
.copy_loop:
        ld      a, (hl)
        out     (098h), a
        inc     hl
        dec     bc
        ld      a, b
        or      c
        jr      nz, .copy_loop
        ret

FILL_VRAM:
        ; HL = Dest (VRAM), BC = Length, A = Value
        ; Assumes interrupts are already disabled!
        ld      d, a
        ld      a, l
        out     (099h), a
        ld      a, h
        or      040h
        out     (099h), a
.fill_loop:
        ld      a, d
        out     (098h), a
        dec     bc
        ld      a, b
        or      c
        jr      nz, .fill_loop
        ret

;----------------------------------------------------------
; Custom CHPUT - Writes a character to VDP directly
;----------------------------------------------------------
CUSTOM_CHPUT:
        push    af
        push    bc
        push    de
        push    hl

        cp      13              ; Check for Carriage Return
        jr      z, .cr
        cp      10              ; Check for Line Feed
        jr      z, .lf

        ; Normal character: Write to VRAM
        ld      c, a
        ld      hl, (CURSOR)

        ; Set VDP to Write Mode at address HL
        di
        ld      a, l
        out     (099h), a       ; VDP Register 1 (Command/Status)
        ld      a, h
        or      040h            ; Bit 6 = 1 for Write
        out     (099h), a       ; VDP Register 1

        ; Write character
        ld      a, c
        out     (098h), a       ; VDP Register 0 (Data)
        ei

        ; Increment cursor
        inc     hl
        ld      (CURSOR), hl
        jr      .end

.cr:
        ; Carriage Return: Move cursor to beginning of the line
        ; cursor = cursor - (cursor % 40)
        ld      hl, (CURSOR)
        ld      bc, 40
.cr_div:
        or      a               ; clear carry
        sbc     hl, bc          ; hl = hl - 40
        jr      nc, .cr_div     ; loop if hl >= 0
        add     hl, bc          ; add back 40, hl = remainder (cursor % 40)
        
        ex      de, hl          ; de = remainder
        ld      hl, (CURSOR)
        or      a
        sbc     hl, de          ; hl = cursor - remainder
        ld      (CURSOR), hl
        jr      .end

.lf:
        ; Line Feed: Move to next line (add 40 to cursor)
        ld      hl, (CURSOR)
        ld      bc, 40
        add     hl, bc
        ld      (CURSOR), hl

.end:
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

;----------------------------------------------------------
; Data
;----------------------------------------------------------

MESSAGE:
        db "HELLO WORLD?",13,10,0

;----------------------------------------------------------
; Pad ROM to exactly 16KB
;----------------------------------------------------------

        ds      04000h - ($ - 04000h), 0FFh