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
; Page 0 (0000h to 3FFFh)
; Before bootstrap the environment: Main Bios
; After bootstrap the environment: Cartridge ROM
; =============================================================================

; [0000h - 0037h] Free unrestricted space 

; [0038h]         : Z80 Interrupt Mode 1 execution entry point (Custom implementation)
        ds 0038h - $, 0FFh
ISRHandler:
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
    ret

; [Post-ISRHandler - 3FFFh] : Free unrestricted space

; =============================================================================
; Page 1 (4000h to 7FFFh)
; Always Cartrigde ROM
; =============================================================================
        ds 4000h - $, 0FFh
    db "AB"                 ; MSX Cartridge Identifier
    dw ROMInit              ; ROM initialization vector
    dw 0, 0, 0, 0, 0, 0
ROMInit:
    di                      ; Disable CPU interrupts

    ; -------------------------------------------------------------------------
    ; Diable VPD
    ; R#1: Bit 6=1 (Screen On), Bit 5=1 (V-Blank IRQ Enabled)
    ; -------------------------------------------------------------------------
    ld a, 0x00
    out (VDP_PRT1), a
    ld a, 0x81
    out (VDP_PRT1), a
    in a, (VDP_PRT1)

    ; -------------------------------------------------------------------------
    ; StreamGameAssets (ROM → VRAM)
    ; Slot mapping
    ; -------------------------------------------------------------------------
    call    BootstrapGameEnvironment

    ; -------------------------------------------------------------------------
    ; Set Stack Pointer(sp) final address
    ; -------------------------------------------------------------------------
    ld sp, 0xF380           ; Stack pointer
  

    jp GameInit

; =============================================================================
; GAME INITIALIZATION
; =============================================================================

GameInit:
    
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

    call    VDPInit

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
    db      0x60            ; R#1: Bit 6=1 (Screen on), Bit 5=1 (V-Blank IRQ enabled)
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

BootstrapGameEnvironment:
    ; -------------------------------------------------------------------------
    ; 1. CONTEXT DISCOVERY (While Page 3 is still safely RAM)
    ; -------------------------------------------------------------------------    
    in   a,(0A8h)
    ld   d,a                ; D = Original PPI state

    and  0C0h               ; Isolate page-3 bits
    exx
    ld   e,a                ; E' = RAM primary slot bits
    exx

    ld   a,d
    and  0Ch                ; Isolate page-1 bits
    rrca
    rrca                  
    ld   e,a                ; E = Cartridge primary slot index (0-3)

    ; Determine whether the cartridge is in a slot is expanded
    add a, 0xC1             ; Target 0xFCC1 (EXPTBL)
    ld l, a
    ld h, 0xFC              
    ld a, (hl)              
    and 0x80                
    ld b, a                 ; B = Expansion Flag (0x80 if expanded)
    exx
    ld b, a                 ; B' = Expansion Flag (0x80 if expanded)
    exx

    jr z, .skipSLTTBL       ; If not expanded, skipp SLTTBL

    ld a, e                 ; Get Primary Slot Index (1)
    add a, 0xC5             ; Target 0xFCC5 (SLTTBL)
    ld l, a                 ; HL points to SLTTBL for Cartridge Slot
    ld a, (hl)              ; A = Inverted mirror byte of Cartridge's 0xFFFF
    cpl                     ; Invert it -> A = True current sub-slot layout!
    ld c, a                 ; C = Cartridge Sub-slot layout
    exx    
    ld c, a                 ; C' = Cartridge Sub-slot layout
    exx

.skipSLTTBL:

    ; -------------------------------------------------------------------------
    ; 2. MAP PAGE 3 → CARTRIDGE (RAM cut-off)
    ; -------------------------------------------------------------------------
    ld a, d
    and 0x0C                
    rlca                    
    rlca
    rlca
    rlca                    ; A = (SS000000b)
    ld l, a                 
    
    ld a, d
    and 0x3F                
    or l                    
    out (0xA8), a           ; --- FLIP PRIMARY! --- RAM Stack is gone.

    ld a, b                 ; Check expansion flag
    and 0x80
    jr z, .skipSubSlotFlip     ; Not expanded? Skip to Stream assets.

    ; Cartridge is expanded: Modify layout using our clean register copy
    ld a, c                 ; A = Safe true layout (00b for your Sub-slot 0)
    and 0x0C                ; Isolate Page 1's sub-slot bits (0000SS00b)
    rlca
    rlca
    rlca
    rlca                    ; Shift 4 times -> A = (SS000000b)
    ld l, a

    ld a, c                 ; Get true layout back
    and 0x3F                ; Clear current Page 3 bits
    or l                    ; Merge Page 1's sub-slot selection into Page 3
    cpl                     ; Invert it for the hardware register layout requirement
    ld (0xFFFF), a          ; --- FLIP SECONDARY! --- Page 3 (expanded) is 100% stable now.

.skipSubSlotFlip:

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


    ;------------------------------------------
    ; BIOSCutOff
    ;------------------------------------------

    ; Keep page 3 unchanged
    in   a,(0A8h)
    and 0C0h
    ld  l,a

    ; Replicate cartridge primary slot into
    ; pages 0,1 and 2.
    ld  a,e            ; SS

    ld  h,a            ; save original

    ; page 0
    ld  b,a

    ; page 1
    rlca
    rlca
    or  b
    ld  b,a

    ; page 2
    ld  a,h
    rlca
    rlca
    rlca
    rlca
    or  b

    ; restore page 3 bits
    or  l


    out (0A8h),a

    
    ; Secondary slot register (FFFFh)
    ; Only if the cartridge is expanded.

    exx
    ld  a,b
    exx
    
    and 080h
    jr  z,.done

    exx
    ld  a,c            ; true slot layout
    exx
    ld  d,a            ; preserve original

    ; Extract page 1 subslot
    and 00Ch
    ld  e,a

    ; page 0 = page 1
    rrca
    rrca
    ld  l,a

    ; page 1
    ld  a,e
    or  l
    ld  l,a

    ; page 2 = page 1
    ld  a,e
    rlca
    rlca
    or  l
    ld  l,a

    ; preserve page 3
    ld  a,d
    and 0C0h
    or  l

    cpl
    ld  (0FFFFh),a

.done

    

    ; -------------------------------------------------------------------------
    ; Restore page 3 → RAM
    ; -------------------------------------------------------------------------
    in   a,(0A8h)
    and  3Fh          ; keep current pages 0-2

    exx
    or   e            ; merge original page-3 bits
    exx

    out  (0A8h),a


    ; On return:
    ;   D' = original PPI register
    ;   E' = Primary Slot bits
    ;   B' = 00h/80h expansion flag
    ;   C' = true secondary-slot layout (valid only if B!=0)
    ret


; =============================================================================
; Page 2 (8000h to BFFFh)
; Before bootstrap the environment: Arbitrary 
; After bootstrap the environment: Cartridge ROM
; =============================================================================
        ds 0x8000 - $, 0FFh    
.pnt_pg1:
    db 0x04, 0x03, 0x05, 0x05, 0x06, 0x00, 0x08, 0x06, 0x07, 0x05, 0x02, 0x01

; =============================================================================
; Page 3 Data Region (0C000h - FFFFh)
; This block contains transient data used during environment bootstrapping. 
; During this phase, Page 3 is temporarily remapped from RAM to Cartridge ROM 
; to allow direct streaming of graphical assets to VRAM. Once the transfer is 
; complete, Page 3 is reverted to its original RAM mapping.
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