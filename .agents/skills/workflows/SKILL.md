---
name: workflows
description: | 
  Deploy project
metadata:
  version: 0.1
  author: vdom-1
---

# Workflows

All workflows defined in this file must be executed autonomously, following every step in sequence without interruption unless an error is encountered.

*(Always use absolute paths and forward slashes for filenames)*

## Deploy project

Progress:
- [ ] Step 1: **mcp_openmsx-contr_sendCommand** `set power off`
- [ ] Step 2: **mcp_openmsx-contr_sendCommand** `carta eject`
- [ ] Step 3: **mcp_openmsx-contr_sendCommand** `debug symbols files` (List existing symbols files)
- [ ] Step 4: **mcp_openmsx-contr_sendCommand** `debug symbols remove <filename>` (Remove all existing symbols files)
- [ ] Step 5: **Run in terminal** `.\build.bat <project_name> <object_type>` (Never skip this step even if you have already done it before)
- [ ] Step 6: **mcp_openmsx-contr_sendCommand** `debug symbols load <filename>` (Load new symbols file)
- [ ] Step 7: **mcp_openmsx-contr_sendCommand** `carta insert <filename>` (Use the object file)
- [ ] Step 8: **mcp_openmsx-contr_sendCommand** `set throttle off`  
- [ ] Step 9: **mcp_openmsx-contr_sendCommand** `set power on`
- [ ] Step 10: **mcp_openmsx-contr_sendCommand** `after 500 set throttle on` (**REQUIRED**)