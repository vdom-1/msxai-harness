@echo off
setlocal

set "JAVA=C:/Users/Victor/MSX/devtools/jre1.8.0_202/bin/java.exe"
set "GLASS=C:/Users/Victor/MSX/devtools/glass.jar"

set "PROJECT_NAME=%~1"
set "OBJECT_TYPE=%~2"

if "%PROJECT_NAME%"=="" (
    echo Usage: build.bat ^<project_name^> ^<rom^|bin^|com^>
    exit /b 1
)

if "%OBJECT_TYPE%"=="" (
    echo Usage: build.bat ^<project_name^> ^<rom^|bin^|com^>
    exit /b 1
)

if /I not "%OBJECT_TYPE%"=="rom" if /I not "%OBJECT_TYPE%"=="bin" if /I not "%OBJECT_TYPE%"=="com" (
    echo Error: OBJECT_TYPE must be rom, bin, or com.
    exit /b 1
)

set "PROJECT_SRC_DIR=./src/%PROJECT_NAME%"
if not exist "%PROJECT_SRC_DIR%/%PROJECT_NAME%.asm" (
    echo Error: Source file "%PROJECT_SRC_DIR%/%PROJECT_NAME%.asm" not found.
    exit /b 1
)

echo.
echo Build STARTED
echo.
echo Project Name: %PROJECT_NAME%
echo Object Type: %OBJECT_TYPE%
echo Main Source: %PROJECT_SRC_DIR%/%PROJECT_NAME%.asm
echo.

set "PROJECT_OUT_DIR=./out/%PROJECT_NAME%"
mkdir "%PROJECT_OUT_DIR%" 2>nul

"%JAVA%" -jar "%GLASS%" ^
    -L "%PROJECT_OUT_DIR%/%PROJECT_NAME%.lst" ^
    "%PROJECT_SRC_DIR%/%PROJECT_NAME%.asm" ^
    "%PROJECT_OUT_DIR%/%PROJECT_NAME%.%OBJECT_TYPE%" ^
    "%PROJECT_OUT_DIR%/%PROJECT_NAME%.sym"

set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo Build FAILED
    echo Exit code %RC%
    exit /b %RC%
)

echo Build SUCCEEDED
echo.
echo **Files generated**
for %%F in ("%PROJECT_OUT_DIR%/%PROJECT_NAME%.%OBJECT_TYPE%") do set "BINARY_SIZE_BYTES=%%~zF"
echo Object: %PROJECT_OUT_DIR%/%PROJECT_NAME%.%OBJECT_TYPE% (%BINARY_SIZE_BYTES% bytes)
echo Symbols: %PROJECT_OUT_DIR%/%PROJECT_NAME%.sym
echo Listing: %PROJECT_OUT_DIR%/%PROJECT_NAME%.lst
echo.

endlocal