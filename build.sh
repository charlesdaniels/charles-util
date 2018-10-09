#!/bin/sh

# Build system for charles-util. This script handles any platform-specific
# configuration that needs to happen, as well as copying binaries into the
# right places. It winds up ultimately calling Makefiles from the src/
# directory.

set -u
set -e
cd "$(dirname "$0")"

BIN_DIR="$(pwd)/bin/"
MAN_DIR="$(pwd)/man/"

# handle parameters
USE_PYINSTALLER=0
USE_PP=0
PREFIX=/usr/local

print_help () {
	echo "charles-util build system"
	echo ""
	echo "-p"
	echo "\tSelect prefix (default: /usr/local/)"
	echo ""
	echo "-i"
	echo "\tDisable pyinstaller (pythons scripts will be copied unmodified)"
	echo ""
	echo "-P"
	echo "\tDisable perl packer (perl scripts will be copied unmodified)"
	echo ""
	echo "-h"
	echo "\tDisplay this help message"
	echo ""
	echo ""
	echo "VERB"
	echo "\tThe verb specifies what you want the build script to do, the"
	echo "\tchoices are: build, clean, install, release."
	exit 0
}

if [ $# -lt 1 ] ; then
	$0 -h
	exit 1
fi

while getopts 'hiPp:' opt ; do
	case "$opt" in
	i)	USE_PYINSTALLER=1;;
	p)	PREFIX="$OPTARG";;
	P)	USE_PP=1;;
	h)	print_help;;
	*)	echo "usage: build.sh [-h] [-p] [-P] [-i] VERB" > /dev/stderr
		exit 1;;
	esac
done
shift $(expr $OPTIND - 1)

VERB="$1"

if [ $USE_PYINSTALLER != 0 ] ; then
	echo "disabled pyinstaller"
fi

if [ $USE_PP != 0 ] ; then
	echo "disabled pp"
fi

echo "select prefix $PREFIX"

# platform specific handling

# make sure that we get GNU make
MAKE_COMMAND=""
if make --version | grep "GNU Make" > /dev/null ; then
	MAKE_COMMAND="make"
else
	MAKE_COMMAND="gmake"
fi

# sanity check
if [ ! -x "$(which "$MAKE_COMMAND")" ] ; then
	echo "FATAL: make command '$MAKE_COMMAND' not found"
else
	echo "selected make command '$MAKE_COMMAND'"
fi

# handle verb
case "$VERB" in
	build)
		mkdir -p "$BIN_DIR"
		mkdir -p "$MAN_DIR"
		ERRCOUNT=0
		if ! bookman -p -r "charles-util R$(cat RELEASE)" -t 'charles-util Reference Manual' man/*/* > manual.pdf ; then
			ERRCOUNT=$(expr $ERRCOUNT + 1)
		fi
		for d in src/* ; do
			if ! "$MAKE_COMMAND" \
				BIN_DIR="$BIN_DIR" \
				MAN_DIR="$MAN_DIR" \
				USE_PYINSTALLER=$USE_PYINSTALLER \
				USE_PP=$USE_PP \
				-C "$d" \
				generate ; then
				ERRCOUNT=$(expr $ERRCOUNT + 1)
			fi
		done
		echo "errors: $ERRCOUNT"
		exit $ERRCOUNT
		;;
	clean)
		rm -rf "$BIN_DIR"
		rm -rf "$MAN_DIR"
		rm -f *.tar.xz
		for d in src/* ; do
			"$MAKE_COMMAND" \
				BIN_DIR="$BIN_DIR" \
				MAN_DIR="$MAN_DIR" \
				-C "$d" \
				clean
		done
		;;
	install)
		mkdir -p "$PREFIX/bin/"
		mkdir -p "$PREFIX/man/"
		cp -R "$BIN_DIR"/* "$PREFIX/bin/"
		cp -R "$MAN_DIR"/* "$PREFIX/man/"
		;;
	release)
		echo "make sure you've run build before you generate the release"
		RELEASE_NAME="charles-util_R$(cat RELEASE)_$(uname -m)_$(uname).tar.xz"
		PROJECT_DIR="$(pwd)"
		PROJECT_BASENAME="$(basename "$(pwd)")"
		cd ..
		tar cfJ "$PROJECT_BASENAME/$RELEASE_NAME" \
			"$PROJECT_BASENAME/manual.pdf" \
			"$PROJECT_BASENAME/bin" \
			"$PROJECT_BASENAME/man" \
			"$PROJECT_BASENAME/README.md" \
			"$PROJECT_BASENAME/LICENSE" \
			"$PROJECT_BASENAME/INSTALL" \
			"$PROJECT_BASENAME/RELEASE" \
			"$PROJECT_BASENAME/build.sh"
		;;

	*)
		echo "FATAL: invalid verb '$VERB', try build.sh -h for help" > /dev/stderr
		exit 1
	;;
esac
