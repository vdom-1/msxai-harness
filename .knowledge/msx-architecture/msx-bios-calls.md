---

type: manual

---
# MSX BIOS calls

This is an overview of all official MSX BIOS calls.

- [MSX 1 BIOS](#msx-1-bios-entries) (up to function call #159)
- [MSX 2 BIOS](#msx-2-bios-entries) (up to function call #177)
- [MSX 2+ BIOS](#msx-2-plus-bios-entries)(up to function call #17D)
- [MSX turbo R BIOS](#msx-turbo-r-bios-entries) (up to function call #189)

# MSX 1 BIOS Entries

## Slot Configuration Byte

 Bitfield layout for the slot configuration byte:

- **Bit 7:** Expanded Slot Flag (`0`: Primary Slot only, `1`: Expanded Sub-slot).
- **Bits 6-4:** Unused (Set to `0` for strict safety).
- **Bits 3-2:** Secondary Slot ID (see [Slot ID](#slot-id)) -> Only evaluated if **Bit 7** = `1`.
- **Bits 1-0:** Primary Slot ID (see [Slot ID](#slot-id)) .


### Slot ID

Standard hardware architecture maps the system into four primary slots (0 to 3):

- **`00` (Slot 0):** Main System ROM.
- **`01` (Slot 1):** Cartridge Slot 1 (Primary external expansion).
- **`10` (Slot 2):** Cartridge Slot 2 (Secondary external expansion).
- **`11` (Slot 3):** System RAM / Internal Expansion Sub-slots.

## Memory Page Selection

Standard hardware architecture maps the 64KB address space into four 16KB pages (0 to 3):

- **`00` (Page 0):** `0000h` - `3FFFh`
- **`01` (Page 1):** `4000h` - `7FFFh`
- **`10` (Page 2):** `8000h` - `BFFFh`
- **`11` (Page 3):** `C000h` - `FFFFh`


## FUNCTION: RDSLT (Read Slot)

### Metadata

- **Address:** `000Ch`
- **Context:** Main BIOS (Page 0)
- **Safe across generations:** Yes (MSX1 / MSX2 / MSX2+ / Turbo R)
- **Deterministic:** Yes

### Description

Reads a single byte from a specified memory address within any target primary or secondary slot configuration without permanently modifying the current slot mapping layout of the executing environment.

### Execution Side Effects

- **Interrupts:** Disables Maskable Interrupts (executes `DI`). **CRITICAL:** Does not restore interrupt state upon return. The calling agent must explicitly execute `EI` post-call if interrupts are required by the system.
- **Page Mapping:** Temporarily alters Page 0 slot selection during execution, then completely restores the original Page 0 slot mapping before returning.

### Input Parameters

- **Register `HL`:** Target memory address to read (`0000h` - `FFFFh`).
- **Register `A`:** See [Slot configuration byte](#slot-configuration-byte).


### Usage Example

To read a single byte from address `4000h` inside Cartridge Slot 1 (`%00000001`), you would pass the target address to `HL` and manually re-enable maskable interrupts after execution:

```z80
RDSLT equ 000Ch ; Read Slot

ld hl, 4000h    ; Target memory address to read inside Page 1
ld a, 01h       ; Select Primary Slot 1 (Cartridge Slot 1) `00000001b` 
call RDSLT      ; Execute RDSLT. Register `A` now holds the byte value.
ei              ; Manually re-enable maskable interrupts
```

### Output Parameters

- **Register `A`:** Value retrieved from the specified address inside the target slot.

### Register Lifecycle State

- **Modified / Corrupted:** `AF` (Returns value/flags), `C`, `DE` (Destroyed during internal slot matrix calculations).
- **Preserved:** `BC` (High byte `B` is safe), `HL`, `IX`, `IY`.



Here is the complete, unified specification for `WRSLT` formatted exactly to your specification blueprint:

## FUNCTION: WRSLT (Write Slot)

### Metadata

* **Address:** `001Ch`
* **Context:** Main BIOS (Page 0)
* **Safe across generations:** Yes (MSX1 / MSX2 / MSX2+ / Turbo R)
* **Deterministic:** Yes

### Description

Writes a single byte of data to a specific 16-bit memory address within a target primary or secondary slot configuration. This write operation is transactional and transient; it does not alter the system's permanent memory page layout.

### Execution Side Effects

* **Interrupts:** Enables Maskable Interrupts (executes `EI`) directly before returning.
* **Page 0 Modification:** Can safely write to addresses in Page 0 of other slots without swapping out the currently running Main BIOS context.

### Input Parameters

* **Register `A`:** See [Slot configuration byte](#slot-configuration-byte).
* **Register `HL`:** Destination memory address (`0000h` - `FFFFh`).
* **Register `E`:** Value to write.

### Usage Example

To write the value `55h` directly into address `4000h` (the start of Page 1) located inside Cartridge Slot 1:

```z80
WRSLT equ 001Ch   ; Write Slot

ld a, 01h         ; Select Primary Slot (Cartridge Slot 1) `00000001b`
ld hl, 4000h      ; Target Address inside the slot
ld e, 55h         ; Data byte to write
call WRSLT        ; Execute WRSLT. Value written; slot mapping is preserved.

```

### Output Parameters

* **None:** The target memory address inside the specified slot is modified directly.

### Register Lifecycle State

* **Modified / Corrupted:** All registers (`AF`, `BC`, `DE`, `HL`) are overwritten/corrupted during execution.
* **Preserved:** `IX`, `IY`.




## FUNCTION: CALSLT (Call Slot)

### Metadata

* **Address:** `001Ch` (Inter-slot call handler wrapper) / Actual execution vector: `0021h` (`DIVLNK`)
* **Context:** Main BIOS (Page 0)
* **Safe across generations:** Yes (MSX1 / MSX2 / MSX2+ / Turbo R)
* **Deterministic:** Yes

### Description

Executes an inter-slot call. It temporarily switches the memory page layout to map a target primary or secondary slot, executes a subroutine at a specified 16-bit address, and restores the original slot mapping environment completely upon return (`RET`).

### Execution Side Effects

* **Interrupts:** Preserves the interrupt state, but routines called in other slots may modify it.
* **Stack Usage:** Uses the current stack pointer (`SP`). The stack must reside in a memory page that remains visible (typically Page 3 RAM) during the inter-slot transition, or the system will crash immediately.

### Input Parameters

* **Register `A`:** See [Slot configuration byte](https://www.google.com/search?q=%23slot-configuration-byte).
* **Register `IX`:** Target 16-bit execution address inside the destination slot (`0000h` - `FFFFh`).
* **Other Registers:** All other registers (`BC`, `DE`, `HL`) can be used freely to pass parameters directly to the called subroutine.

### Usage Example

To call a subroutine located at address `6000h` inside Cartridge Slot 1, while passing the parameter `1234h` in `HL`:

```z80
CALSLT equ 001Ch   ; Call Slot execution wrapper

ld a, 01h         ; Select Primary Slot (Cartridge Slot 1) `00000001b`
ld ix, 6000h      ; Target routine address inside the slot
ld hl, 1234h      ; Parameter passed to the target routine
call CALSLT       ; Execute routine; original slot mapping is preserved on return.
```

### Output Parameters

* **Dynamic:** Dependent entirely on the destination subroutine. Registers returned by the target routine are passed back cleanly to the caller.

### Register Lifecycle State

* **Modified / Corrupted:** `AF` (always modified). `BC`, `DE`, `HL` depend entirely on the subroutine being called.
* **Preserved:** `IY`. (`IX` is typically destroyed or modified as it holds the execution vector).



## FUNCTION: ENASLT (Enable Slot)

### Metadata

- **Address:** `0024h`
- **Context:** Main BIOS (Page 0)
- **Safe across generations:** Yes (MSX1 / MSX2 / MSX2+ / Turbo R)
- **Deterministic:** Yes

### Description

Permanently switches a specified primary or secondary slot into a targeted 16-bit memory page area. Unlike `RDSLT`, which temporarily alters mapping for a single byte, `ENASLT` changes the memory mapping environment completely until explicitly modified again.

### Execution Side Effects

- **Interrupts:** Disables Maskable Interrupts (executes `DI`) during the slot switching phase to prevent system crashes, but restores the interrupt state before returning based on the system's interrupt flag state upon entry.
- **Page 0 Warning:** If remapping Page 0, the Main BIOS is swapped out. If your execution logic depends on Main BIOS routines, your program will crash unless the new slot contains valid code at the execution pointer.

### Input Parameters

- **Register `A`:** See [Slot configuration byte](#slot-configuration-byte).
- **Register `H`:** Page number. 
  - **Bits 7–6**: (See [Memory Page Selection](#memory-page-selection)). 
  - **Bits 5–0**: Ignored.

### Usage Example

To map Cartridge Slot 1 into Memory Page 1 (`4000h - 7FFFh`), you load register `A` with the slot configuration byte and register `H` with the page number:

```z80
ENASLT equ 0024h  ; Enable Slot

ld a, 01h         ; Select Primary Slot (Cartridge Slot 1) `00000001b`
ld h, 40h         ; Page number 1 `01000000b`
call ENASLT       ; Execute ENASLT. Page 1 now points to Slot 1.
```

### Output Parameters

- **None:** The system's physical memory layout configuration is modified directly.

### Register Lifecycle State

- **Modified / Corrupted:** All registers (`AF`, `BC`, `DE`, `HL`) are overwritten/corrupted during execution.
- **Preserved:** `IX`, `IY`.






This completes the foundational four-part slot management toolkit (`RDSLT`, `WRSLT`, `CALSLT`, `ENASLT`). Would you like to transition to the most used **Input Processing BIOS calls** (like joystick and keyboard parsing) or dive into the **MSX2 SUBROM VDP operations** next?