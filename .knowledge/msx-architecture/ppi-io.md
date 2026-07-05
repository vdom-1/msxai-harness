# Programmable Peripheral Interface

The 8255 PPI is a general purpose parallel interface device configured as three eight bit data ports, called A, B and C, and a mode port. It appears to the Z80 as four I/O ports through which the keyboard, the memory switching hardware, the cassette motor, the cassette output, the Caps Lock LED and the Key Click audio output can be controlled. Once the PPI has been initialized access to a particular piece of hardware just involves writing to or reading the relevant I/O port.

|  Port     | Value | Description |  Access mode   |
|-----------|-------|-----|----------------|
| Port A    | A8H   | Primary Slot Register | READ and WRITE |
| Port B    | A9H   |  | READ and WRITE |
| Port C    | AAH   |  | WRITE-only     |
| Mode Port | ABH   |  | WRITE-only     |



## PPI Port A (I/O Port A8H)

|Page  | Adress      | Bits    | 
|------|-------------|---------| 
|Page 0| 0000 to 3FFF| 1 and 0 | 
|Page 1| 4000 to 7FFF| 3 and 2 | 
|Page 2| 8000 to BFFF| 5 and 4 | 
|Page 3| c000 to FFFF| 7 and 6 | 


