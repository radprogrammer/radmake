@echo off
setlocal enabledelayedexpansion

rem -------------------------------------------------------------------------------------------------------------------
rem https://github.com/radprogrammer/radmake 
rem -------------------------------------------------------------------------------------------------------------------


rem -------------------------------------------------------------------------------------------------------------------
rem Establish working path 
set "pwd=%~dp0"
set "pwd=%pwd:~0,-1%"

rem -------------------------------------------------------------------------------------------------------------------
rem Enable ANSI escape sequences (Windows 10+)
>nul 2>&1 reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f

rem Define ESC character
for /f %%A in ('"prompt $E & for %%B in (1) do rem"') do set "ESC=%%A"


rem -------------------------------------------------------------------------------------------------------------------
rem Ensure some parameters are provided
if /i "%~1"=="--help" goto PrintUsage
if /i "%~1"=="/?" goto PrintUsage
if "%~1"=="" (
    call :PrintUsage
    exit /b 1
)


rem -------------------------------------------------------------------------------------------------------------------
rem Full list of configurable variables, some with defaults
rem If a variable has been established, it can be overwritten by build-profile INI
set "undefined_flag=undefined"
set "radmake_profilename=%undefined_flag%"
set "radmake_reponame=%undefined_flag%"
set "radmake_branch=master"
set "radmake_buildtype=Release"
set "radmake_cleanflag=none"
set "radmake_repofolder=%undefined_flag%"
set "radmake_cmakelistpathinrepo=%undefined_flag%"
set "radmake_outputfolder=%undefined_flag%"
set "radmake_installfolder=%undefined_flag%"
set "radmake_cmaketxt=%undefined_flag%"
set "radmake_patchbat=%undefined_flag%"
set "radmake_postinstallbat=%undefined_flag%"
set "radmake_prebuildbat=%undefined_flag%"
set "radmake_workfolder=%undefined_flag%"
set "radmake_asmcompiler=%undefined_flag%"
set "radmake_ccompiler=%undefined_flag%"
set "radmake_cxxcompiler=%undefined_flag%"
set "radmake_rsvarspath64=%undefined_flag%"
set "radmake_log_level=0"
set "radmake_configversion=1"



rem -------------------------------------------------------------------------------------------------------------------
rem Parse named and short parameters
:ParseArgs
if "%~1"=="" goto ArgsDone

set "radmake_arg1=%1"

set "arg=%~1"
set "val="

rem First, handle --key=value style
echo %arg% | find "=" >nul
if not errorlevel 1 (
    for /F "tokens=1,2 delims==" %%A in ("%arg%") do (
        set "arg=%%A"
        set "val=%%B"
    )
) else (
    rem Handle --key value style
    set "val=%~2"
    shift
)



if /I "%arg%"=="-a" set "arg=--patch-bat"
if /I "%arg%"=="-b" set "arg=--branch"
if /I "%arg%"=="-c" set "arg=--clean-flag"
if /I "%arg%"=="-d" set "arg=--clone-to"
if /I "%arg%"=="-e" set "arg=--prebuild-bat"
if /I "%arg%"=="-f" set "arg=--profile-folder"
if /I "%arg%"=="-h" set "arg=--help"
if /I "%arg%"=="-i" set "arg=--install-to"
if /I "%arg%"=="-l" set "arg=--postinstall-bat"
if /I "%arg%"=="-m" set "arg=--cmake_opts"
if /I "%arg%"=="-o" set "arg=--output-to"
if /I "%arg%"=="-p" set "arg=--profile-name"
if /I "%arg%"=="-r" set "arg=--repo"
if /I "%arg%"=="-t" set "arg=--build-type"
if /I "%arg%"=="-w" set "arg=--work-folder"


