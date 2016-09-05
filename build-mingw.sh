#/usr/bin/env sh

if [ $# -gt 0 ]; then
  while test $# -gt 0
  do
    case "$1" in
      --help) (echo "Supported steps: zlib libzip libelf jansson toolchain dlfcn binutils gcc newlib gcc-final headers strip"; exit 1)
        ;;
      zlib) STEP0=true
        ;;
      libzip) STEP1=true
        ;;
      libelf) STEP2=true
        ;;
      jansson) STEP3=true
        ;;
      toolchain) STEP4=true
        ;;
      dlfcn) STEP5=true
        ;;
      binutils) STEP6=true
        ;;
      gcc) STEP7=true
        ;;
      newlib) STEP8=true
        ;;
      gcc-final) STEP9=true
        ;;
      headers) STEP10=true
        ;;
      strip) STEP11=true
        ;;
      *) (echo "Unsupported $1"; exit 1)
        ;;
    esac
    shift
  done
else
  STEP0=true
  STEP1=true
  STEP2=true
  STEP3=true
  STEP4=true
  STEP5=true
  STEP6=true
  STEP7=true
  STEP8=true
  STEP9=true
  STEP10=true
  STEP11=true
fi

. ./build-common.sh

set -e
set -o pipefail

mkdir -p ${DOWNLOADDIR} ${SRCDIR} ${BUILDDIR} ${INSTALLDIR}

if [ ${STEP0} ]; then
  echo "[Step 0] Build zlib..."
  cd ${DOWNLOADDIR}
  if [ ! -f zlib-${ZLIB_VERSION}.tar.xz ]; then
    curl -L -O http://zlib.net/zlib-${ZLIB_VERSION}.tar.xz
  fi
  tar xJf zlib-${ZLIB_VERSION}.tar.xz -C ${SRCDIR}
  cd ${SRCDIR}/zlib-${ZLIB_VERSION}
  BINARY_PATH=${INSTALLDIR}/bin INCLUDE_PATH=${INSTALLDIR}/include LIBRARY_PATH=${INSTALLDIR}/lib make -f win32/Makefile.gcc ${JOBS} install || exit 1
fi

if [ ${STEP1} ]; then
  echo "[Step 1] Build libzip..."
  cd ${DOWNLOADDIR}
  if [ ! -f libzip-${LIBZIP_VERSION}.tar.xz ]; then
    curl -L -O https://nih.at/libzip/libzip-${LIBZIP_VERSION}.tar.xz
  fi
  tar xJf libzip-${LIBZIP_VERSION}.tar.xz -C ${SRCDIR}
  rm -rf ${BUILDDIR}/libzip-${LIBZIP_VERSION}
  mkdir -p ${BUILDDIR}/libzip-${LIBZIP_VERSION}
  cd ${BUILDDIR}/libzip-${LIBZIP_VERSION}
  CFLAGS='-DZIP_STATIC' ${SRCDIR}/libzip-${LIBZIP_VERSION}/configure --host=i686-w64-mingw32 --prefix=$INSTALLDIR --disable-shared --enable-static
  make ${JOBS} -C lib install || exit 1
fi

if [ ${STEP2} ]; then
  echo "[Step 2] Build libelf..."
  cd ${DOWNLOADDIR}
  if [ ! -f libelf-${LIBELF_VERSION}.tar.gz ]; then
    curl -L -O http://www.mr511.de/software/libelf-${LIBELF_VERSION}.tar.gz
  fi
  tar xzf libelf-${LIBELF_VERSION}.tar.gz -C ${SRCDIR}
  cd ${SRCDIR}/libelf-${LIBELF_VERSION}
  patch -p3 < ${PATCHDIR}/libelf.patch
  rm -rf ${BUILDDIR}/libelf-${LIBELF_VERSION}
  mkdir -p ${BUILDDIR}/libelf-${LIBELF_VERSION}
  cd ${BUILDDIR}/libelf-${LIBELF_VERSION}
  ../${SRCRELDIR}/libelf-${LIBELF_VERSION}/configure --host=i686-w64-mingw32 --prefix=$INSTALLDIR
  make ${JOBS} install || exit 1
fi

