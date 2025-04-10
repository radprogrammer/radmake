@echo off
setlocal enabledelayedexpansion

set "REPO_DIR=%~1"

echo [INFO] Applying libgit2 patches...
echo [INFO] Repo: %REPO_DIR%



rem -----------------------------------------------------------------------------------------------------------------------------------------------------------------
rem Patch 1: Strip /** ... */ comments from problematic headers to prevent -Wdocumentation warnings. 
rem Problem: The Embarcadero bcc64x compiler treats certain /** ... */ Doxygen-style blocks as documentation directives
rem This PowerShell-based patch strips only the /** ... */ comment blocks from specific headers (path_w32.h, utf-conv.h, w32_util.h), preserving regular comments.
set "PS1_DOC_FIX=%TEMP%\radmake_patch_docblocks.ps1"

set "HDR1=%REPO_DIR%\src\util\win32\path_w32.h"
set "HDR2=%REPO_DIR%\src\util\win32\utf-conv.h"
set "HDR3=%REPO_DIR%\src\util\win32\w32_util.h"
set "HDR4=%REPO_DIR%\src\util\win32\path_w32.c"


if exist "%PS1_DOC_FIX%" del "%PS1_DOC_FIX%"

>> "%PS1_DOC_FIX%" echo $headers = @(
>> "%PS1_DOC_FIX%" echo     '%HDR1%',
>> "%PS1_DOC_FIX%" echo     '%HDR2%',
>> "%PS1_DOC_FIX%" echo     '%HDR3%',
>> "%PS1_DOC_FIX%" echo     '%HDR4%'
>> "%PS1_DOC_FIX%" echo ^)

>> "%PS1_DOC_FIX%" echo foreach ($file in $headers) ^{
>> "%PS1_DOC_FIX%" echo     if (Test-Path $file) ^{
>> "%PS1_DOC_FIX%" echo         Write-Host "[PATCH1] Removing comment blocks from: $file"
>> "%PS1_DOC_FIX%" echo         $lines = Get-Content -Path $file
>> "%PS1_DOC_FIX%" echo         $output = @()
>> "%PS1_DOC_FIX%" echo         $inBlock = $false
>> "%PS1_DOC_FIX%" echo         foreach ($line in $lines) ^{
>> "%PS1_DOC_FIX%" echo             if ($line -match '^\s*/\*\*') ^{ $inBlock = $true; continue }
>> "%PS1_DOC_FIX%" echo             if ($inBlock) ^{
>> "%PS1_DOC_FIX%" echo                 if ($line -match '\*/') ^{ $inBlock = $false }; continue
>> "%PS1_DOC_FIX%" echo             }
>> "%PS1_DOC_FIX%" echo             $output += $line
>> "%PS1_DOC_FIX%" echo         ^}
>> "%PS1_DOC_FIX%" echo         Set-Content -Path $file -Value $output -Encoding UTF8
>> "%PS1_DOC_FIX%" echo         Write-Host "[PATCH1] Comment blocks removed from: $file"
>> "%PS1_DOC_FIX%" echo     ^} else ^{
>> "%PS1_DOC_FIX%" echo         Write-Host "[PATCH1 FAIL] File not found: $file"
>> "%PS1_DOC_FIX%" echo     ^}
>> "%PS1_DOC_FIX%" echo ^}

powershell -ExecutionPolicy Bypass -File "%PS1_DOC_FIX%"
del "%PS1_DOC_FIX%"



rem -----------------------------------------------------------------------------------------------------------------------------------------------------------------
rem Patch 2: Overwrite git2.rc with compatible content
rem The original git2.rc uses VERSIONINFO macros in a way that's incompatible with brcc3
rem The file is replaced with a known-good, minimal VERSIONINFO block that uses static version numbers and string values in a compatible format

set "RC_FILE=%REPO_DIR%\src\libgit2\git2.rc"
set "PS1_RC_FIX=%TEMP%\radmake_patch_git2_rc.ps1"
echo [PATCH2] Rewriting RC file: %RC_FILE%
if exist "%PS1_RC_FIX%" del "%PS1_RC_FIX%"