if /I "%arg%"=="--repo"        set "custom_reponame=%val%"
if /I "%arg%"=="--branch"      set "custom_branch=%val%"
if /I "%arg%"=="--build-type"  set "custom_buildtype=%val%"
if /I "%arg%"=="--clean-flag"  set "custom_cleanflag=%val%"
if /I "%arg%"=="--clone-to"    set "custom_repofolder=%val%"
if /I "%arg%"=="--install-to"  set "custom_installfolder=%val%"
if /I "%arg%"=="--output-to"   set "custom_outputfolder=%val%"
if /I "%arg%"=="--prebuild-bat"   set "custom_prebuildbatch=%val%"
if /I "%arg%"=="--postinstall-bat" set "custom_postinstallbatch=%val%"
if /I "%arg%"=="--patch-bat" set "custom_patchbatch=%val%"
if /I "%arg%"=="--cmake_opts" set "custom_cmaketxt=%val%"
if /I "%arg%"=="--work-folder" set "custom_workfolder=%val%"
if /I "%arg%"=="--profile-name" set "custom_profilename=%val%"
if /I "%arg%"=="--profile-folder" set "custom_profilefolder=%val%"

if /I "%arg%"=="--help"        goto PrintUsage

if /i "%arg%"=="--log-level" (
    if "%val%"=="quiet" (
      set "radmake_log_level=0"
    ) else if "%val%"=="verbose" (
      echo Log level = verbose
      set "radmake_log_level=5"
    ) else if "%val%"=="debug" (
      echo Log level = debug
      set "radmake_log_level=10"
    )
)

shift
goto ParseArgs

:ArgsDone

rem -------------------------------------------------------------------------------------------------------------------
rem Profiles configure default values, but can always be overridden by command-line parameters

rem The file "radmake-{name}-profile.ini" is used to provide defaults  (only one file is currently used / no hierachy at this time)
rem First look in {profile-folder}\radmake-{name}-profile.ini if a custom_profilename provided
rem otherwise look in .\build-profiles\{name}\   as-expected when run from original radmake repo folder
rem otherwise look in .\  
if defined custom_profilename set "radmake_profilename=%custom_profilename%"

if "!radmake_profilename!"=="%undefined_flag%" (
   if "%~2"=="" (
     rem Exactly one parameter was provided, use it as profile name %1
     set "radmake_profilename=%radmake_arg1%"
   )
)
  
if "!radmake_profilename!"=="%undefined_flag%" (
    call :missingParam radmake_profilename || goto :END
    exit /b 1
)

set "radmake_profilefolder=%custom_profilefolder%"
if not defined custom_profilefolder (
  if exist "%pwd%\build-profiles\%radmake_profilename%" (
    set "radmake_profilefolder=%pwd%\build-profiles\%radmake_profilename%"
  ) else (
    set "radmake_profilefolder=%pwd%"
  )
)

call :cecho 92 "radmake [%radmake_profilename%]"

rem -------------------------------------------------------------------------------------------------------------------
rem Parse build profile ini

set "radmake_profileini=%radmake_profilefolder%\radmake-%radmake_profilename%-profile.ini"
call :parse_profile_ini "!radmake_profileini!"


rem -------------------------------------------------------------------------------------------------------------------
rem Override settings if provided by command line parameters
if defined custom_reponame set "radmake_reponame=%custom_reponame%"
if defined custom_branch set "radmake_branch=%custom_branch%"
if defined custom_buildtype set "radmake_buildtype=%custom_buildtype%"
if defined custom_cleanflag set "radmake_cleanflag=%custom_cleanflag%"
if defined custom_repofolder set "radmake_repofolder=%custom_repofolder%"
if defined custom_installfolder set "radmake_installfolder=%custom_installfolder%"
if defined custom_outputfolder set "radmake_outputfolder=%custom_outputfolder%"
if defined custom_prebuildbatch set "radmake_prebuildbat=%custom_prebuildbatch%"
if defined custom_postinstallbatch set "radmake_postinstallbat=%custom_postinstallbatch%"
if defined custom_cmaketxt set "radmake_cmaketxt=%custom_cmaketxt%"
if defined custom_workfolder set "radmake_workfolder=%custom_workfolder%"
if defined custom_patchbatch set "radmake_patchbat=%custom_patchbatch%"


