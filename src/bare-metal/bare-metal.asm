; =============================================================================
; BARE-METAL 64KB ROM COMPILATION STRUCTURE
; Target Assembler: Glass Z80
; =============================================================================

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

    ; 1. Your lightning-fast frame updates go here
    ; [Direct I/O writes to VDP Ports 98h/99h]
    ; [Direct I/O writes to PSG Ports A0h-A2h]

    ; 2. Acknowledge and clear the VDP hardware interrupt flag
    ld a, 0
    out (099h), a       ; Select VDP Status Register 0
    ld a, 8Fh           ; Register 15 (Status Register Select)
    out (099h), a
    in a, (099h)        ; Reading this port physically resets the interrupt line

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
    out (099h), a
    ld a, 40h           ; Set bit 6 to indicate a WRITE operation
    out (099h), a

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
GameInit:
    
    
    ; [Perform your 4-line boot check for slot expansion here]
    ; [Execute your PPI Port A8h switch to permanently kill the BIOS]

GameLoop:
    ; Your core game logic, AI Markov chains, and physics run here.
    ; It runs completely unhindered until the V-Blank forces a jump to 0038h.
    jp GameLoop

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

; =============================================================================
; Pad ROM to exactly 64KB
; =============================================================================

        ds 10000h - ($ - 00000h), 0FFh