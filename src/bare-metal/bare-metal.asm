; =============================================================================
; BARE-METAL 64KB ROM
; MSX2 (V9938) Graphic Mode 3 (Screen 4)
; Target Assembler: Glass Z80
; =============================================================================

PRT0 equ 0x98
PRT1 equ 0x99
PRT2 equ 0x9A
PRT3 equ 0x9B

PGT_DDRSS equ 0x0
CT_DDRSS  equ 0x2000
PNT_DDRSS equ 0x1800

PGT_SZ equ 0x1800
CT_SZ  equ 0x1800
PNT_SZ equ 0x300



; =============================================================================
; BARE-METAL EXECUTION CONTEXT: Page 0 (0000h - 3FFFh)
; This memory block becomes physically active in Page 0 IMMEDIATELY AFTER
; the Port A8h switch (BIOS cut-off).
; =============================================================================

; [0000h - 0037h] : Free custom initialization / re-entry space.
    ;org 00000h

; [0038h]         : HARDWIRED: Z80 Interrupt Mode 1 execution entry point.
        ds 0038h - $, 0FFh
    org 0038h
ISRHandler:
    push af             ; Protect the registers your ISR touches
    push bc
    push de
    push hl

    ; 2. Acknowledge and clear the VDP hardware interrupt flag
    ld a, 0
    out (PRT1), a       ; Select VDP Status Register 0
    ld a, 8Fh           ; Register 15 (Status Register Select)
    out (PRT1), a
    in a, (PRT1)        ; Reading this port physically resets the interrupt line

    pop hl              ; Restore registers
    pop de
    pop bc
    pop af
    ei                  ; Re-enable interrupts at the CPU level
    reti                ; Return to your main gameplay loop


; [Post-isr Code] : Free unrestricted space from isr end to 3FFFh (Page 0 End).


; =============================================================================
; BIOS COLD BOOT: Page 1 (4000h - 7FFFh)
; Hardwired hook for Main BIOS slot-scanning on system startup/reset.
; =============================================================================
        ds 4000h - $, 0FFh
    org 4000h
    db "AB"             ; MSX Cartridge Identifier
    dw ROMInit             ; Pointer the BIOS jumps to at power-on
    dw 0, 0, 0, 0, 0, 0

ROMInit:
    di                  ; Stop the BIOS interrupts
    
    ld sp, 0xBFFF

    ; MAP PAGE 3 TO CARTRIDGE ROM
    in a, (0A8h)
    and 00111111b           ; Clear Page 3 bits
    or  01000000b           ; Map Page 3 to Cartridge (Slot 1)
    out (0A8h), a           ; Your assets at 0xC000 are now safely readable

    ; -------------------------------------------------------------------------
    ; LOAD GRAPHICS TO VRAM (While Page 3 ROM is still visible!)
    ; -------------------------------------------------------------------------
    ; Set VRAM write address destination
    xor a
    out (PRT1), a           ; Value: 0 (Targets Bank 0, bits A16-A14 = 0)
    ld a, 14 
    or 080h                 ; Target Register 14 (Bit 7 set flags a register write)
    out (PRT1), a           ; Register 14 is now safely 0.    

    ld a, PGT_DDRSS
    out (PRT1), a
    ld a, 0x40           ; Set bit 6 to indicate VRAM write operation
    out (PRT1), a

    ; Stream graphic assets straight out of Page 3 ROM into VRAM
    ld hl, 0xC000       ; Source: Start of Page 3 ROM
    ld bc, PGT_SZ       ; 
    
StreamGameAssets:
    ld a, (hl)              ; Load the byte from current ROM address (HL) into A
    out (PRT0), a           ; Send that byte to VDP Data Port
    inc hl                  ; Move the ROM pointer to the next byte
    dec bc                  ; Decrement our counter (BC)
    ld a, b                 ; Check if BC is zero: 
    or c                    ;   Load B into A and OR it with C. If both are 0, the Zero Flag is set.  
    jr nz, StreamGameAssets ; If not zero jump again

    ; FINAL CUT-OFF
    ld a, 0xD5              ; Page 3: RAM, Page 2,1,0: Cartridge ROM
    out (0A8h), a

    ; 6. RE-ESTABLISH SAFE STACK IN NEWLY MAPPED PAGE 3 RAM
    ld sp, 0xFFFF           ; Stack now sits at the absolute top of Page 3 RAM,
                            ; safely growing backwards away from your code.

    jp GameInit   ; Jump into your newly mapped Page 0 boot vector!