rem -------------------------------------------------------------------------------------------------------------------
rem Provide defaults values for all variables that have not been set by build-profile or by user in the command line parameters
if "!radmake_workfolder!"=="%undefined_flag%" (set "radmake_workfolder=%pwd%\work\%radmake_profilename%")
if "!radmake_repofolder!"=="%undefined_flag%" (set "radmake_repofolder=%radmake_workfolder%\%radmake_profilename%-repo")
if "!radmake_installfolder!"=="%undefined_flag%" (set "radmake_installfolder=%radmake_workfolder%\%radmake_profilename%-install")
if "!radmake_outputfolder!"=="%undefined_flag%" (set "radmake_outputfolder=%radmake_workfolder%\%radmake_profilename%-build")
if "!radmake_cmaketxt!"=="%undefined_flag%" (set "radmake_cmaketxt=%radmake_profilefolder%\radmake-%radmake_profilename%-cmake.txt")
if "!radmake_patchbat!"=="%undefined_flag%" (set "radmake_patchbat=%radmake_profilefolder%\radmake-%radmake_profilename%-patch.bat")
if "!radmake_postinstallbat!"=="%undefined_flag%" (set "radmake_postinstallbat=%radmake_profilefolder%\radmake-%radmake_profilename%-postinstall.bat")
if "!radmake_prebuildbat!"=="%undefined_flag%" (set "radmake_prebuildbat=%radmake_profilefolder%\radmake-%radmake_profilename%-prebuild.bat")

if "!radmake_rsvarspath64!"=="%undefined_flag%" (
  call :find_latest_rsvars
  if "!radmake_rsvarspath64!"=="%undefined_flag%" (
    call :cecho 91 "[ERROR] Could not find rsvars.bat file!"
    exit /b 1
  )
)
call "%radmake_rsvarspath64%" || goto :END
call :check_required_tools git || goto :END

if "!radmake_asmcompiler!"=="%undefined_flag%" (set "radmake_asmcompiler=!BDS!\bin64\bcc64x.exe")
if "!radmake_ccompiler!"=="%undefined_flag%" (set "radmake_ccompiler=!BDS!\bin64\bcc64x.exe")
if "!radmake_cxxcompiler!"=="%undefined_flag%" (set "radmake_cxxcompiler=!BDS!\bin64\bcc64x.exe")


if "!radmake_reponame!"=="%undefined_flag%" (
  call :missingParam radmake_reponame || goto :END
  exit /b 1
 )
set "repo_uri=%radmake_reponame%"

rem Normalize 'all' cleanflag
set "radmake_cleanflag=%radmake_cleanflag: =%"
set "radmake_cleanflag=%radmake_cleanflag:"=%"  rem remove quotes if passed
if /i "%radmake_cleanflag%"=="all" (
    set "radmake_cleanflag=source+build+install"
)

rem additional variables not available to be set (yet) by command line parameters
if "!radmake_cmakelistpathinrepo!"=="%undefined_flag%" (set "radmake_cmakelistpathinrepo=")


rem -------------------------------------------------------------------------------------------------------------------
rem Relay all parsed settings for clarity / logging purposes
echo.
call :cecho 1 "------------- Build Configuration Settings -------------"
call :printField "Build Profile:     " "!radmake_profilename!"
call :printField "Repo:              " "!repo_uri!"
call :printField "Branch:            " "!radmake_branch!"
call :printField "Build type:        " "!radmake_buildtype!"
call :printField "Clean flag:        " "!radmake_cleanflag!"
call :printField "Repo folder:       " "!radmake_repofolder!"
call :printField "Build folder:      " "!radmake_outputfolder!"
call :printField "Install folder:    " "!radmake_installfolder!"
rem call :printField "asm_compiler:      " "!radmake_asmcompiler!"
call :printField "c_compiler:        " "!radmake_ccompiler!"
call :printField "cxx_compiler:      " "!radmake_cxxcompiler!"
echo.
call :printField "CMake Options:     " "!radmake_cmaketxt!"
call :printField "Patch Bat:         " "!radmake_patchbat!"
call :printField "PreBuild Bat:      " "!radmake_prebuildbat!"
call :printField "PostInstall Bat:   " "!radmake_postinstallbat!"
echo.
call :printField "rsvars64.bat:      " "!radmake_rsvarspath64!"
call :cecho 1 "-------------------------------------------------------"
echo.

