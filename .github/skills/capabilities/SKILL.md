---
name: capabilities
description: | 
  identify machine (hardware configuration)
metadata:
  version: 0.1
  author: vdom-1
---

# Capabilities

Capabilities frequently requested by the user.

## Identify machine (Hardware configuration)

    Identifying a machine involves gathering all relevant information(type, config_name, z80_freq, r800_freq if applicable and "device VDP") and presenting them as a complete set of information.

  * **mcp_openmsx-contr_sendCommand** `machine_info type`
  * **mcp_openmsx-contr_sendCommand** `machine_info config_name`
  * **mcp_openmsx-contr_sendCommand** `machine_info z80_freq`
  * **mcp_openmsx-contr_sendCommand** If `machine_info type` equals "MSXTurboR", also include `machine_info r800_freq`
  * **mcp_openmsx-contr_sendCommand** `machine_info device VDP`