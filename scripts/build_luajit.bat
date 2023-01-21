@echo off
setlocal

@REM Heads up. Building LuaJIT for the RIO is touchy and you need to make sure things
@REM are in order.

@REM Make sure you have a version of Mingw on your system that actually includes
@REM 32-bit libraries. The default from Chocolatey does not. I used the
@REM MingW-Win64-builds downloads from the link below, and installed version 8.1.0
@REM for x86-64 with win32 threads and SJLJ exceptions.

@REM http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download

@REM You may need to actually remove your existing at C:\msys64\mingw64 and replace
@REM it with the new one you installed to get things to work.

@REM Then make sure that you have Visual Studio 2019 installed on your C drive. This
@REM script will run vcvarsall in order to properly use MSVC.

@REM You then may also need to modify the src/Makefile in LuaJIT to remove
@REM `2>/dev/null` from `TARGET_AR`. I believe that due to a bug in the target and
@REM host detection - it should never be applied when the host is Windows, but it
@REM is. I found this thanks to Demetri Spanos pointing me to this bug and the
@REM corresponding fix commit (which did not fix it):

@REM https://github.com/LuaJIT/LuaJIT/issues/336
@REM https://github.com/LuaJIT/LuaJIT/commit/82151a4514e6538086f3f5e01cb8d4b22287b14f

@REM Removing `2>/dev/null` is not portable but it does work for this specific case,
@REM and I think it just shuts up a warning.

@REM You should probably run `./gradlew installRoboRIOToolchain -Ptoolchain-install-force`
@REM at the start of every new season.

set LUAJIT_PATH=lib\LuaJIT-2.1
set YEAR=2022
set PATH=%PATH%;%USERPROFILE%\.gradle\toolchains\frc\%YEAR%\roborio\bin

set ATHENA_MAKE=frc%YEAR%-make
set ATHENA_FLAGS=HOST_CC="gcc -m32" CROSS=arm-frc%YEAR%-linux-gnueabi- TARGET_CFLAGS="-mcpu=cortex-a9 -mfloat-abi=softfp" TARGET_SYS="Linux"

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

pushd %LUAJIT_PATH%
    pushd src
        rmdir /Q /S dist
        mkdir dist
        mkdir dist\include
        copy *.h dist\include
        copy *.hpp dist\include
    popd

    @REM Windows build
    pushd src
        call msvcbuild.bat
        copy *.lib dist
        copy *.dll dist
    popd
    
    @REM roboRIO build
    %ATHENA_MAKE% clean %ATHENA_FLAGS%
    %ATHENA_MAKE% %ATHENA_FLAGS%
    pushd src
        copy *.a dist
        copy *.so dist
    popd
popd

xcopy %LUAJIT_PATH%\src\dist\ lib\lib /q /e /y

endlocal
