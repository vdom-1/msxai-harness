# Graphic Mode 3

## VRAM layout

| Table Name                    | Address | Register |
|-------------------------------|---------|----------|
| Pattern Generator Table       | 0000H   | R#4      |
| Pattern Name Table            | 1800H   | R#2      |
| Color Table (Low)             | 00H     | R#3      |
| Color Table (High)            | 20H     | R#10     |
| Sprite Attribute Table (Low)  | 00H     | R#5      |
| Sprite Attribute Table (High) | 1EH     | R#11     |
| Sprite Generator Table        | 3800H   | R#6      |