if [ ${STEP3} ]; then
  echo "[Step 3] Build jansson..."
  cd ${DOWNLOADDIR}
  if [ ! -f jansson-${JANSSON_VERSION}.tar.gz ]; then
    curl -L -o jansson-${JANSSON_VERSION}.tar.gz https://github.com/akheron/jansson/archive/v${JANSSON_VERSION}.tar.gz
  fi
  tar xzf jansson-${JANSSON_VERSION}.tar.gz -C ${SRCDIR}
  rm -rf ${BUILDDIR}/jansson-${JANSSON_VERSION}
  mkdir -p ${BUILDDIR}/jansson-${JANSSON_VERSION}
  cd ${BUILDDIR}/jansson-${JANSSON_VERSION}
  cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$INSTALLDIR -DCMAKE_BUILD_TYPE=Release -DJANSSON_BUILD_DOCS=OFF ${SRCDIR}/jansson-${JANSSON_VERSION}
  make ${JOBS} install || exit 1
fi

if [ ${STEP4} ]; then
  echo "[Step 4] Build vita-toolchain..."
  if [ ! -d ${SRCDIR}/vita-toolchain/.git ]; then
    rm -rf ${SRCDIR}/vita-toolchain
    git clone https://github.com/vitasdk/vita-toolchain ${SRCDIR}/vita-toolchain
  else
    cd ${SRCDIR}/vita-toolchain
    git pull origin master
  fi
  rm -rf ${BUILDDIR}/vita-toolchain
  mkdir -p ${BUILDDIR}/vita-toolchain
  cd ${BUILDDIR}/vita-toolchain
  cmake -G"Unix Makefiles" -DCMAKE_C_FLAGS_RELEASE:STRING="-O3 -DNDEBUG -DZIP_STATIC" -DCMAKE_BUILD_TYPE=Release -DJansson_INCLUDE_DIR=$INSTALLDIR/include/ -DJansson_LIBRARY=$INSTALLDIR/lib/libjansson.a -Dlibelf_INCLUDE_DIR=$INSTALLDIR/include -Dlibelf_LIBRARY=$INSTALLDIR/lib/libelf.a -Dzlib_INCLUDE_DIR=$INSTALLDIR/include/ -Dzlib_LIBRARY=$INSTALLDIR/lib/libz.a -Dlibzip_INCLUDE_DIR=$INSTALLDIR/include/ -Dlibzip_CONFIG_INCLUDE_DIR=$INSTALLDIR/lib/libzip/include -Dlibzip_LIBRARY=$INSTALLDIR/lib/libzip.a -DCMAKE_INSTALL_PREFIX=${VITASDKROOT} -DDEFAULT_JSON=../share/db.json ${SRCDIR}/vita-toolchain
  make ${JOBS} install || exit 1
fi

if [ ${STEP5} ]; then
  echo "[Step 5] Build dlfcn-win32..."
  cd ${DOWNLOADDIR}
  if [ ! -f dlfcn-${DLFCN_VERSION}.tar.gz ]; then
    curl -L -o dlfcn-${DLFCN_VERSION}.tar.gz https://github.com/dlfcn-win32/dlfcn-win32/archive/v${DLFCN_VERSION}.tar.gz
  fi
  tar xzf dlfcn-${DLFCN_VERSION}.tar.gz -C ${SRCDIR}
  cd ${SRCDIR}/dlfcn-win32-${DLFCN_VERSION}
  ./configure --prefix=$INSTALLDIR
  make && make install || exit 1
fi

if [ ${STEP6} ]; then
  echo "[Step 6] Build binutils..."
  cd ${DOWNLOADDIR}
  if [ ! -f binutils-${BINUTILS_VERSION}.tar.bz2 ]; then
    curl -L -O http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2
  fi
  tar xjf binutils-${BINUTILS_VERSION}.tar.bz2 -C ${SRCDIR}
  cd ${SRCDIR}/binutils-${BINUTILS_VERSION}
  patch -p3 < ${PATCHDIR}/binutils.patch
  rm -rf ${BUILDDIR}/binutils-${BINUTILS_VERSION}
  mkdir -p ${BUILDDIR}/binutils-${BINUTILS_VERSION}
  cd ${BUILDDIR}/binutils-${BINUTILS_VERSION}
  ../${SRCRELDIR}/binutils-${BINUTILS_VERSION}/configure --host=i686-w64-mingw32 --build=i686-w64-mingw32 --target=arm-vita-eabi --prefix=${VITASDKROOT} --infodir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/info --mandir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/man --htmldir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/html --pdfdir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/pdf --disable-nls --disable-werror --enable-interwork --enable-plugins --with-sysroot=${VITASDKROOT}/arm-vita-eabi "--with-pkgversion=GNU Tools for ARM Embedded Processors [VitaSDK for MSYS2 by Soar Qin]"
  make ${JOBS} && make install || exit 1