rem -------------------------------------------------------------------------------------------------------------------
rem Clean requested components
for %%c in (source build install) do (
    echo !radmake_cleanflag! | findstr /i /c:"%%c" >nul
    if !errorlevel! == 0 (
        if "%%c"=="source" call :clean_directory "Repo local dir" "!radmake_repofolder!" || goto :END
        if "%%c"=="build" call :clean_directory "Output dir" "!radmake_outputfolder!"  || goto :END
        if "%%c"=="install" call :clean_directory "Install dir" "!radmake_installfolder!"  || goto :END
    )
)
echo.


rem -------------------------------------------------------------------------------------------------------------------
rem GIT pull/refresh repo
call :refresh_or_clone_repo || goto :END
echo.

rem -------------------------------------------------------------------------------------------------------------------
rem Optionally patch cloned source
if exist "%radmake_patchbat%" (
    echo.
    call :cecho 97 "Running PATCH script: !radmake_patchbat!"
    call "%radmake_patchbat%" %radmake_repofolder%  || goto :END
	echo.
)


rem -------------------------------------------------------------------------------------------------------------------
rem Provide default list of CMake options needed by C++ Builder
set "cmake_options=-DCMAKE_SYSTEM_NAME=Windows"
set "cmake_options=!cmake_options! -DCMAKE_SYSTEM_PROCESSOR=x86_64"
set "cmake_options=!cmake_options! -DCMAKE_CROSSCOMPILING=OFF"
set "cmake_options=!cmake_options! -DCMAKE_INSTALL_PREFIX=!radmake_installfolder:\=/%!"
set cmake_options=!cmake_options! -DCMAKE_ASM_COMPILER="!radmake_asmcompiler:\=/%!"
set cmake_options=!cmake_options! -DCMAKE_C_COMPILER="!radmake_ccompiler:\=/%!"
set cmake_options=!cmake_options! -DCMAKE_CXX_COMPILER="!radmake_cxxcompiler:\=/%!"


rem -------------------------------------------------------------------------------------------------------------------
rem Optionally, load custom CMake_options and append to standard CMake options
if exist "%radmake_cmaketxt%" (
  echo.  
  call :cecho 97 "Loading custom CMake options from !radmake_cmaketxt!"
  echo.
  for /f "usebackq tokens=* delims=" %%l in ("%radmake_cmaketxt%") do (
    set "line=%%l"
    rem Skip empty lines and lines starting with #
    if not "!line!"=="" if not "!line:~0,1!"=="#" (
      if defined cmake_custom_options (
        set "cmake_custom_options=!cmake_custom_options! !line!"
      ) else (
        set "cmake_custom_options=!line!"
	  )
    )
  )
)
set "cmake_options=!cmake_options! !cmake_custom_options!"

echo.
call :cecho 1 "--- CMake options ---"
echo !cmake_options!
echo.

rem -------------------------------------------------------------------------------------------------------------------
rem CMake configuration
if not exist "%radmake_outputfolder%\" mkdir "%radmake_outputfolder%" || goto :END
if not exist "%radmake_installfolder%\" mkdir "%radmake_installfolder%" || goto :END
call :cecho 1 "--- Create Build environment with CMake/Ninja ---"
if not "%radmake_cmakelistpathinrepo%"=="" (
    call :verboselog "NOTE: profile has custom CMakeLists.txt path: %radmake_cmakelistpathinrepo%"
)
CMake -G Ninja -S "%radmake_repofolder%%radmake_cmakelistpathinrepo%" -B "%radmake_outputfolder%" -Wno-dev --no-warn-unused-cli -DCMAKE_BUILD_TYPE=%radmake_buildtype% !cmake_options! || goto :END
echo.

