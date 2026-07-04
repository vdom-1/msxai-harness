# I/O

## Ports overview

|  Port   | Value |  Access mode   |
|---------|-------|----------------|
| Port #0 | 0x98  | READ and WRITE |
| Port #1 | 0x99  | READ and WRITE |
| Port #2 | 0x9A  | WRITE-only     |
| Port #3 | 0x9B  | WRITE-only     |
 

## Accessing the [Control Registers](vdp-registers.md#control-Register)

The control registers are write-only registers. They can be addressed in two ways, direct and indirect. Usually the direct way is used, but the indirect method is also practical in some situations.

### Direct access

Write the data and the register number in sequence to port #1. The data is first written to port #1 and then the destination register number is written to port #1 using the five least significant bits. The most significant bit(bit 7) must be set to 1 and the second most signficant bit(bit 6) must be set to 0 (in other words, add 128.)

| Step | Target       | Byte Format | Purpose                                            |
| ---- | ------------ | ----------- | -------------------------------------------------- |
| 1    | Port #1      | Any         | Writes one single byte                             |
| 2    | Port #1      | `10nnnnn`   | Select control register number (0 to 23, 32 to 46) |

Interrupts should be inhibited before the control register is accessed. After the desired task is completed interrupts should be released.

### Indirect access

Instead of specifying the target register each time, you first load R#17(objective address pointer) with a register number using [Direct access](#direct-access), optionally enabling autoincrement(bit 7) . In non-autoincrement mode, all writes go repeatedly to the same register without changing R#17. In autoincrement mode, each write automatically advances R#17 to the next register number, allowing a sequence of consecutive registers to be filled efficiently. This approach reduces the need to repeatedly send register-selection commands, making bulk register updates faster and more efficient, especially when initializing or configuring groups of related VDP registers.

| Step | Target       | Byte Format | Purpose                                            |
| ---- | ------------ | ----------- | -------------------------------------------------- |
| 1    | R#17         | `a0nnnnn`  | Select control register number (0 to 23, 32 to 46) |
| 2    | Port #3      | Any         | Writes one single byte                             |
| 3    | Port #3      | Any         | Writes one single byte                             |
| n    | Port #3      | Any         | Writes one single byte                             |

## Accessing the [Status Registers](vdp-registers.md#status-registers)

Status registers are read-only registers. Their contents can be read from Port #1 after setting the status register number in the least significant four bits of R#15(status address pointer). 

| Step | Target       | Byte Format | Purpose                                   |
| ---- | ------------ | ----------- | ----------------------------------------- |
| 1    | R#15         | `0000nnnn`  | Select status register number (0 to 9)    |
| 2    | Port #1      | Any         | Reads one single byte                     |

Interrupts should be inhibited before the status register is accessed. After the desired task is completed, R#15 should be set to 0 and the interrupts released.


## Accessing the [Pallete Registers](vdp-registers.md#palette-registers)

Pallete Registers are read-only. To write data to the palette registers (P#0 to P#15), specify the palette register number in the four lowest significant bits of R#16(color palette address pointer), and then send the data to Port #2. Since palette registers have a length of 9 bits, data must be sent twice; red brightness and blue brightness first, then green brightness. Brightness is specified in the lower three bits of a four bit segment.

| Step | Target       | Byte Format | Purpose                                   |
| ---- | ------------ | ----------- | ----------------------------------------- |
| 1    | R#16         | `0000nnnn`  | Select palette register number (0 to 15)  |
| 2    | Port #2      | `0RRR0BBB`  | Set Red and Blue brightness (3 bits each) |
| 3    | Port #2      | `00000GGG`  | Set Green brightness (3 bits)             |

Each color component uses 3 bits, allowing 8 intensity levels (0 to 7). After the Green byte is written, the palette index automatically increments, enabling rapid programming of consecutive palette entries by repeatedly writing only the color data.

## Accessing the VRAM

Read or write to VRAM address. The V9938 VRAM address counter is 17 bits wide, allowing it to address 128 KB of VRAM. The address bits are numbered A16 (most significant) through A0 (least significant).

|Step|Destination|7 |6 |5  |4  |3  |2  |1  |0  |Purpose |
|-   |-          |- |- |-  |-  |-  |-  |-  |-  |- |
|1   |R#14       |0 |0 |0  |0  |A16|A17|A17|0  |Load the high-order three bits (A16 to Al4) of the address counter|
|2   |Port #1    |A7|A6|A5 |A4 |A3 |A2 |A1 |A0 |Load the low-order eight bits (A7 to AO) of the address counter|
|3   |Port #1    |0 |X |A13|A12|A11|A10|A9 |A8 |Load the remaining six bits (A13 to A8) of the address counter and specify bit 6 (X) read=0 or write=1|

Once the address has been set, each read from or write to the VRAM data port automatically increments the address counter.