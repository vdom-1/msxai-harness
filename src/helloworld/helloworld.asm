;----------------------------------------------------------
; MSX1 Cartridge
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
; BIOS equates
;----------------------------------------------------------

CHPUT   equ     00A2h           ; Output character
CHGMOD  equ     005Fh           ; Change screen mode

;----------------------------------------------------------
; Cartridge entry point
;----------------------------------------------------------

INIT:
        ; SCREEN 0 (40-column text mode)
        xor     a
        call    CHGMOD

        ld      hl, MESSAGE

PRINT:
        ld      a, (hl)
        or      a
        jr      z, DONE

        call    CHPUT
        inc     hl
        jr      PRINT

DONE:
        jr      DONE

;----------------------------------------------------------
; Data
;----------------------------------------------------------

MESSAGE:
        db "HELLO WORLD!",13,10,0

;----------------------------------------------------------
; Pad ROM to exactly 16KB
;----------------------------------------------------------

        ds      04000h - ($ - 04000h), 0FFh