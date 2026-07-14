# Ensure target inputs are defined first to fail fast
ifndef PROJECT
    $(error PROJECT is undefined. Use: make PROJECT=<project_name> TYPE=<rom|bin|com>)
endif

ifndef TYPE
    $(error TYPE is undefined. Use: make PROJECT=<project_name> TYPE=<rom|bin|com>)
endif

# -------------------------------------------------------------
# Absolute Path Resolution (Zero shell calls, 100% stable)
# -------------------------------------------------------------
ROOT_DIR := $(subst \,/,$(CURDIR))

# Define absolute paths for our build execution
SRC_DIR  := $(ROOT_DIR)/src/$(PROJECT)
OUT_DIR  := $(ROOT_DIR)/out/$(PROJECT)

MAIN_ASM      := $(SRC_DIR)/$(PROJECT).asm
TARGET_BINARY := $(OUT_DIR)/$(PROJECT).$(TYPE)

# -------------------------------------------------------------
# Default configuration (Linux / macOS fallback)
# -------------------------------------------------------------
JAVA = java
RUN_JAVA = $(JAVA)
GLASS = $(HOME)/MSX/openmsx-control-wslc/glass.jar
MKDIR = mkdir -p
NULL_DEV = /dev/null
ECHO_EMPTY = echo

# Linux shell needs quotes to prevent tilde expansion
QUOTE = "

# -------------------------------------------------------------
# Detect Windows and overwrite paths / commands for CMD
# -------------------------------------------------------------
ifeq ($(OS),Windows_NT)
    WIN_HOME := $(subst \,/,$(USERPROFILE))
    
    JAVA = $(WIN_HOME)/MSX/devtools/jre1.8.0_202/bin/java.exe
    RUN_JAVA = "$(JAVA)"
    GLASS = $(WIN_HOME)/MSX/devtools/Glass-0.7-SNAPSHOT/glass.jar
    
    MKDIR = if not exist "$(OUT_DIR)" mkdir
    NULL_DEV = nul
    ECHO_EMPTY = echo.
    
    TIDY_WORKSPACE = ~$(subst $(WIN_HOME),,$(ROOT_DIR))

    # CMD prints quotes literally, so we remove them!
    QUOTE = 

    # CMD native file-size and path print (Removed quotes around string)
    PRINT_RESULT = for %%I in ("$(TARGET_BINARY)") do @echo Object:  $(TIDY_WORKSPACE)/out/$(PROJECT)/$(PROJECT).$(TYPE) (%%~zI bytes)
endif

# Fallback to the original working Linux path resolution
ifndef TIDY_WORKSPACE
    TIDY_WORKSPACE = ~$(subst $(HOME),,$(ROOT_DIR))
endif

# -------------------------------------------------------------
# Clean paths constructed exclusively for user-facing terminal prints
# -------------------------------------------------------------
TIDY_MAIN_ASM = $(TIDY_WORKSPACE)/src/$(PROJECT)/$(PROJECT).asm
TIDY_OUT      = $(TIDY_WORKSPACE)/out/$(PROJECT)/$(PROJECT).$(TYPE)
TIDY_SYM      = $(TIDY_WORKSPACE)/out/$(PROJECT)/$(PROJECT).sym
TIDY_LST      = $(TIDY_WORKSPACE)/out/$(PROJECT)/$(PROJECT).lst

.PHONY: all build

all: build

build:
	@echo $(QUOTE)Build STARTED$(QUOTE)
	@echo $(QUOTE)Project Name: $(PROJECT)$(QUOTE)
	@echo $(QUOTE)Object Type:  $(TYPE)$(QUOTE)
	@echo $(QUOTE)Main Source:  $(TIDY_MAIN_ASM)$(QUOTE)
	@$(ECHO_EMPTY)
	@$(MKDIR) "$(OUT_DIR)" >$(NULL_DEV) 2>&1
	@$(RUN_JAVA) -jar "$(GLASS)" -L "$(OUT_DIR)/$(PROJECT).lst" "$(MAIN_ASM)" "$(TARGET_BINARY)" "$(OUT_DIR)/$(PROJECT).sym"
	@$(ECHO_EMPTY)
	@echo $(QUOTE)Build SUCCEEDED$(QUOTE)
	@echo $(QUOTE)**Artifacts generated**$(QUOTE)
ifeq ($(OS),Windows_NT)
	@$(PRINT_RESULT)
	@echo Symbols: $(TIDY_SYM)
	@echo Listing: $(TIDY_LST)
else
	@echo "Object:  $(TIDY_OUT) ($$({ stat -c%s "$(TARGET_BINARY)" || stat -f%z "$(TARGET_BINARY)"; } 2>/dev/null) bytes)"
	@echo "Symbols: $(TIDY_SYM)"
	@echo "Listing: $(TIDY_LST)"
endif