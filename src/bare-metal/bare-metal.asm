; =============================================================================
; BARE-METAL 64KB ROM COMPILATION STRUCTURE
; Target Assembler: Glass Z80
; =============================================================================

PRT0 equ 0x98
PRT1 equ 0x99
PRT2 equ 0x9A
PRT3 equ 0x9B


; =============================================================================
; BARE-METAL EXECUTION CONTEXT: Page 0 (0000h - 3FFFh)
; This memory block becomes physically active in Page 0 IMMEDIATELY AFTER
; the Port A8h switch (BIOS cut-off).
; =============================================================================

; [0000h - 0037h] : Free custom initialization / re-entry space.
    org 00000h

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
    db "AB"             ; MSX Cartridge Magic Identifier
    dw ROMInit             ; Pointer the BIOS jumps to at power-on
    dw 0, 0, 0, 0, 0, 0

ROMInit:
    di                  ; Stop the BIOS immediately
    
    ; -------------------------------------------------------------------------
    ; LOAD GRAPHICS TO VRAM (While Page 3 ROM is still visible!)
    ; -------------------------------------------------------------------------
    ; Set VRAM write address destination to 0000h via VDP Port 99h
    ld a, 000h
    out (PRT1), a
    ld a, 40h           ; Set bit 6 to indicate a WRITE operation
    out (PRT1), a

    ; Stream 16KB of graphic assets straight out of Page 3 ROM into VRAM
    ld hl, 0C000h       ; Source: Start of Page 3 ROM
    ld bc, 4000h        ; Length: 16,384 bytes (16KB)
    
StreamGameAssets:
    ld a, (hl)          ; Read asset byte from Page 3 ROM
    out (PRT0), a       ; Send it directly to VRAM
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, StreamGameAssets


    ; --- THE CUT-OFF ---
    ; Read Port A8h, and alter Page 0 bits to select YOUR cartridge slot 
    ; instead of the Main BIOS slot.
    in a, (0A8h)
    and 11111100b       ; Clear Page 0 slot selection bits
    or b                ; Merge your cartridge slot ID (pre-calculated or found)
    out (0A8h), a       ; INSTANT SWITCH: Main BIOS dies. Your Section 1 is now at 0000h!

    ld sp, 0FFFFh       ; Set your stack safely at the top of Page 3 RAM
    jp GameInit   ; Jump into your newly mapped Page 0 boot vector!

; =============================================================================
; GAME INITIALIZATION (Safe Zone past interrupt space)
; =============================================================================
CURSOR  equ     0E000h          ; Cursor position in RAM

GameInit:
    
    ; [Perform your 4-line boot check for slot expansion here]
    ; [Execute your PPI Port A8h switch to permanently kill the BIOS]

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
    jr      z, GameLoop

    call    CUSTOM_CHPUT
    inc     hl
    jr      PRINT

GameLoop:
    ; Your core game logic, AI Markov chains, and physics run here.
    ; It runs completely unhindered until the V-Blank forces a jump to 0038h.
    jp GameLoop

;----------------------------------------------------------
; Custom Mode 0 (40-column text) setup
;----------------------------------------------------------
SETMODE0:
    ; The BIOS is likely in Screen 1 (Graphics mode) when it calls the cartridge.
    ; We must fully initialize the VDP for Screen 0 (Text mode).
    di
    
    ; CRITICAL: Reset VDP address flip-flop!
    ; The BIOS might have been interrupted or left the flip-flop in an unknown state.
    in      a, (PRT1)

    ; CRITICAL FOR MSX2: Set Register 14 to 0.
    ; This ensures all our VRAM writes go to the first 16KB bank.
    ; On MSX1, this safely mirrors to Reg 6 (Sprite Generator) which is ignored in Screen 0.
    ld      a, 0
    out     (PRT1), a
    ld      a, 14 | 080h    ; 8Eh
    out     (PRT1), a
    
    ; 1. Initialize VDP registers 0-8
    ; Using indirect access with auto-increment
    ; Fist set destination register to R#17 using normal direct access
    ld a, 0             ; bit 7 = 0 -> autoincrement enabled
                        ; bits 0-5 = 0 -> start at register 0
    out (PRT1), a      ; First write: Data for R#17
    
    ld a, 17            ; 00010001b
    or 80h              ; 10010001b
    out (PRT1), a      ; Second write: Destination R#17

    ld      hl, VDP_REG_DATA
    ld      b, 9
    ld      c, 0
.reg_loop:
    ld      a,(hl)
    out     (PRT3),a      ; <-- indirect write
    inc     hl
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
    out     (PRT1), a
    ld      a, 081h
    out     (PRT1), a
    
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
    out     (PRT1), a
    ld      a, d
    or      040h
    out     (PRT1), a
.copy_loop:
    ld      a, (hl)
    out     (PRT0), a
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
    out     (PRT1), a
    ld      a, h
    or      040h
    out     (PRT1), a
.fill_loop:
    ld      a, d
    out     (PRT0), a
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