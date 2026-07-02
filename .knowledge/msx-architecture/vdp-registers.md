# Registers

## Control registers

(R#0 to R#23, R#32 to R#46)

| R#n  |                        Function                          |
|------|----------------------------------------------------------|
| R#0  | mode register #0                                         |
| R#1  | mode register #1                                         |
| R#2  | pattern name table                                       |
| R#3  | colour table (LOW)                                       |
| R#4  | pattern generator table                                  |
| R#5  | sprite attribute table (LOW)                             |
| R#6  | sprite pattern generator table                           |
| R#7  | border colour/character colour at text mode              |
| R#8  | mode register #2                                         |
| R#9  | mode register #3                                         |
| R#10 | colour table (HIGH)                                      |
| R#11 | sprite attribute table (HIGH)                            |
| R#12 | character colour at text blinks                          |
| R#13 | blinking period                                          |
| R#14 | VRAM access base address (HIGH)                          |
| R#15 | status address pointer                                   |
| R#16 | color palette address pointer                            |
| R#17 | objective address pointer                                |
| R#18 | screen location adjustment (ADJUST)                      |
| R#19 | scanning line number when the interrupt occurs           |
| R#20 | colour burst signal 1                                    |
| R#21 | colour burst signal 2                                    |
| R#22 | colour burst signal 3                                    |
| R#23 | screen hard scroll                                       |
| R#32 | SX: X-coordinate to be transferred (LOW)                 |
| R#33 | SX: X-coordinate to be transferred (HIGH)                |
| R#34 | SY: Y-coordinate to be transferred (LOW)                 |
| R#35 | SY: Y-coordinate to be transferred (HIGH)                |
| R#36 | DX: X-coordinate to be transferred to (LOW)              |
| R#37 | DX: X-coordinate to be transferred to (HIGH)             |
| R#38 | DY: Y-coordinate to be transferred to (LOW)              |
| R#39 | DY: Y-coordinate to be transferred to (HIGH)             |
| R#40 | NX: num. of dots to be transferred in X direction (LOW)  |
| R#41 | NX: num. of dots to be transferred in X direction (HIGH) |
| R#42 | NY: num. of dots to be transferred in Y direction (LOW)  |
| R#43 | NY: num. of dots to be transferred in Y direction (HIGH) |
| R#44 | CLR: for transferring data to CPU                        |
| R#45 | ARG: bank switching between VRAM and expanded VRAM       |
| R#46 | CMR: send VDP command                                    |

## Status registers

(S#0 to S#9)

| S#n  |                        Function                          |
|------|----------------------------------------------------------|
| S#0  | interrupt information                                    |
| S#1  | interrupt information                                    |
| S#2  | DP command control information/etc.                      |
| S#3  | coordinate detected (LOW)                                |
| S#4  | coordinate detected (HIGH)                               |
| S#5  | coordinate detected (LOW)                                |
| S#6  | coordinate detected (HIGH)                               |
| S#7  | data obtained by VDP command                             |
| S#8  | X-coordinate obtained by search command (LOW)            |
| S#9  | X-coordinate obtained by search command (HIGH)           |

##  Palette registers 

(P#0 to P#15)

These registers are used to set the colour palette. Registers are expressed using the notation P#n where ‘n’ is the palette number which represents one of 512 colours. Each palette register has 9 bits allowing three bits to be used for each RGB colour (red, green, and blue).