rem -------------------------------------------------------------------------------------------------------------------
rem Optionally, allow for a prebuild action 
if exist "%radmake_prebuildbat%" (
    call :cecho 97 "Running PREBUILD script: !radmake_prebuildbat!" || goto :END
    call "%radmake_prebuildbat%" "%radmake_outputfolder%"
	echo.
)

rem -------------------------------------------------------------------------------------------------------------------
rem CMake build
call :cecho 1 "--- Start Build ---"
CMake --build "%radmake_outputfolder%" --config %radmake_buildtype% || goto :END
echo.

rem -------------------------------------------------------------------------------------------------------------------
rem CMake install
call :cecho 1 "--- Cmake Install Process ---"
CMake --install "%radmake_outputfolder%" --config %radmake_buildtype% || goto :END
echo.

rem -------------------------------------------------------------------------------------------------------------------
rem Optionally, allow for a postinstall action
if exist "%radmake_postinstallbat%" (
	call :cecho 97 "Running POSTINSTALL script: !radmake_postinstallbat!"
    call "%radmake_postinstallbat%" "%radmake_installfolder%" || goto :END
	echo.
)

:END
echo.
if !errorlevel! == 0 (
    call :cecho 92 "radmake [%radmake_profilename%] completed successfully."
    exit /b 0
) else (
    call :cecho 91 "radmake [%radmake_profilename%] failed"
    exit /b 1
)



rem -------------------------------------------------------------------------------------------------------------------
rem Function Definitions
rem -------------------------------------------------------------------------------------------------------------------


rem -------------------------------------------------------------------------------------------------------------------
:verboselog
if not "%radmake_log_level%"=="5" goto :eof
    echo [verbose] %*
rem )
goto :eof

:debuglog
if not "%radmake_log_level%"=="10" goto :eof
    echo [debug] %*
rem )
goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:highlightParam
rem Usage: call :highlightParam "{value}" 96
setlocal EnableDelayedExpansion
set "text=%~1"
set "color=%~2"

