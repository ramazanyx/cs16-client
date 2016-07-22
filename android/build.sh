#!/bin/bash

if [[ "$1" = "--help" ]]; then
	echo "Usage: ./build.sh <release|debug> <omp|noomp>"
	exit 0
fi

if [[ "$#" -ne "2" ]]; then
	echo "Illegal number of parameters, see ./build.sh --help"
	exit 0
fi

if [[ "$1" = "release" ]]; then
	RELEASE="0"
else
	RELEASE="1 APP_CFLAGS=\"-gdwarf-3\""
fi

if [[ "$2" = "omp" ]]; then
	OMP="1"
	NAME_POSTFIX="omp"
else
	OMP="0"
	NAME_POSTFIX="noomp"
fi

echo "*****************************************"
echo "* OMP: $OMP "
echo "* RELEASETYPE: $RELEASE "
echo "*****************************************"

set -x

# Clean
rm -rf obj/ libs/armeabi-v7a libs/armeabi libs/x86 bin/ gen/ assets/ pak/

# Regenerate PAK file
mkdir -p pak/
mkdir -p assets/
cp -r ../3rdparty/extras/* pak/
python2 makepak.py pak/ assets/extras.pak

# Build
ndk-build -j8 NDK_TOOLCHAIN_VERSION=4.8 _CS16CLIENT_ENABLE_OPENMP=$OMP NDK_DEBUG=$RELEASE 
ant $1
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ../../myks.keystore bin/cs16-client-$1-unaligned.apk xashdroid -tsa https://timestamp.geotrust.com/tsa
$HOME/.android/android-sdk-linux/build-tools/23.0.3/zipalign 4 bin/cs16-client-$1-unaligned.apk bin/cs16-client.apk
mv bin/cs16-client.apk cs16-client-$1-$NAME_POSTFIX.apk