fi

export OLDPATH=${PATH}
export PATH=${VITASDKROOT}/bin:${PATH}

if [ ${STEP7} ]; then
  echo "[Step 7] Build gcc first time..."
  cd ${DOWNLOADDIR}
  if [ ! -f gcc-${GCC_VERSION}.tar.bz2 ]; then
    curl -L -O http://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
  fi
  tar xjf gcc-${GCC_VERSION}.tar.bz2 -C ${SRCDIR}
  if [ ! -d ${SRCDIR}/gcc-${GCC_VERSION}/isl ]; then
    cd ${SRCDIR}/gcc-${GCC_VERSION}
    ./contrib/download_prerequisites
  fi
  patch -p3 < ${PATCHDIR}/gcc.patch
  patch -p1 < ${PATCHDIR}/gcc-mingw.patch
  rm -rf ${BUILDDIR}/gcc-${GCC_VERSION}
  mkdir -p ${BUILDDIR}/gcc-${GCC_VERSION}
  cd ${BUILDDIR}/gcc-${GCC_VERSION}
  ../${SRCRELDIR}/gcc-${GCC_VERSION}/configure --host=i686-w64-mingw32 --build=i686-w64-mingw32 --target=arm-vita-eabi --prefix=${VITASDKROOT} --libexecdir=${VITASDKROOT}/lib --infodir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/info --mandir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/man --htmldir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/html --pdfdir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/pdf --enable-languages=c --disable-decimal-float --disable-libffi --disable-libgomp --disable-libmudflap --disable-libquadmath --disable-libssp --disable-libstdcxx-pch --disable-nls --disable-shared --disable-threads --disable-tls --with-newlib --without-headers --with-gnu-as --with-gnu-ld --with-python-dir=share/gcc-arm-vita-eabi --with-sysroot=${VITASDKROOT}/arm-vita-eabi  "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"  "--with-pkgversion=GNU Tools for ARM Embedded Processors [VitaSDK for MSYS2 by Soar Qin]" --disable-multilib --with-arch=armv7-a --with-tune=cortex-a9 --with-fpu=neon --with-float=hard --with-mode=thumb
  make ${JOBS} all-gcc && make install-gcc || exit 1
fi

if [ ${STEP8} ]; then
  echo "[Step 8] Build newlib..."
  if [ ! -d ${SRCDIR}/newlib/.git ]; then
    rm -rf ${SRCDIR}/newlib
    git clone https://github.com/vitasdk/newlib ${SRCDIR}/newlib
  else
    cd ${SRCDIR}/newlib
    git pull origin vita
  fi
  rm -rf ${BUILDDIR}/newlib
  mkdir -p ${BUILDDIR}/newlib
  cd ${BUILDDIR}/newlib
  ../${SRCRELDIR}/newlib/configure --host=i686-w64-mingw32 --build=i686-w64-mingw32 --target=arm-vita-eabi --prefix=${VITASDKROOT} --infodir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/info --mandir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/man --htmldir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/html --pdfdir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/pdf --enable-newlib-io-long-long --enable-newlib-register-fini --disable-newlib-supplied-syscalls --disable-nls
  make ${JOBS} && make install || exit 1
fi