<nul set /p="!ESC![!color!m!text!!ESC![0m"
endlocal & goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:cecho
rem Usage: call :cecho 33 "Some yellow text"
setlocal
set "color=%~1"
set "text=%~2"
echo %ESC%[%color%m%text%%ESC%[0m
endlocal & goto :eof



rem -------------------------------------------------------------------------------------------------------------------
rem Help on argument failure
:PrintUsage
echo.
call :cecho 97 "Usage:"
echo   radmake.bat -p={profilename} [options that override build-profile]
echo.
call :cecho 97 "Required"
echo   --profile-name,    -p  Profile base name (e.g. ninja)
echo.
echo Required (if not specified by profile)
echo   --repo,            -r  GitHub path (e.g. ninja-build/ninja)
echo.
echo Optional, customize what to build:
echo   --branch,          -b  Branch to checkout (default: master)
echo   --build-type,      -t  Build type: Release, Debug, etc. (default: Release)
echo   --clean-flag,      -c  Clean directories before build. Values: build, install, source, all (default: none)
echo.
echo Optional, where to put files:
echo   --work-folder,     -w  Base target working folder (default: .\)
echo   --clone-to,        -d  Target folder to clone the repo (default: {work}\{name}-repo)
echo   --output-to,       -o  Target folder for CMake output (default: {work}\{name}-build)
echo   --install-to,      -i  Target folder for CMake install (default: {work}\{name}-install)
echo.
echo Optional, where to find customizations:
echo   --profile-folder,  -f  Base folder for radmake custom build files 
echo   --cmake_opts,      -m  List of custom CMake options to use (default: {profile}\radmake-{name}-cmake.txt)
echo   --patch-bat,       -a  Custom actions after repo, before CMake (default: {profile}\radmake-{name}-patch.bat)
echo   --prebuild-bat,    -e  Custom actions before CMake build (default: {profile}\radmake-{name}-prebuild.bat)
echo   --postinstall-bat, -l  Custom actions after CMake install (default: {profile}\radmake-{name}-postinstall.bat)
echo.
<nul set /p="Visit " 
call :highlightParam "https://github.com/radprogrammer/radmake/ " 96
<nul set /p=" for the latest version of radmake.bat"
echo.
exit /b 1



rem -------------------------------------------------------------------------------------------------------------------
:printField
setlocal EnableDelayedExpansion
set "label=%~1"
set "value=%~2"

<nul set /p="!ESC![96m!label! !ESC![0m"
if defined value (
    echo !value!
) else (
    echo.
)
endlocal & goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:missingParam
  call :cecho 91 "Missing required parameter: %1"
  call :PrintUsage
  endlocal
  exit /b 1
endlocal & goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:clean_directory
setlocal EnableDelayedExpansion
set "dir_name=%~1"
set "dir_path=%~2"

if exist "!dir_path!" (
    call :cecho 93 "Cleaning %dir_name%: !dir_path!"
     rd /s /q "!dir_path!" 2>nul
    if exist "!dir_path!" (
        call :cecho 91 "ERROR: Could not clean %dir_name% at !dir_path!"
        endlocal & exit /b 1
    )
) else (
    echo No need to clean %dir_name% {not found}
)
endlocal & exit /b 0



rem -------------------------------------------------------------------------------------------------------------------
rem Find bin64\rsvars64.bat for RAD Studio 12+
:find_latest_rsvars
setlocal enabledelayedexpansion

set "HKLM_BASE=HKLM\SOFTWARE\Embarcadero\BDS"
set "HKLM_WOW64=HKLM\SOFTWARE\WOW6432Node\Embarcadero\BDS"

set "RAD_VERS=23.0 24.0 25.0 26.0"

set "latest_ver="
set "latest_path="

for %%V in (%RAD_VERS%) do (
    for %%R in ("%HKLM_BASE%" "%HKLM_WOW64%") do (
        for /f "tokens=1,2,*" %%A in ('reg query %%~R\%%~V /v RootDir 2^>nul ^| findstr /R /C:"RootDir"') do (
            set "install_dir=%%C"
            rem no support for 32-bit  "bin\rsvars.bat" radmake_rsvarspath32
            call :pathcombine "!install_dir!" "bin64\rsvars64.bat" radmake_rsvarspath64
            if exist "!radmake_rsvarspath64!" (
                rem echo Found version %%~V at !radmake_rsvarspath64!
                set "latest_ver=%%~V"
                set "latest_path=!radmake_rsvarspath64!"
            )
        )
    )
)

endlocal & (
    set "radmake_rsvarspath64=%latest_path%"
)
goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:check_required_tools
setlocal

set apps=CMake ninja %~1
set "app_not_found="

for %%a in (%apps%) do (
    where %%a >nul 2>nul
    if ERRORLEVEL 1 (
        call :cecho 91 "[ERROR] %%a is not available in PATH."
        set "app_not_found=true"
        endlocal
        exit /b 1
    )
)

rem Export required variables to parent scope
endlocal & (
    set "cc="
    set "cflags="
    set "cxx="
    set "cxxflags="
    set "rc="
    set "rcflags="
    set "pythonpath="
    set "pythonhome="
)
goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:pathcombine
setlocal EnableDelayedExpansion
set "base=%~1"
set "file=%~2"
set "outvar=%~3"

rem Handle empty inputs
if not defined base (
    set "!outvar!=!file!"
    goto :eof
)
if not defined file (
    set "!outvar!=!base!"
    goto :eof
)

rem Normalize slashes to backslashes
set "base=!base:/=\!"
set "file=!file:/=\!"

rem Ensure base ends in backslash (except for root drives like C:\)
if not "!base:~-1!"=="\" (
    set "base=!base!\"
)

rem Remove leading backslash from file to avoid double-backslash

if "!file:~0,1!"=="\" (
    set "file=!file:~1!"
)

