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

PGT_SZ equ 0x800
CT_SZ  equ 0x1800
PNT_SZ equ 0x300

CartridgeSlot equ 0xF000
AssetRAMBuffer  equ 0xC000


; =============================================================================
; Page 0 (0000h - 3FFFh)
; Before port switch: Unmapped (Main Bios)
; After port switch: Mapped (ISRHandler)
; =============================================================================

; [0000h - 0037h] Free unrestricted space 

; [0038h]         : Z80 Interrupt Mode 1 execution entry point (Custom implementation)
        ds 0038h - $, 0FFh
    org 0038h
ISRHandler:
    di                  ; Disable interrupts
    push af             ; Protect the registers your ISR touches
    push bc
    push de
    push hl

    ; Clear VDP status baseline (R#15)
    xor a
    out (PRT1), a
    ld a, 15 
    or 0x80
    out (PRT1), a    
    in a, (PRT1)

    pop hl              ; Restore registers
    pop de
    pop bc
    pop af
    ei                  ; Enable interrupts
    reti

; [Post-ISRHandler - 3FFFh] : Free unrestricted space

; =============================================================================
; Page 1 (4000h - 7FFFh)
; Always mapped (program code)
; =============================================================================
        ds 4000h - $, 0FFh
    org 4000h
    db "AB"                 ; MSX Cartridge Identifier
    dw ROMInit              ; ROM initialization vector
    dw 0, 0, 0, 0, 0, 0
ROMInit:
    di                      ; Disable CPU interrupts

    call    VDPInit

    ; 2. Set up VDP R#14 and destination address for the VRAM write
    xor a                   
    out (PRT1), a           
    ld a, 14                ; R#14 (VRAM Access base address register)
    or 080h                 ; Write bit (7)
    out (PRT1), a
    xor a                   ; Low byte (0)
    out (PRT1), a
    ld a, PGT_DDRSS         ; High byte (PGT Address)
    or 0x40                 ; Write bit (6)
    out (PRT1), a

    ; -------------------------------------------------------------------------
    ; 3. THE HARDWARE FLIP: Map Page 3 to Cartridge ROM
    ; -------------------------------------------------------------------------
    in a, (0xA8)            ; Read current Primary Slot Register status
    ld d, a                 ; D = Safe backup of the original boot slot state!

    ; Isolate Page 1's slot bits (bits 2-3) and shift them to Page 3 (bits 6-7)
    ld a, d
    and 0x0C                ; Mask bits 2-3 (00001100b) -> This is your Cartridge Slot!
    rlca                    ; Rotate left 4 times to move them to bits 6-7
    rlca
    rlca
    rlca                    ; A now looks like (SS000000b) where SS = Cartridge Slot
    
    ld e, a                 ; E = Cartridge Page 3 bits
    ld a, d
    and 0x3F                ; Clear original Page 3 bits (00111111b)
    or e                    ; Merge Cartridge bits into Page 3
    
    out (0xA8), a           ; --- FLIP! --- Page 3 is now your Cartridge ROM.
                            ; WARNING: RAM and Stack are gone. Do not PUSH/POP/CALL!
                            

    ; -------------------------------------------------------------------------
    ; 4. REGISTER-ONLY STREAMING LOOP
    ; -------------------------------------------------------------------------
    ld hl, 0xC000           ; Source: Page 3 of Cartridge ROM (Now physically visible!)
    ld bc, 0x48             ; Counter: 2KB asset block

.manualStreamLoop:
    ld a, (hl)              ; Read asset byte directly from Cartridge ROM
    out (PRT0), a           ; Blast it straight to the VDP Data Port
    inc hl                  ; Advance ROM pointer
    
    ; Minimal, fast 16-bit register decrement
    dec bc
    ld a, b
    or c
    jr nz, .manualStreamLoop ; Loop until all 2048 bytes are pushed

    ; -------------------------------------------------------------------------
    ; Stream Color Table Data (Destination: VRAM 0x2000)
    ; -------------------------------------------------------------------------
    xor a                   
    out (PRT1), a           
    ld a, 14                ; R#14
    or 080h                 
    out (PRT1), a
    
    xor a                   ; Low byte (0x00)
    out (PRT1), a
    ld a, 0x20              ; High byte (0x20 for 0x2000)
    or 0x40                 ; Write bit (6)
    out (PRT1), a

    ; Stream 72 bytes of solid colors (White on Black)
    ld bc, 72
.colorStreamLoop:
    ld a, 0xF1              ; Foreground: White (F), Background: Black (1)
    out (PRT0), a
    dec bc
    ld a, b
    or c
    jr nz, .colorStreamLoop


    
    ; -------------------------------------------------------------------------
    ; 5. THE FLIP BACK: Restore Page 3 to System RAM
    ; -------------------------------------------------------------------------
    ; We have our original boot state still safely preserved in register D!
    ld a, d                 ; Load original boot slot layout
    out (0A8h), a           ; --- FLIP BACK! --- Page 3 is instantly System RAM again.

    ; -------------------------------------------------------------------------
    ; 6. CLEANUP & BIOS CUT-OFF
    ; -------------------------------------------------------------------------
    ; Now that RAM is back online, we can safely set our final stack pointer
    ld sp, 0xF380           

    ld a, 0xD5              ; Binary 11010101b
    out (0A8h), a           ; The BIOS is now permanently and completely unmapped!

    ; 1. Blank screen & disable VDP interrupts (R#1)
    xor a
    out (PRT1), a
    ld a, 0x81
    out (PRT1), a
    in a, (PRT1)

    jp GameInit

; =============================================================================
; GAME INITIALIZATION
; =============================================================================

GameInit:
    


GameLoop:
    ; Your core game logic, AI Markov chains, and physics run here.
    ; It runs completely unhindered until the V-Blank forces a jump to 0038h.
    jp GameLoop

;----------------------------------------------------------
; Initialize VDP in Graphic Mode 3
;----------------------------------------------------------
VDPInit:    
    ; fully initialize VDP for Graphic Mode 3
  
    ;in      a, (PRT1)   ; Reset VDP address flip-flop

    ; Force the VDP pointer to the base VRAM block address
    xor a                   ; Value 0
    out (PRT1), a           
    ld a, 14                ; R#14(VRAM Access base address register)
    or 080h                 ; write bit (7)
    out (PRT1), a
    
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

.vdp_cnfg_lp:
    ld      a, (hl)
    out     (PRT3), a      ; Writes R#0, increments up to R#11 automatically
    inc     hl
    djnz    .vdp_cnfg_lp

    ei
    ret

VDP_REG_DATA:
    db      0x04            ; R#0: M3=1(Graphic Mode 3)
    db      0x00            ; R#1: Bit 6=1 (Screen On), Bit 5=1 (V-Blank IRQ Enabled)   0x60  
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


; =============================================================================
; Page 2 
; =============================================================================
        ds 0x8000 - $, 0FFh
    org 0x8000

; =============================================================================
; Page 3 (transient data) after this data is loaded to the VRAM, this area
; will be mapped to RAM and will no longer be accessible by the game.
; =============================================================================
        ds 0C000h - $, 0FFh
    org 0C000h

GameAssets:
    ; [Your game maps, levels, sprites go here]
.gameFont:
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