>> "%PS1_RC_FIX%" echo $lines = @(
>> "%PS1_RC_FIX%" echo '#include ^<winver.h^>',
>> "%PS1_RC_FIX%" echo '#include "../../include/git2/version.h"',
>> "%PS1_RC_FIX%" echo 'VS_VERSION_INFO VERSIONINFO',
>> "%PS1_RC_FIX%" echo ' FILEVERSION 1,9,0,0',
>> "%PS1_RC_FIX%" echo ' PRODUCTVERSION 1,9,0,0',
>> "%PS1_RC_FIX%" echo ' FILEFLAGSMASK 0x3fL',
>> "%PS1_RC_FIX%" echo ' FILEFLAGS 0x0L',
>> "%PS1_RC_FIX%" echo ' FILEOS 0x40004L',
>> "%PS1_RC_FIX%" echo ' FILETYPE 0x1L',
>> "%PS1_RC_FIX%" echo ' FILESUBTYPE 0x0L',
>> "%PS1_RC_FIX%" echo 'BEGIN',
>> "%PS1_RC_FIX%" echo '    BLOCK "StringFileInfo"',
>> "%PS1_RC_FIX%" echo '    BEGIN',
>> "%PS1_RC_FIX%" echo '        BLOCK "040904b0"',
>> "%PS1_RC_FIX%" echo '        BEGIN',
>> "%PS1_RC_FIX%" echo '            VALUE "CompanyName", "libgit2 contributors"',
>> "%PS1_RC_FIX%" echo '            VALUE "FileDescription", "libgit2 - the Git linkable library"',
>> "%PS1_RC_FIX%" echo '            VALUE "FileVersion", "1.9.0"',
>> "%PS1_RC_FIX%" echo '            VALUE "InternalName", "git2"',
>> "%PS1_RC_FIX%" echo '            VALUE "OriginalFilename", "git2.dll"',
>> "%PS1_RC_FIX%" echo '            VALUE "ProductName", "libgit2"',
>> "%PS1_RC_FIX%" echo '            VALUE "ProductVersion", "1.9.0"',
>> "%PS1_RC_FIX%" echo '        END',
>> "%PS1_RC_FIX%" echo '    END',
>> "%PS1_RC_FIX%" echo '    BLOCK "VarFileInfo"',
>> "%PS1_RC_FIX%" echo '    BEGIN',
>> "%PS1_RC_FIX%" echo '        VALUE "Translation", 0x409, 1200',
>> "%PS1_RC_FIX%" echo '    END',
>> "%PS1_RC_FIX%" echo 'END'
>> "%PS1_RC_FIX%" echo )
>> "%PS1_RC_FIX%" echo Set-Content -Path "%RC_FILE%" -Value $lines -Encoding UTF8
>> "%PS1_RC_FIX%" echo Write-Host "[PATCH2 DONE] RC file overwritten successfully."

powershell -ExecutionPolicy Bypass -File "%PS1_RC_FIX%"
del "%PS1_RC_FIX%"



rem Patch3: MemoryBarrier is a Windows API macro defined in windows.h, but it's only available if windows.h includes winnt.h 
rem it's not being found, so need ot include it here
set "THREAD_FILE=%REPO_DIR%\src\util\thread.h"
set "PS1_THREAD_FIX=%TEMP%\radmake_patch_thread.ps1"
if exist "%PS1_THREAD_FIX%" del "%PS1_THREAD_FIX%"