endlocal & set "%outvar%=%base%%file%"
goto :eof



rem -------------------------------------------------------------------------------------------------------------------
:refresh_or_clone_repo
rem Refreshes or clones the repository into !radmake_repofolder!

if exist "!radmake_repofolder!\\.git" (
    call :debuglog "Repo exists: !radmake_repofolder!"
    pushd "!radmake_repofolder!"
    call :cecho 0 "Fetching latest changes..."

    call :debuglog "Clean submodules BEFORE fetching, in case old references are broken"
    git submodule deinit --all -f >nul 2>&1
    rd /s /q .git\modules >nul 2>&1

    git fetch origin --quiet || (popd & goto :GIT_FAIL)
    rem added --force to grab re-released tags
    git fetch --tags --force --quiet || (popd & goto :GIT_FAIL)

    rem Check if it's a branch
    git rev-parse --verify origin/!radmake_branch! >nul 2>&1
    if not errorlevel 1 (
        call :cecho 0 "Resetting to branch: !radmake_branch!"
        git checkout "!radmake_branch!" || (popd & goto :GIT_FAIL)
        git reset --hard origin/!radmake_branch! || (popd & goto :GIT_FAIL)
        popd
        goto :GIT_DONE
    )

    rem Check if it's a tag
    git rev-parse --verify "refs/tags/!radmake_branch!" >nul 2>&1
    if not errorlevel 1 (
        call :cecho 0 "Checking out tag: !radmake_branch!"
        git checkout "tags/!radmake_branch!" --detach || (popd & goto :GIT_FAIL)
        popd
        goto :GIT_DONE
    )

    call :cecho 91 "ERROR: Branch or tag not found in local repo: !radmake_branch!"
    popd
    goto :GIT_FAIL
)

rem Else: repo doesn't exist, clone it
call :cecho 96 "[radmake] Cloning repository..."

set "is_remote_branch="
set "is_remote_tag="

for /f %%R in ('git ls-remote --heads "%repo_uri%" "refs/heads/%radmake_branch%"') do (
    set "is_remote_branch=1"
)

for /f %%T in ('git ls-remote --tags "%repo_uri%" "refs/tags/%radmake_branch%"') do (
    set "is_remote_tag=1"
)

if defined is_remote_branch (
    call :cecho 93 "Detected remote branch: %radmake_branch%"
    git clone --depth 1 --branch "%radmake_branch%" --single-branch "%repo_uri%" "%radmake_repofolder%" || goto :GIT_FAIL
    goto :GIT_DONE
) else if defined is_remote_tag (
    call :cecho 93 "Detected remote tag: %radmake_branch%"
    rem workaround for shallow-cloning tag
    git init "%radmake_repofolder%" || goto :GIT_FAIL
    pushd "%radmake_repofolder%"
    git remote add origin "%repo_uri%" || (popd & goto :GIT_FAIL)
    git fetch --depth=1 origin "refs/tags/%radmake_branch%" || (popd & goto :GIT_FAIL)
    git checkout FETCH_HEAD --detach || (popd & goto :GIT_FAIL)
    popd
    goto :GIT_DONE
)

call :cecho 91 "ERROR: Branch or tag not found on remote: %radmake_branch%"
goto :GIT_FAIL


:GIT_DONE
rem failsafe / credential failure perhaps
if not exist "!radmake_repofolder!\\.git" (
    call :cecho 91 "ERROR: Clone failed. Check your credentials or repo visibility."
    goto :GIT_FAIL
)

call :gitsubmodules "%radmake_repofolder%"
 
call :cecho 92 "Git operations succeeded"
exit /b 0

:GIT_FAIL
call :cecho 91 "Git failure for %repo_uri% (%radmake_branch%)"
exit /b 1



rem -------------------------------------------------------------------------------------------------------------------
:trim
rem Usage: call :trim inputVar outputVar
rem Trims leading/trailing whitespace (spaces and tabs) from %inputVar% into %outputVar%

