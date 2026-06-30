In the MSX development community, standard practices dictate balancing raw hardware speed with machine safety and compatibility. While highly optimized games bypass the BIOS entirely for intensive time-critical operations (like custom VRAM writes or polling the keyboard matrix directly via PPI registers), specific BIOS and SUBROM calls remain vital.

These calls are well-optimized, handle complex machine architecture variations automatically, and are fully safe across MSX2, MSX2+, and Turbo R platforms.

## 1. Safest and Most Used MAIN BIOS Calls

These entries reside in the Main ROM (Page 0). When building clean software, especially under MSX-DOS environments, these routines are heavily relied upon.

### Slot Management (The absolute essentials)

MSX slot layout varies widely between machines (e.g., internal RAM slots, cartridge configurations). Trying to handle slot switches manually is prone to severe bugs.

- **`RDSLT` (`#000C`) / `WRSLT` (`#0014`)**: Reads or writes a single byte to an external slot without permanently changing your current slot page mapping.
    
- **`CALSLT` (`#001C`)**: Executes an inter-slot call. Essential if you have code split across pages/slots.
    
- **`ENASLT` (`#0024`)**: Permanently switches a specified slot into a memory page.
    

### Input Processing (Safe & highly used)

Directly querying I/O registers for controllers or keyboard matrix tracking can break on clones or machines with quirks. The standard calls are safe and highly optimal:

- **`GTSTCK` (`#00D5`)**: Reads the joystick or cursor keys. It returns normalized direction values (0-8), abstracting away whether the user is on a keyboard layout, Joyport 1, or Joyport 2.
    
- **`GTTRIG` (`#00D8`)**: Reads spacebar/joystick trigger status.
    
- **`CHGET` (`#009F`)**: Halts execution until a character is entered via keyboard. It handles background system tasks (like function keys) cleanly.
    
- **`CHSNS` (`#009C`)**: Checks if a character is waiting in the keyboard buffer without blocking execution.
    

### Basic System Operations

- **`DCOMPR` (`#0020`)**: Compares `HL` with `DE`. It is a tiny, highly efficient math helper routine that saves you from writing `or a / sbc hl, de` sequences repeatedly.
    
- **`BEEP` (`#00C0`)**: Generates the default system beep using the PSG. Writing a raw PSG routine just for a simple notification sound wastes space.
    

## 2. Most Used SUBROM (EXTROM) BIOS Calls

The introduction of the MSX2 standard brought the **SUBROM**, which handles VDP VRAM modes higher than SCREEN 3, block transfers, and advanced geometric functions.

> ⚠️ **Important Implementation Note:** You should never call the SUBROM using standard `CALSLT` directly, because both `CALSLT` and the SUBROM routines use the `IX` register for parameter passing. Instead, the community standard is to perform an inter-slot call via the Main ROM hook **`EXTROM` (`#015F`)** or utilize a standard trampoline execution block (`CALSUB`).

### Advanced VDP & Display Control

- **`CHGMOD` (`#005F` in SUBROM)**: Changes the screen mode safely. Hand-coding register adjustments across SCREEN 5 through SCREEN 8 is tedious; `CHGMOD` handles color setups, boundaries, and system variables safely.
    
- **`SETATR` (`#0143` in SUBROM)**: Sets up attribute pointers for high-resolution graphics screen modes.
    

### Fast VRAM Block Transfers (Command Engine wrappers)

While direct VDP Command Engine register parsing is common for custom assembly engines, the SUBROM contains optimized routines that handle the handshake protocols cleanly.

- **`NVBDRD` (`#014C` in SUBROM)**: Highly optimized block read from VRAM to RAM.
    
- **`NVBDWR` (`#014F` in SUBROM)**: Highly optimized block write from RAM to VRAM.
    

## Summary of Best Practices

|**Action Type**|**Use BIOS?**|**Reason**|
|---|---|---|
|**Slot Access & Call Handling**|**Yes (Always)**|Prevents hard crashes due to wildly varying hardware memory configurations.|
|**Joystick & Basic Text Input**|**Yes**|Standardizes layouts, auto-debounces mechanical noise, and adapts to MSX-DOS pipelines.|
|**Screen Mode Switching**|**Yes**|Updates all critical kernel system variables (`LINLEN`, `TXTNAM`, etc.) in sync with the hardware registers.|
|**High-fps Sprite/Pixel Engines**|**No (Direct I/O)**|High-frequency VRAM writes (`#004D`) introduce too much stack overhead. Use direct VDP port writes (`IN`/`OUT`) or `OTIR` blocks for pure frame rendering performance.|

If you are compiling using environment libraries like **MSXgl**, you will find that these exact safe routines are mapped internally inside its `bios` module wrappers. They safely toggle the Main-ROM in page 0 (`#0000–#3FFF`) when required and restore your application page state cleanly.


Highly optimized MSX games manage to achieve incredible performance while maintaining compatibility across thousands of hardware configurations by adhering to a strict strategy: **they skip the software BIOS, but they respect the hardware architecture.** Instead of treating the MSX standard as a set of software functions, they treat it as an immutable set of hardware specs, I/O ports, and strict initialization rules. Here is exactly how they do it.

## 1. Respecting the Rigid I/O Port Architecture

