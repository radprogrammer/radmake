@echo off
setlocal

set "SOURCE_DIR=%~1"
set "TARGET_FILE=%SOURCE_DIR%\src\catch2\internal\catch_compiler_capabilities.hpp"
set "PS1_FILE=%TEMP%\radmake_patch_catch2_isnan.ps1"

if not exist "%TARGET_FILE%" (
    echo ERROR: Target file does not exist.
    exit /b 1
)

rem Clear old script
if exist "%PS1_FILE%" del "%PS1_FILE%"

rem Write patch script
>> "%PS1_FILE%" echo $file = Get-Content -Raw -Path "%TARGET_FILE%"
>> "%PS1_FILE%" echo if ($file -match '^[ \t]*#define[ \t]+CATCH_INTERNAL_CONFIG_POLYFILL_ISNAN') ^{
>> "%PS1_FILE%" echo     $patched = $file -replace '^[ \t]*#define[ \t]+CATCH_INTERNAL_CONFIG_POLYFILL_ISNAN', '//     #define CATCH_INTERNAL_CONFIG_POLYFILL_ISNAN // RADMAKE PATCH: disabled CATCH_INTERNAL_CONFIG_POLYFILL_ISNAN'
>> "%PS1_FILE%" echo     Set-Content -Path "%TARGET_FILE%" -Value $patched -Encoding UTF8
>> "%PS1_FILE%" echo     Write-Host "Patch applied."
>> "%PS1_FILE%" echo ^} else ^{
>> "%PS1_FILE%" echo     Write-Host "Patch already applied or line not found."
>> "%PS1_FILE%" echo ^}

powershell -ExecutionPolicy Bypass -File "%PS1_FILE%"
del "%PS1_FILE%"
exit /b 0