; =============================================================================
; GAME INITIALIZATION
; =============================================================================
CURSOR  equ     0E000h          ; Cursor position in RAM

GameInit:
    
    ; [Perform your 4-line boot check for slot expansion here]
    ; [Execute your PPI Port A8h switch to permanently kill the BIOS]

    ; SCREEN 0 (40-column text mode)
    xor     a
    call    VDPInit

    ; Initialize cursor to VRAM PGT
    ld      hl, PNT_DDRSS
    ld      (CURSOR), hl

    ld      hl, MESSAGE


GameLoop:
    ; Your core game logic, AI Markov chains, and physics run here.
    ; It runs completely unhindered until the V-Blank forces a jump to 0038h.
    jp GameLoop

;----------------------------------------------------------
; Initialize VDP in Graphic Mode 3
;----------------------------------------------------------
VDPInit:    
    ; fully initialize VDP for Graphic Mode 3

    di                  ; disable interrupts
    
    in      a, (PRT1)   ; Reset VDP address flip-flop

    ; Force the VDP pointer to the base VRAM block (Bank 0)
    ld      a, 0
    out     (PRT1), a
    ld      a, 14 
    or 080h
    out     (PRT1), a
    
    ; Initialize VDP registers 0-11 (indirect access with auto-increment)
    ; Fist set destination register to R#17 using normal direct access
    ld a, 0
    out (PRT1), a
    ld a, 17 
    or 80h
    out (PRT1), a

    ld      hl, VDP_REG_DATA
    ld      b, 0x0c
    ld      c, 0
.reg_loop:
    ld      a, (hl)
    out     (PRT3), a      ; <-- indirect write
    inc     hl
    djnz    .reg_loop

    ; Enabled screen display
    ld      a, 0x40
    out     (PRT1), a
    ld      a, 0x81
    out     (PRT1), a
    
    ei
    ret

VDP_REG_DATA:
    db      0x04            ; R#0: M3=1(Graphic Mode 3)
    db      0x00            ; R#1: Screen disabled
    db      0x06            ; R#2: Pattern Name Table at 1800H
    db      0xFF            ; R#3: Color Table at 2000H(LOW)
    db      0x00            ; R#4: Pattern Generator Table at 0000H
    db      0x3C            ; R#5: Sprite Attribute Table at 1E00H(LOW)
    db      0x07            ; R#6: Sprite Generator Table at 3800H
    db      0xFA            ; R#7: Text: White(Color 15), Border: Dark Yellow(Color 10)
    db      0x08            ; R#8: 64K VRAM
    db      0x82            ; R#9: NTSC (212 lines)
    db      0x00            ; R#10: Color Table at 2000H(HIGH)
    db      0x00            ; R#11: Sprite Attributes at 1E00H(HIGH)

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
    out     (PRT1), a       ; VDP Register 1 (Command/Status)
    ld      a, h
    or      040h            ; Bit 6 = 1 for Write
    out     (PRT1), a       ; VDP Register 1

    ; Write character
    ld      a, c
    out     (PRT0), a       ; VDP Register 0 (Data)
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

MESSAGE:
    db "HELLO WORLD?",13,10,0

; =============================================================================
; GRAPHICS INITIALIZATION
; Stream static game assets directly from Page 3 ROM into VRAM.
; CRITICAL: This transfer must execute BEFORE the BIOS cut-off, while the 
; cartridge ROM block is still physically visible in the C000h-FFFFh range.
; =============================================================================
        ds 0C000h - $, 0FFh
    org 0C000h

GameAssets:
    ; [Your game maps, levels, sprites go here]
GameFont:
    db      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h ; space
    db      038h, 044h, 008h, 010h, 010h, 000h, 010h, 000h ; question mark
    db      0F0h, 088h, 088h, 088h, 088h, 088h, 0F0h, 000h ; D
    db      0F8h, 080h, 0F0h, 080h, 080h, 0F8h, 000h, 000h ; E
    db      088h, 088h, 088h, 0F8h, 088h, 088h, 088h, 000h ; H
    db      080h, 080h, 080h, 080h, 080h, 0F8h, 000h, 000h ; L
    db      070h, 088h, 088h, 088h, 088h, 070h, 000h, 000h ; O
    db      0F0h, 088h, 088h, 0F0h, 088h, 088h, 088h, 000h ; R
    db      088h, 088h, 088h, 0A8h, 0A8h, 050h, 000h, 000h ; W    
    
; =============================================================================
; Pad ROM to exactly 64KB
; =============================================================================

        ds 10000h - ($ - 00000h), 0FFh