The MSX standard specifies that certain hardware chips must _always_ exist at specific I/O port addresses. Because these ports are standardized at the silicon level, developers can use direct Z80 `IN` and `OUT` assembly instructions without guessing where the hardware lives.

- **VDP (Video Display Processor):** Data port is always `#98`, and the Control/Status port is always `#99`.
    
- **PSG (Programmable Sound Generator - AY-3-8910):** Port `#A0` selects the register, `#A1` writes data, and `#A2` reads data.
    
- **PPI (Programmable Peripheral Interface - 8255):** Ports `#A8` to `#AB` control slot switching, keyboard scanning, and cassette I/O.
    

By using these hardcoded ports, a game can write bytes directly to the video chip or sound chip with zero overhead.

## 2. Dynamic Slot Discovery at Boot

The trickiest part of MSX compatibility is memory layout. An MSX can have its primary RAM in Slot 3, its game cartridge in Slot 1, and its Sub-ROM in Slot 0-1. Furthermore, slots can be expanded into "sub-slots." If a game hardcodes its memory locations, it will crash on 80% of machines.

To bypass the BIOS safely during gameplay, optimized games use a "hybrid" approach at startup:

1. **The Safe Boot:** When the cartridge boots, it temporarily uses the Main ROM's slot management calls (`RDSLT`, `ENASLT`) to analyze the system.
    
2. **The Hardware Map:** The game scans the system to see exactly which slots contain RAM and where the VRAM is mapped. It saves this layout into a few bytes of variable memory.
    
3. **The Cut-off:** Once the game maps its environment, it switches the Main ROM entirely out of Page 0 (`#0000–#3FFF`) and replaces it with its own game code or RAM. From this moment on, the BIOS is completely gone.
    
4. **Direct PPI Manipulation:** When the game needs to access RAM or switch ROM pages during gameplay, it doesn't call `ENASLT`. Instead, it modifies Port `#A8` (the PPI register) and the secondary slot register (`#FFFF`) directly using highly optimized Z80 instructions based on the map it created at boot.
    

## 3. Standard-Compliant VDP Timing (The VREG/Status Trick)

Different MSX2 machines use different revisions of the Yamaha VDP (such as the V9938 or V9958). A massive pitfall for unoptimized games is writing data to the VDP faster than the chip can physically process it, resulting in graphical corruption.

To bypass the slow BIOS video routines safely, developers write directly to the ports but implement strict, hardware-safe timing loops:

Code snippet

```
; Example of a fast, safe VRAM write block without BIOS
WriteVDP:
    out (#99), a       ; Send address/register data to VDP
    nop                ; Small hardware delay padding to allow 
    nop                ; older V9938 chips to catch up safely
    ret
```

Furthermore, games poll the VDP status registers directly (via Port `#99`) to detect vertical blanking (`V-Blank`) interrupts rather than relying on the BIOS interrupt handlers. This gives them pixel-perfect synchronization with the monitor refresh rate.

## 4. Bypassing the Kernel Interrupt Handler

Every time a hardware interrupt occurs (60 times a second on NTSC, 50 times on PAL), the Z80 CPU jumps to address `#0038`. The MSX BIOS normally intercepts this to scan the keyboard, update its internal clock, and blink the cursor—wasting valuable CPU cycles.

Optimized games hook directly into this cycle by writing a custom interrupt handler:

- They overwrite the system interrupt vector at address `#0038` or redirect the hooks located at RAM address `#FD9A` (`H.TIMI`).
    
- Their custom handler executes _only_ what the game needs (like updating the music engine and scrolling the screen) and exits immediately with an `EI / RETI` instruction sequence, skipping the sluggish system housekeeping entirely.
    

## 5. Direct Keyboard and Joystick Matrix Scanning

Reading input through the BIOS (`GTSTCK`, `CHGET`) introduces lag because the BIOS decodes the matrix, handles key repeats, and buffers strings.

Games bypass this by taking over Port `#AA` and Port `#A9` of the PPI chip. By writing a specific row number to Port `#AA`, the hardware instantly presents the state of those exact 8 keys on Port `#A9`.

```
                       Direct Hardware Input Loop
                       
  +------------------+     Select Matrix Row     +-------------------+
  |                  | ------------------------> |   PPI Port #AA    |
  |  Game Engine     |                           +-------------------+
  |  Assembly Loop   |                                     |
  |                  | <------------------------ +-------------------+
  +------------------+    Read Pressed Keys      |   PPI Port #A9    |
                                                 +-------------------+
```

A game engine can scan the arrow keys, Spacebar, and Graph key in less than 50 Z80 clock cycles, compared to hundreds of cycles spent inside a BIOS routine.

## When _Can't_ You Skip the BIOS?

Even the most optimized games must yield to the BIOS in one specific scenario: **Disk I/O**.

Because an MSX could be connected to a dedicated floppy disk drive, an IDE interface, a Nextor cartridge, or an SD card adapter, the underlying hardware implementation of the storage system is unpredictable. Trying to write a raw hardware driver for every storage system is impossible.

When loading data or saving game states to a disk, games will temporarily swap the MSX-DOS/Disk BIOS back into memory, execute standard system file calls, and then immediately unmap it once the operation completes.