@echo off
setlocal enabledelayedexpansion

:: ----------------------------------------------------------------------------
:: Usage: radmake-template.bat <project-name>
:: ----------------------------------------------------------------------------
if "%~1"=="" (
    echo Usage: %~nx0 ^<project-name^>
    exit /b 1
)

set "name=%~1"
set /p "repo_path=GitHub repo path (e.g. https://github.com/ninja-build/ninja): "
if "%repo_path%"=="" (
    echo Repo path is required.
    exit /b 1
)

set /p "branch=Default branch (default = master): "
if "%branch%"=="" set "branch=master"

set /p "build_type=Build type (default = Release): "
if "%build_type%"=="" set "build_type=Release"

set /p "clean_flag=Clean flag (default = none. Can be source+build+install+all+none): "
if "%clean_flag%"=="" set "clean_flag=none"

set /p "work_folder=Work folder (default = work): "
if "%work_folder%"=="" set "work_folder=work"

set "pwd=%~dp0"
mkdir %pwd%\build-profiles\%name%\

rem + now
set "profile_file=%pwd%build-profiles\%name%\radmake-%name%-profile.ini"
set "opts_file=%pwd%build-profiles\%name%\radmake-%name%-cmake.txt"
set "patch_file=%pwd%build-profiles\%name%\radmake-%name%-patch.bat"
set "prebuild_file=%pwd%build-profiles\%name%\radmake-%name%-prebuild.bat"
set "postinstall_file=%pwd%build-profiles\%name%\radmake-%name%-postinstall.bat"

:: ----------------------------------------------------------------------------
:: Create .ini file
if not exist "%profile_file%" (
    echo Creating %profile_file%
    > "%profile_file%" (
        echo [build-profile]
        echo radmake_configversion=1.0
        echo radmake_reponame=%repo_path%
        echo radmake_branch=%branch%
        echo radmake_buildtype=%build_type%
        echo radmake_cleanflag=%clean_flag%
        echo radmake_workfolder=%work_folder%
        echo radmake_repofolder=
        echo radmake_outputfolder=
        echo radmake_installfolder=
        echo radmake_cmaketxt=
        echo radmake_patchbat=
        echo radmake_postinstallbat=
        echo radmake_prebuildbat=
        echo radmake_asmcompiler=
        echo radmake_ccompiler=
        echo radmake_cxxcompiler=
        echo radmake_rsvarspath64=
        echo 
        echo ;For radmake_reponame=xxx, provide the full repository uri such as https://github.com/ninja-build/ninja.git
        echo 
        echo ;Default values {as of version 1.0}
        echo ;radmake_branch=master
        echo ;radmake_buildtype=Release
        echo ;radmake_cleanflag=none
        echo ;radmake_workfolder=.\work
        echo ;radmake_repofolder={radmake_workfolder}\{profilename}-repo
        echo ;radmake_cmakelistpathinrepo=
        echo ;radmake_outputfolder={radmake_workfolder}\{profilename}-build
        echo ;radmake_installfolder={radmake_workfolder}\{profilename}-install
        echo ;radmake_cmaketxt={radmake_profilefolder}\radmake-{profilename}-cmake.txt
        echo ;radmake_patchbat={radmake_profilefolder}\radmake-{profilename}-patch.bat
        echo ;radmake_postinstallbat={radmake_profilefolder}\radmake-{profilename}-postinstall.bat
        echo ;radmake_prebuildbat={radmake_profilefolder}\radmake-{profilename}-prebuild.bat
        echo ;radmake_cxxcompiler={BDS}\bin64\bcc64x.exe
        echo ;radmake_rsvarspath64={registry lookup}
        echo 
        echo ;Note the repo is shallow-cloned and currently hard-reset
    )
) else (
    echo %profile_file% already exists.
)

:: ----------------------------------------------------------------------------
:: Create .opts file
if not exist "%opts_file%" (
    echo Creating %opts_file%
    > "%opts_file%" (
        echo # Customize the radmake.bat build process by applying custom CMake options
        echo #
        echo # These options are always included:
        echo #
        echo #-DCMAKE_SYSTEM_NAME=Windows
        echo #-DCMAKE_SYSTEM_PROCESSOR=x86_64
        echo #-DCMAKE_CROSSCOMPILING=OFF
        echo #-DCMAKE_INSTALL_PREFIX=install_folder
        echo #-DCMAKE_ASM_COMPILER=asm_compiler
        echo #-DCMAKE_C_COMPILER=c_compiler
        echo #-DCMAKE_CXX_COMPILER=cxx_compiler
        echo #
        echo # Note that comment lines starting with # are ignored
        echo # Add your additional CMake options here, one per line:    
    )
) else (
    echo %opts_file% already exists.
)

:: ----------------------------------------------------------------------------
:: Create patch.bat
if not exist "%patch_file%" (
    echo Creating %patch_file%
    > "%patch_file%" (
        @echo off
        echo :: Customize the radmake.bat build process by running a batch file after the git operations are done
        echo ::
        echo :: Param #1 is the repository foldername
        echo ::
        echo :: This is an available seam for doing things after the repository is downloaded but before CMake configuration
        echo :: Such as:
        echo ::   Apply custom patches/diffs
        echo ::   Delete temp files that might cause problems with build
        echo ::   Modify file permissions
        echo ::   Initialize submodules
        echo ::   Patch CMake files
        echo ::
        echo :: Add your custom patching logic here:
    )
) else (
    echo %patch_file% already exists.
)

:: ----------------------------------------------------------------------------
:: Create prebuild.bat
if not exist "%prebuild_file%" (
    echo Creating %prebuild_file%
    > "%prebuild_file%" (
        @echo off
        echo :: Customize the radmake.bat build process by preparing files for a build
        echo ::
        echo :: Param #1 is the CMake Output foldername
        echo ::
        echo :: This is an available seam for doing things after CMake configuration, but before compiling.
        echo :: Such as:
        echo ::   Code gen
        echo ::   Version stamping / metadata 
        echo ::   File sync / patching
        echo ::   Build-time validation
        echo ::   Download/update dependencies
        echo ::   Inject CMakeLists.txt overrides manually
        echo ::   Touch files to trigger rebuilds
        echo ::
        echo :: Add your custom compile prep logic here:
    )
) else (
    echo %prebuild_file% already exists.
)

:: ----------------------------------------------------------------------------
:: Create postinstall.bat
if not exist "%postinstall_file%" (
    echo Creating %postinstall_file%
    > "%postinstall_file%" (
        @echo off
        echo :: Customize the radmake.bat build process by deploying binaries
        echo ::
        echo :: Param #1 is the Install foldername
        echo ::
        echo :: This is an available seam for doing things after CMake Install has completed
        echo :: Such as:
        echo ::   Generate manifest/filelist
        echo ::   Package/sign the output
        echo ::   Sanity-check the Install
        echo ::   Copy to global/sdk folder
        echo ::
        echo :: example: copying application just built to a Tools directory...
        echo :: md "%~dp0tools\"
        echo :: copy /y "%~1\bin\ninja.exe" "%~dp0tools\ninja.exe"
        echo ::
        echo :: Add your custom post-build deployment logic here:
    )
) else (
    echo %postinstall_file% already exists.
)

echo.
echo Setup complete for project: %name%
