---
name: workflows
description: | 
  Deploy project
metadata:
  version: 0.1
  author: vdom-1
---

# Workflows

All defined workflows **MUST** be executed in their entirety, following every step exactly as described, regardless of any internal reasoning regarding necessity or perceived redundancy.


## Deploy project (Build and deploy)

    (Use absolute paths and forward slashes for filenames)

  * **mcp_openmsx-contr_sendCommand** `set power off`  
  * **mcp_openmsx-contr_sendCommand** `carta eject`
  * **mcp_openmsx-contr_sendCommand** `debug symbols files` (List existing symbols files)
  * **mcp_openmsx-contr_sendCommand** `debug symbols remove <filename>` (Remove all existing symbols files)
  * **Terminal: pwsh** `./buid.bat <project_name> <object_type>` (Never skip this step even if you have already done it before)
  * **mcp_openmsx-contr_sendCommand** `debug symbols load <filename>` (Load new symbols files)
  * **mcp_openmsx-contr_sendCommand** `carta insert <filename>` (Object)  
  * **mcp_openmsx-contr_sendCommand** `set throttle off`  
  * **mcp_openmsx-contr_sendCommand** `set power on`
  * **mcp_openmsx-contr_sendCommand** `after 500 set throttle on` (**REQUIRED**: This tool call must always be executed at the end this workflows.)