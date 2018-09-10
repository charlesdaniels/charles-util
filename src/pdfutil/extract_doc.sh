#!/bin/sh

# Extract documentation from pdfutil scripts. These use an older style of
# inline documentation that I have since deprecated, but I can't be bothered to
# rewrite them at this time.

TOK1='########10########20########30## DOCUMENTATION #50########60########70########80'
TOK2='########10########20########30'

TARGET_FILE="$1"

TOOLCHEST_DOC=""
if grep -qI . "$TARGET_FILE" ; then
	# this should prevent us from operating on a binary file with this
	# approach.
	TOOLCHEST_DOC="$(sed -n '/'"$TOK1"'/{:a;n;/'"$TOK2"'/b;p;ba}' "$TARGET_FILE" | cut -c2-)"
fi
if [ "$(echo "$TOOLCHEST_DOC" | wc -l)" -gt 1 ] ; then
	echo "$TOOLCHEST_DOC"
	exit $?
fi