if [ ${STEP9} ]; then
  echo "[Step 9] Build gcc final..."
  pushd ${VITASDKROOT}/arm-vita-eabi
  mkdir -p ./usr
  cp -rf include lib usr/
  popd
  rm -rf ${BUILDDIR}/gcc-${GCC_VERSION}-final
  mkdir -p ${BUILDDIR}/gcc-${GCC_VERSION}-final
  cd ${BUILDDIR}/gcc-${GCC_VERSION}-final
  ../${SRCRELDIR}/gcc-${GCC_VERSION}/configure --host=i686-w64-mingw32 --build=i686-w64-mingw32 --target=arm-vita-eabi --prefix=${VITASDKROOT} --libexecdir=${VITASDKROOT}/lib --infodir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/info --mandir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/man --htmldir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/html --pdfdir=${VITASDKROOT}/share/doc/gcc-arm-vita-eabi/pdf --enable-languages=c,c++ --enable-plugins --disable-decimal-float --disable-libffi --disable-libgomp --disable-libmudflap --disable-libquadmath --disable-libssp --disable-libstdcxx-pch --disable-nls --disable-shared --disable-threads --disable-tls --with-gnu-as --with-gnu-ld --with-newlib --with-headers=yes --with-python-dir=share/gcc-arm-vita-eabi --with-sysroot=${VITASDKROOT}/arm-vita-eabi  "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" "--with-pkgversion=GNU Tools for ARM Embedded Processors [VitaSDK for MSYS2 by Soar Qin]" --disable-multilib --with-arch=armv7-a --with-tune=cortex-a9 --with-fpu=neon --with-float=hard --with-mode=thumb
  make ${JOBS} INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0" && make install || exit 1

  pushd ${VITASDKROOT}
  rm -rf bin/arm-vita-eabi-gccbug
  LIBIBERTY_LIBRARIES=`find ${VITASDKROOT}/arm-vita-eabi/lib -name libiberty.a`
  for libiberty_lib in $LIBIBERTY_LIBRARIES ; do
      rm -rf $libiberty_lib
  done
  rm -rf ./lib/libiberty.a
  rmdir include
  popd
  rm -f ./arm-vita-eabi/usr
fi

if [ ${STEP10} ]; then
  echo "[Step 10] Build vita-headers..."
  if [ ! -d ${SRCDIR}/vita-headers/.git ]; then
    rm -rf ${SRCDIR}/vita-headers
    git clone https://github.com/vitasdk/vita-headers ${SRCDIR}/vita-headers
  else
    cd ${SRCDIR}/vita-headers
    git pull origin master
  fi
  rm -rf ${BUILDDIR}/vita-headers
  mkdir -p ${BUILDDIR}/vita-headers
  cd ${BUILDDIR}/vita-headers
  vita-libs-gen ${SRCDIR}/vita-headers/db.json .
  make ARCH=${VITASDKROOT}/bin/arm-vita-eabi ${JOBS} || exit 1
  cp *.a ${VITASDKROOT}/arm-vita-eabi/lib/
  cp -r ${SRCDIR}/vita-headers/include ${VITASDKROOT}/arm-vita-eabi/
  mkdir -p ${VITASDKROOT}/share
  cp ${SRCDIR}/vita-headers/db.json ${VITASDKROOT}/share
fi

if [ ${STEP11} ]; then
  echo "[Step 11] Strip binaries..."
  strip ${VITASDKROOT}/bin/*.exe
  strip ${VITASDKROOT}/arm-vita-eabi/bin/*.exe
  strip ${VITASDKROOT}/lib/gcc/arm-vita-eabi/${GCC_VERSION}/*.exe

  find ${VITASDKROOT} -name '*.la' -exec rm '{}' ';'

  for target_lib in `find ${VITASDKROOT}/arm-vita-eabi/lib -name \*.a` ; do
      arm-vita-eabi-objcopy -R .comment -R .note -R .debug_info -R .debug_aranges -R .debug_pubnames -R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str -R .debug_ranges -R .debug_loc $target_lib || true
  done

  for target_obj in `find ${VITASDKROOT}/arm-vita-eabi/lib -name \*.o` ; do
      arm-vita-eabi-objcopy -R .comment -R .note -R .debug_info -R .debug_aranges -R .debug_pubnames -R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str -R .debug_ranges -R .debug_loc $target_obj || true
  done

  for target_lib in `find ${VITASDKROOT}/lib/gcc/arm-vita-eabi/4.9.4 -name \*.a` ; do
      arm-vita-eabi-objcopy -R .comment -R .note -R .debug_info -R .debug_aranges -R .debug_pubnames -R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str -R .debug_ranges -R .debug_loc $target_lib || true
  done

  for target_obj in `find ${VITASDKROOT}/lib/gcc/arm-vita-eabi/4.9.4 -name \*.o` ; do
      arm-vita-eabi-objcopy -R .comment -R .note -R .debug_info -R .debug_aranges -R .debug_pubnames -R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str -R .debug_ranges -R .debug_loc $target_obj || true
  done
fi

export PATH=${OLDPATH}
export -n OLDPATH
echo "[DONE] Everything is OK!"