setlocal EnableDelayedExpansion
set "in=%~1"
set "out=%~2"
set "val=!%in%!"

rem === Trim leading whitespace (spaces & tabs) ===
:trim_leading
if "!val:~0,1!"==" " set "val=!val:~1!" & goto trim_leading
if "!val:~0,1!"=="	" set "val=!val:~1!" & goto trim_leading

rem === Trim trailing whitespace (spaces & tabs) ===
:trim_trailing
if "!val:~-1!"==" " set "val=!val:~0,-1!" & goto trim_trailing
if "!val:~-1!"=="	" set "val=!val:~0,-1!" & goto trim_trailing

( endlocal
  set "%out%=%val%"
)
exit /b 0



rem -------------------------------------------------------------------------------------------------------------------
:parse_profile_ini
rem Usage: call :parse_profile_ini path_to_ini
set "iniFile=%~1"

if not exist "%iniFile%" (
    echo Missing build profile: %iniFile%
    endlocal & exit /b 0
)

call :cecho 97 "Reading build profile: %iniFile%"

for /f "usebackq tokens=* delims=" %%a in ("%iniFile%") do (
    set "line=%%a"
    rem drop BOM
    if "!line:~0,1!"=="ï»¿" set "line=!line:~1!"
    set "line=!line!"

    rem Trim leading whitespace
    for /f "tokens=* delims= " %%b in ("!line!") do set "line=%%b"

    rem Detect section headers
    if /i "!line!"=="[build-profile]" (
        set "inSection=1"
    ) else if "!line:~0,1!"=="[" (
        set "inSection="
    ) else if defined inSection (
        if not "!line!"=="" if not "!line:~0,1!"==";" (

            for /f "tokens=1,* delims==" %%k in ("!line!") do (
                set "key=%%k"
                set "value=%%l"
                set "key=!key: =!"
                
                call :trim value value

                rem Probe for known key 
                set "keyexists="
                for /f "delims==" %%V in ('set !key! 2^>nul') do (
                    set "keyexists=1"
                )
                call :debuglog line="%%a"
                call :debuglog key="!key!" value="!value!" keyexists="!keyexists!"

                if not "!key!"=="" (
                    if not "!value!"=="" (
                        if defined keyexists (
                            call :cecho 33 "[SET] !key!=!value!"
                            rem call set "!key!=%%value%%"
                            call set "!key!=!value!"
                        ) else (
                            call :cecho 93 "[SKIP] Unknown key: !key!"
                        )
                    ) else (
                        if defined keyexists (
                            call :verboselog "[SKIP] Known key with empty value: !key!"
                        ) else (
                            call :verboselog "[SKIP] Unknown key with empty value: !key!"
                        )
                    )
                ) else (
                    call :cecho 93 "[SKIP] Empty key name in INI line"
                )
            )
        )
    )
)
endlocal & exit /b 0



rem -------------------------------------------------------------------------------------------------------------------
:gitsubmodules
rem First argument is the repo folder name
setlocal
set "REPO=%~1"
call :debuglog "Git submodule handling started for %REPO%"

if not exist "%REPO%" (
    call :cecho 91 "ERROR: Repo folder not found: %REPO%"
    exit /b 1
)

if not exist "%REPO%\.gitmodules" (
    call :debuglog "No submodules defined in %REPO%"
    goto :eof
)

pushd "%REPO%" || (
    call :cecho 91 "ERROR: Failed to change directory to %REPO%"
    exit /b 1
)

call :cecho 93 "Initializing git submodules..."
git submodule init
if errorlevel 1 (
    call :cecho 91 "ERROR: git submodule init failed."
    popd
    exit /b 1
)

call :verboselog Updating git submodules
git submodule update --recursive
if errorlevel 1 (
    call :cecho 91 "ERROR: git submodule update failed."
    popd
    exit /b 1
)

popd
call :cecho 93 "Submodules initialized successfully."
echo.
endlocal & exit /b 0
