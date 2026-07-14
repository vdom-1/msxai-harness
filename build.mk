# Default configuration (Linux / macOS fallback)
JAVA = java
RUN_JAVA = $(JAVA)
GLASS = $(HOME)/MSX/openmsx-control-wslc/glass.jar
MKDIR = mkdir -p
NULL_DEV = /dev/null
ECHO_EMPTY = echo

# Clean result printing for Linux
PRINT_RESULT = echo "Object:  $(TARGET_BINARY) ($$(stat -c%s "$(TARGET_BINARY)" 2>/dev/null || stat -f%z "$(TARGET_BINARY)" 2>/dev/null) bytes)"

# -------------------------------------------------------------
# Detect Windows and overwrite paths / commands for CMD
# -------------------------------------------------------------
ifeq ($(OS),Windows_NT)
    JAVA = $(USERPROFILE)/MSX/devtools/jre1.8.0_202/bin/java.exe
    RUN_JAVA = "$(JAVA)"
    GLASS = $(USERPROFILE)/MSX/devtools/Glass-0.7-SNAPSHOT/glass.jar
    
    # CMD native directory creator
    MKDIR = if not exist "$(PROJECT_OUT_DIR)" mkdir
    NULL_DEV = nul
    ECHO_EMPTY = echo.
    
    # CMD native file-size print
    PRINT_RESULT = for %%I in ("$(TARGET_BINARY)") do @echo Object:  $(TARGET_BINARY) (%%~zI bytes)
endif

# Ensure target inputs are defined
ifndef PROJECT
	$(error PROJECT is undefined. Use: make PROJECT=<project_name> TYPE=<rom|bin|com>)
endif

ifndef TYPE
	$(error TYPE is undefined. Use: make PROJECT=<project_name> TYPE=<rom|bin|com>)
endif

# Build paths
PROJECT_SRC_DIR = ./src/$(PROJECT)
MAIN_ASM = $(PROJECT_SRC_DIR)/$(PROJECT).asm
PROJECT_OUT_DIR = ./out/$(PROJECT)
TARGET_BINARY = $(PROJECT_OUT_DIR)/$(PROJECT).$(TYPE)

.PHONY: all build

all: build

build:
	@echo Build STARTED
	@echo Project Name: $(PROJECT)
	@echo Object Type:  $(TYPE)
	@echo Main Source:  $(MAIN_ASM)
	@$(ECHO_EMPTY)
	@$(MKDIR) "$(PROJECT_OUT_DIR)" >$(NULL_DEV) 2>&1
	@$(RUN_JAVA) -jar "$(GLASS)" -L "$(PROJECT_OUT_DIR)/$(PROJECT).lst" "$(MAIN_ASM)" "$(TARGET_BINARY)" "$(PROJECT_OUT_DIR)/$(PROJECT).sym"
	@$(ECHO_EMPTY)
	@echo Build SUCCEEDED
	@echo **Artifacts generated**
	@$(PRINT_RESULT)
	@echo Symbols: $(PROJECT_OUT_DIR)/$(PROJECT).sym
	@echo Listing: $(PROJECT_OUT_DIR)/$(PROJECT).lst