>> "%PS1_THREAD_FIX%" echo $file = '%THREAD_FILE%'
>> "%PS1_THREAD_FIX%" echo if (Test-Path $file) ^{
>> "%PS1_THREAD_FIX%" echo     Write-Host "[CHECK PATCH3] Scanning $file for existing patch..."
>> "%PS1_THREAD_FIX%" echo     $text = Get-Content -Raw -Path $file
>> "%PS1_THREAD_FIX%" echo     if ($text -notmatch 'radmake_patch3') ^{
>> "%PS1_THREAD_FIX%" echo         Write-Host "[PATCH3] applying to $file"
>> "%PS1_THREAD_FIX%" echo         $lines = Get-Content -Path $file
>> "%PS1_THREAD_FIX%" echo         $output = @()
>> "%PS1_THREAD_FIX%" echo         $output += '^/* includes radmake_patch3 *^/'
>> "%PS1_THREAD_FIX%" echo         $inserted = $false
>> "%PS1_THREAD_FIX%" echo         foreach ($line in $lines) ^{
>> "%PS1_THREAD_FIX%" echo(            if (-not $inserted -and $line -like '*GIT_MEMORY_BARRIER MemoryBarrier()*') ^{
>> "%PS1_THREAD_FIX%" echo                 $inserted = $true
>> "%PS1_THREAD_FIX%" echo(                $output += '#  include ^<windows.h^>'
>> "%PS1_THREAD_FIX%" echo(                $output += '#  ifndef MemoryBarrier'
>> "%PS1_THREAD_FIX%" echo(                $output += '#    define MemoryBarrier() ((void)0)'
>> "%PS1_THREAD_FIX%" echo(                $output += '#  endif'
>> "%PS1_THREAD_FIX%" echo             ^}
>> "%PS1_THREAD_FIX%" echo             $output += $line
>> "%PS1_THREAD_FIX%" echo         ^}
>> "%PS1_THREAD_FIX%" echo         Set-Content -Path $file -Value $output -Encoding UTF8
>> "%PS1_THREAD_FIX%" echo         Write-Host "[PATCH3] applied to $file"
>> "%PS1_THREAD_FIX%" echo     ^} else ^{
>> "%PS1_THREAD_FIX%" echo         Write-Host "[SKIP] Patch 3 already applied"
>> "%PS1_THREAD_FIX%" echo     ^}
>> "%PS1_THREAD_FIX%" echo ^} else ^{
>> "%PS1_THREAD_FIX%" echo     Write-Host "[ERROR PATCH 3] File not found: $file"
>> "%PS1_THREAD_FIX%" echo ^}

powershell -ExecutionPolicy Bypass -File "%PS1_THREAD_FIX%"
del "%PS1_THREAD_FIX%"



rem PATCH4: Mark hash_sha1_win32_ctx_init as unused via attribute to suppress warning
set "HASH_FILE=%REPO_DIR%\src\util\hash\win32.c"
set "PS1_HASH_FIX=%TEMP%\radmake_patch_hash_unused.ps1"
if exist "%PS1_HASH_FIX%" del "%PS1_HASH_FIX%"

>> "%PS1_HASH_FIX%" echo $file = '%HASH_FILE%'
>> "%PS1_HASH_FIX%" echo if (Test-Path $file) ^{
>> "%PS1_HASH_FIX%" echo     Write-Host "[CHECK PATCH4] Scanning $file for radmake_patch4..."
>> "%PS1_HASH_FIX%" echo     $text = Get-Content -Raw -Path $file
>> "%PS1_HASH_FIX%" echo     if ($text -notmatch 'radmake_patch4') ^{
>> "%PS1_HASH_FIX%" echo         Write-Host "[PATCH4] applying to $file"
>> "%PS1_HASH_FIX%" echo         $lines = Get-Content -Path $file
>> "%PS1_HASH_FIX%" echo         $output = @()
>> "%PS1_HASH_FIX%" echo         $output += '^/* includes radmake_patch4 *^/'
>> "%PS1_HASH_FIX%" echo         foreach ($line in $lines) ^{
>> "%PS1_HASH_FIX%" echo(            if ($line -match '^\s*GIT_INLINE\s*\(\s*int\s*\)\s*hash_sha1_win32_ctx_init') ^{
>> "%PS1_HASH_FIX%" echo                 $output += '__attribute__((unused)) ' + $line
>> "%PS1_HASH_FIX%" echo             ^} else ^{
>> "%PS1_HASH_FIX%" echo                 $output += $line
>> "%PS1_HASH_FIX%" echo             ^}
>> "%PS1_HASH_FIX%" echo         ^}
>> "%PS1_HASH_FIX%" echo         Set-Content -Path $file -Value $output -Encoding UTF8
>> "%PS1_HASH_FIX%" echo         Write-Host "[PATCH4] applied to $file"
>> "%PS1_HASH_FIX%" echo     ^} else ^{
>> "%PS1_HASH_FIX%" echo         Write-Host "[SKIP] Patch 4 already applied"
>> "%PS1_HASH_FIX%" echo     ^}
>> "%PS1_HASH_FIX%" echo ^} else ^{
>> "%PS1_HASH_FIX%" echo     Write-Host "[ERROR PATCH4] File not found: $file"
>> "%PS1_HASH_FIX%" echo ^}

powershell -ExecutionPolicy Bypass -File "%PS1_HASH_FIX%"
del "%PS1_HASH_FIX%"



exit /b 0