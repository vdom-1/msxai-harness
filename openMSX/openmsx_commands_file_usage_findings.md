# Commands

| Check | Command | Description | Notes |
|:-----:|---------|-----------------------|-------|
| [  ] | `cart <filename>` / `carta` / `cartb` | Inserts ROM cartridge from file | Includes IPS patch option |
| [  ] | `cart insert <filename>` / `carta insert` / `cartb insert` | Inserts ROM cartridge from file | Includes IPS patch option |
| [  ] | `casload <file>` | Opens CAS-file for loading | Part of CAS-file tools |
| [  ] | `cassave <file>` | Saves to a CAS-file | Part of CAS-file tools |
| [  ] | `casrun <file> [<number>]` | Automatically runs program from CAS-file | Part of CAS-file tools |
| [  ] | `cassetteplayer <filename>` | Inserts a tape file image | |
| [  ] | `data_file` | Resolves files from user/system directories | `$::env(OPENMSX_SYSTEM_DATA)` |
| [  ] | `debug symbols load <filename> [<type>]` | Loads a symbol file into the debugger | Subcommand of `debug symbols` |
| [  ] | `debug symbols remove <filename>` | Removes a previously loaded symbol file | Subcommand of `debug symbols` |
| [  ] | `debug symbols lookup [-filename <filename>] [-name <name>] [-value <value>]` | Returns a list of symbols in an optionally given file and/or with an optionally given name/value | Subcommand of `debug symbols` |
| [  ] | `diska insert -ips <filename> <diskfile>` | Inserts disk image with optional IPS patch | Option for `diska insert` |
| [  ] | `diskmanipulator create <fn> <sz>` | Creates a formatted dsk file named `<fn>` | |
| [  ] | `diskmanipulator savedsk <dn> <fn>` | Saves disk `<dn>` as dsk file named `<fn>` | |
| [  ] | `diskmanipulator dir <dn>` | Lists files in current directory of `<dn>` | |
| [  ] | `diskmanipulator import <disk> <dir/file>` | Imports files and subdirs from `<dir/file>` | |
| [  ] | `diskmanipulator export <disk> <host dir>` | Exports all files on `<disk>` to `<host dir>` | |
| [  ] | `diskmanipulator rename <disk> <old> <new>` | Renames a file or directory on disk | |
| [  ] | `get_breakpoints_dir` | Returns breakpoint directory path | |
| [  ] | `load_breakpoints <file>` | Loads breakpoints from file | |
| [  ] | `load_debuggable <file>` | Loads raw data into a debuggable from file | |
| [  ] | `load_machine` | Loads machine configuration from file | |
| [  ] | `load_session <name>` | Restores session (likely uses files) | |
| [  ] | `load_settings <file>` | Loads settings from given file | |
| [  ] | `loadstate <name>` | Restores a previously created savestate | |
| [  ] | `multi_screenshot <num> [<base>]` | Takes multiple screenshots (saves files) | |
| [  ] | `psg_log start <filename>` | Logs PSG registers to file | |
| [  ] | `record start <filename>` | Records video/audio to .avi file | |
| [  ] | `reg_log record <debuggable> [<filename>]` | Logs debuggable state to file | |
| [  ] | `reg_log play <debuggable> <filename>` | Replays a log in `<filename>` | Subcommand of `reg_log` |
| [  ] | `save_breakpoints <file>` | Saves breakpoints to file | |
| [  ] | `save_debuggable <debuggable> <file>` | Saves part of a debuggable to file | |
| [  ] | `save_msx_screen` | Saves current screen to binary file | MSX compatible format |
| [  ] | `save_session <name>` | Saves session state to files | |
| [  ] | `save_settings` | Saves the current settings | Likely config file |
| [  ] | `save_to_file <args> <filename>` | Helper procedure to write command output to a file | |
| [  ] | `savestate <name>` | Creates a snapshot/savestate file | |
| [  ] | `sdcdb open <directories> [<cdbFile>]` | Opens a project directory and starts debugging session | Subcommand of `sdcdb` |
| [  ] | `sdcdb list <file>:<line/functionName>` | Lists contents of a C source file at specific location | Subcommand of `sdcdb` |
| [  ] | `screenshot <filename>` | Writes screenshot to indicated file | Supports `-prefix`, `-raw` etc. |
| [  ] | `sha1sum <file>` | Calculates SHA1 value for the given file | |
| [  ] | `store_machine <id> <file>` | Saves machine state to file | Low-level command |
| [  ] | `store_setup <depth> [file]` | Saves setup to file | |
| [  ] | `type_from_file <args> <filename>` | Types content of the indicated file | |
| [  ] | `type_password_from_file <filename> <index>` | Types a specific line from file | Useful for passwords |
| [  ] | `vgm_rec` | Records VGM file from audio | |