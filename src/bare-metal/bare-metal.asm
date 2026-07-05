; =============================================================================
; BARE-METAL 64KB PLAIN ROM
; MSX2 (V9938) Graphic Mode 3 (Screen 4)
; Target Assembler: Glass Z80
; =============================================================================

PPI_PRTA equ 0xA8 ; Primary Slot Register
PPI_PRTB equ 0xA9 ; Keyboard Matrix Columns
PPI_PRTC equ 0xAA ; Control Port
PPI_MODE equ 0xAB ; Configures how the 8255 chips behave internally

VDP_PRT0 equ 0x98 ; Data Port
VDP_PRT1 equ 0x99 ; Control Port
VDP_PRT2 equ 0x9A ; Palette Port
VDP_PRT3 equ 0x9B ; Indirect Port

PGT_ADDR equ 0x00
CT_ADDR  equ 0x020
PNT_ADDR equ 0x18


; =============================================================================
; Page 0 (0000h - 3FFFh)
; Before port switch: Unmapped (Main Bios)
; After port switch: Mapped (ISRHandler)
; =============================================================================

; [0000h - 0037h] Free unrestricted space 

; [0038h]         : Z80 Interrupt Mode 1 execution entry point (Custom implementation)
        ds 0038h - $, 0FFh
ISRHandler:
    di                  ; Disable interrupts
    push af             ; Protect the registers your ISR touches
    push bc
    push de
    push hl

    ; Clear VDP status baseline (R#15)
    xor a
    out (VDP_PRT1), a
    ld a, 15 
    or 0x80
    out (VDP_PRT1), a    
    in a, (VDP_PRT1)

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
    db "AB"                 ; MSX Cartridge Identifier
    dw ROMInit              ; ROM initialization vector
    dw 0, 0, 0, 0, 0, 0
ROMInit:
    di                      ; Disable CPU interrupts

    ; Diable VPD
    ; R#1: Bit 6=1 (Screen On), Bit 5=1 (V-Blank IRQ Enabled)
    ld a, 0x00
    out (VDP_PRT1), a
    ld a, 0x81
    out (VDP_PRT1), a
    in a, (VDP_PRT1)

    call    LoadGameAssets

    ld sp, 0xF380           ; Stack pointer

    ; -------------------------------------------------------------------------
    ; BIOS CUT-OFF (Mapping page 0 to cartridge ROM)
    ; -------------------------------------------------------------------------
    ld a, 0xD5              ; Binary 11010101b
    out (0A8h), a           ; The BIOS is now permanently and completely unmapped!

    jp GameInit

; =============================================================================
; GAME INITIALIZATION
; =============================================================================

GameInit:
    call    VDPInit
    ; -------------------------------------------------------------------------
    ; Print 'Hello World?'
    ; -------------------------------------------------------------------------
    xor a                   
    out (VDP_PRT1), a           
    ld a, 14                ; R#14
    or 080h                 
    out (VDP_PRT1), a
    
    xor a                   ; Low byte (0x00)
    out (VDP_PRT1), a
    ld a, PNT_ADDR              ; High byte (0x18 for 0x1800)
    or 0x40                 ; Write bit (6)
    out (VDP_PRT1), a

    ; Stream 2KB bytes of solid colors (White on Black)
    ld hl, .pnt_pg1
    ld bc, 12
.pntStreamLoop
    ld a, (hl)              
    out (VDP_PRT0), a
    inc hl 

    dec bc
    ld a, b
    or c
    jr nz, .pntStreamLoop

    ei

GameLoop:
    ; Your core game logic and physics run here.
    ; It runs completely unhindered until the V-Blank forces a jump to 0038h.
    jp GameLoop

;----------------------------------------------------------
; Initialize VDP in Graphic Mode 3
;----------------------------------------------------------
VDPInit:    
    ; fully initialize VDP for Graphic Mode 3
  
    in a, (VDP_PRT1)            ; Reset VDP address flip-flop

    ; Force the VDP pointer to the base VRAM block address
    xor a                   ; Value 0
    out (VDP_PRT1), a           
    ld a, 14                ; R#14(VRAM Access base address register)
    or 080h                 ; write bit (7)
    out (VDP_PRT1), a
    
    ; Initialize VDP registers 0-11 (indirect access with auto-increment)
    ; Fist set destination register to R#17 using normal direct access
    ld a, 0
    out (VDP_PRT1), a
    ld a, 17 
    or 80h
    out (VDP_PRT1), a

    ld      hl, VDP_REG_DATA
    ld      b, 0x0c
    ld      c, 0
.vdp_cnfg_lp:
    ld      a, (hl)
    out     (VDP_PRT3), a      ; Writes R#0, increments up to R#11 automatically
    inc     hl
    djnz    .vdp_cnfg_lp

    ret

VDP_REG_DATA:
    db      0x04            ; R#0: M3=1(Graphic Mode 3)
    db      0x60            ; R#1: Bit 6=0 (Screen Off), Bit 5=0 (V-Blank IRQ Disabled)     
    db      0x06            ; R#2: Pattern Name Table at 1800H
    db      0xFF            ; R#3: Color Table at 2000H(LOW)
    db      0x00            ; R#4: Pattern Generator Table at 0000H
    db      0x3C            ; R#5: Sprite Attribute Table at 1E00H(LOW)
    db      0x07            ; R#6: Sprite Generator Table at 3800H
    db      0x01            ; R#7: Border: Black (Text color zeroed out)
    db      0x08            ; R#8: 64K VRAM
    db      0x00            ; R#9: NTSC (192 lines)
    db      0x00            ; R#10: Color Table at 2000H(HIGH)
    db      0x00            ; R#11: Sprite Attributes at 1E00H(HIGH)

LoadGameAssets:
    ; -------------------------------------------------------------------------
    ; Map Page 3 to Cartridge ROM
    ; -------------------------------------------------------------------------
    in a, (0xA8)            ; Read current Primary Slot Register status
    ld d, a                 ; D = Save backup of the original boot slot state!

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
    ; Stream Pattern Generator
    ; -------------------------------------------------------------------------
    xor a                   
    out (VDP_PRT1), a           
    ld a, 14                ; R#14 (VRAM Access base address register)
    or 080h                 ; Write bit (7)
    out (VDP_PRT1), a
    xor a                   ; Low byte (0)
    out (VDP_PRT1), a
    ld a, PGT_ADDR         ; High byte (PGT Address)
    or 0x40                 ; Write bit (6)
    out (VDP_PRT1), a

    ld hl, .pgt_pg1           ; Source: Page 3 of Cartridge ROM (Now physically visible!)
    ld bc, 72             ; Counter: 2KB asset block

.pgtStreamLoop:
    ld a, (hl)              ; Read asset byte directly from Cartridge ROM
    out (VDP_PRT0), a           ; Blast it straight to the VDP Data Port
    inc hl                  ; Advance ROM pointer
    
    ; Minimal, fast 16-bit register decrement
    dec bc
    ld a, b
    or c
    jr nz, .pgtStreamLoop ; Loop until all 2048 bytes are pushed

    ; -------------------------------------------------------------------------
    ; Stream Color Table
    ; -------------------------------------------------------------------------
    xor a                   
    out (VDP_PRT1), a           
    ld a, 14                ; R#14
    or 080h                 
    out (VDP_PRT1), a
    
    xor a                   ; Low byte (0x00)
    out (VDP_PRT1), a
    ld a, CT_ADDR              ; High byte (0x20 for 0x2000)
    or 0x40                 ; Write bit (6)
    out (VDP_PRT1), a

    ; Stream 2KB bytes of solid colors (White on Black)
    ld hl, .ct_pg1 
    ld bc, 72
.ctStreamLoop:
    ld a, (hl)              
    out (VDP_PRT0), a
    inc hl 

    dec bc
    ld a, b
    or c
    jr nz, .ctStreamLoop

    ; -------------------------------------------------------------------------
    ; Restore Page 3 to System RAM
    ; -------------------------------------------------------------------------
    ld a, d                 ; Load backup of the original boot slot state
    out (0A8h), a           ; --- FLIP BACK! --- Page 3 is instantly System RAM again.

    ret


; =============================================================================
; Page 2 
; =============================================================================
        ds 0x8000 - $, 0FFh    
.pnt_pg1:
    db 0x04, 0x03, 0x05, 0x05, 0x06, 0x00, 0x08, 0x06, 0x07, 0x05, 0x02, 0x01

; =============================================================================
; Page 3 (transient data) after this data is loaded to the VRAM, this area
; will be mapped to RAM and will no longer be accessible by the game.
; =============================================================================
        ds 0C000h - $, 0FFh    
.pgt_pg1:
    db      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h ; space
    db      038h, 044h, 008h, 010h, 010h, 000h, 010h, 000h ; question mark
    db      0F0h, 088h, 088h, 088h, 088h, 088h, 0F0h, 000h ; D
    db      0F8h, 080h, 0F0h, 080h, 080h, 0F8h, 000h, 000h ; E
    db      088h, 088h, 088h, 0F8h, 088h, 088h, 088h, 000h ; H
    db      080h, 080h, 080h, 080h, 080h, 0F8h, 000h, 000h ; L
    db      070h, 088h, 088h, 088h, 088h, 070h, 000h, 000h ; O
    db      0F0h, 088h, 088h, 0F0h, 088h, 088h, 088h, 000h ; R
    db      088h, 088h, 088h, 0A8h, 0A8h, 050h, 000h, 000h ; W    
        ds 0C800h - $, 0FFh
.ct_pg1:
    db      0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; space
    db      0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h ; question mark
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; D
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; E
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; H
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; L
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; O
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; R
    db      0C1h, 0D1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h, 0F1h ; W 

; =============================================================================
; Pad ROM to exactly 64KB
; =============================================================================
        ds 10000h - ($ - 00000h), 0FFh