![radmake-graphic](./bin/radmake-graphic-125x125.png)
# radmake

## Ready to use build profiles using CMake/Ninja for C++ Builder 12.2 and later

RAD Studio 12.2 has new CMake support for the Windows 64-bit Modern toolchain!  This collection of build profiles simplifies building binaries for use with C++ Builder.


- `10/07/2024` Blog: [Introducing Amazing CMake Support in C++Builder 12.2](https://blogs.embarcadero.com/introducing-amazing-cmake-support-in-cbuilder-12-2/)
- `11/26/2024` Blog: [Practical Info: Using CMake with C++Builder 12.2](https://blogs.embarcadero.com/practical-info-using-cmake-with-cbuilder-12-2/)
- docwiki help: [Using CMake with C++ Builder](https://docwiki.embarcadero.com/RADStudio/en/Using_CMake_with_C%2B%2B_Builder)
- Embarcadero add sample builds into their demo repo: [RADStudio12Demos](https://github.com/Embarcadero/RADStudio12Demos)  (look in `CPP\CMake`) 

- Ninja links:
  - [Download Ninja](https://ninja-build.org/)
  - [Ninja Repo](https://github.com/ninja-build/ninja)
  
 Notes:
 - Ensure you have RAD Studio 12.2 _with both patches_, or use  latest version of RAD Studio (currently 12.3)
 - Download and install CMake via GetIt.  Ensure this is within the system PATH. 
 - Note the GetIt version of CMake.exe is a custom build from Embarcadero as they have made some revisions and are waiting for those to get merged into the main repo.
 - Download ninja.exe and ensure it is also in the system PATH (simply save in the CMake folder.)
---
## Usage


| Action | radmake command line  |
|---|---|
| EZ-mode | `radmake {build-profile-name}` |
| View help | `radmake --help` |
| Custom Build | `radmake -p=ninja -b=v1.12.1 -t=Debug -w="C:\build" --clean-flag=all` |


---

## Current List of Build-Profiles
| Profile Name | Branch | Description  | Stars |
|---|---|---|---|
| [curl](https://github.com/curl/curl) | `curl-8_13_0` | A command line tool and library for transferring data | 37.4k |
| [spdlog](https://github.com/gabime/spdlog) | `v1.15.2` | Fast C++ logging library | 25.8k |
| [zstd](https://github.com/facebook/zstd) | `v1.5.7` | Fast real-time compression algorithm | 24.7k |
| [flatbuffers](https://github.com/google/flatbuffers) | `v25.2.10` | Google: Memory Efficient Serialization Library | 24k |
| [fmt](https://github.com/fmtlib/fmt) | `11.1.4` | A modern formatting library | 21.6k |
| [simdjson](https://github.com/simdjson/simdjson) | `v3.12.3` | Parsing gigabytes of JSON per second | 20k |
| [brotli](https://github.com/google/brotli) | `v1.1.0` | Google: Brotli compression format | 14k |
| [ninja](https://github.com/ninja-build/ninja) | `master` | A small build system with a focus on speed | 11.8k |
| [lz4](https://github.com/lz4/lz4) | `v1.10.0` | Extremely Fast Compression algorithm | 10.8k |
| [jsoncpp](https://github.com/open-source-parsers/jsoncpp) | `1.9.6` | A C++ library for interacting with JSON | 8.5k |
| [zlib](hhttps://github.com/madler/zlib) | `v1.3.1` | A massively spiffy yet delicately unobtrusive compression library | 6.1k |
| [cnl](https://github.com/johnmcfarlane/cnl) | `v1.1.2` | A Compositional Numeric Library for C++ | 649 |



---

## Build-Profile Customizations Available

`radmake` looks for five _optional_ files within the `build-profiles\{profile}` folder for customizing the build process

| File | Branch |
|---|---|
| radmake-`{profile}`-profile.ini | Default settings - can be overriden by command line parameters |
| radmake-`{profile}`-cmake.txt | Addition CMake settings file. (Add one line per setting) |
| radmake-`{profile}`-patch.bat | Runs after repo refreshed, before CMake for customizing code as needed |
| radmake-`{profile}`-prebuild.bat | Runs after CMake config but before build |
| radmake-`{profile}`-postinstall.bat | Runs after CMake install completes |


### Build Profile defaults
````
Default values {as of radmake version 0.1}
radmake_branch=master
radmake_buildtype=Release
radmake_cleanflag=none
radmake_workfolder=.\work
radmake_repofolder={radmake_workfolder}\{profilename}-repo
radmake_outputfolder={radmake_workfolder}\{profilename}-build
radmake_installfolder={radmake_workfolder}\{profilename}-install
radmake_cmaketxt={radmake_profilefolder}\radmake-{profilename}-cmake.txt
radmake_patchbat={radmake_profilefolder}\radmake-{profilename}-patch.bat
radmake_postinstallbat={radmake_profilefolder}\radmake-{profilename}-postinstall.bat
radmake_prebuildbat={radmake_profilefolder}\radmake-{profilename}-prebuild.bat
radmake_cxxcompiler={BDS}\bin64\bcc64x.exe
radmake_rsvarspath64={registry lookup}
````

### CMake defaults for every project
````
-DCMAKE_SYSTEM_NAME=Windows"
-DCMAKE_SYSTEM_PROCESSOR=x86_64"
-DCMAKE_CROSSCOMPILING=OFF"
-DCMAKE_INSTALL_PREFIX={radmake_installfolder}
-DCMAKE_C_COMPILER=%BDS%\bin64\bcc64x.exe
-DCMAKE_CXX_COMPILER=%BDS%\bin64\bcc64x.exe
````
Note: The path to rsvars64.bat is automatically located in the registry and rsvars64.bat is executed to set the required environment variables for RAD Studio


