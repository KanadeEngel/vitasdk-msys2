Prerequisites
=============
1. Get latest msys2 from https://sourceforge.net/projects/msys2 and install it somewhere.
2. Run 'pacman -Syu' and follow instruction to restart msys2 shell, run it again to update everything to latest.
3. Run 'pacman -S --needed base git make texinfo bison flex tar gzip bzip2 xz patch diffutils mingw-w64-i686-toolchain mingw-w64-i686-cmake' to install required packages for VitaSDK building.
4. (Optional) For building 3rd party libs like vita_portlibs, vita libs for EasyRPG and etc, you had better install other packages: autoconf, automake, pkgconfig, libtool

Build
=====
1. Start msys2 shell by executing "mingw32.exe"
2. Run ./build-mingw.sh to build everything, if you need to do a particular step build, just use ./build-mingw.sh --help to see which steps are supported.
