EXIN="/tmp/exiftool_commands.$$"
EXLAUNCHED=0

launchexiftool() {
	[ "$EXLAUNCHED" = "1" ] && return
	mkfifo $EXIN
	exec 3< <( exiftool -q -stay_open 1 -@ - <$EXIN )
	EXLAUNCHED=1
}

haltexiftool() {
	[ "$EXLAUNCHED" = "0" ] && return
	echo "-stay_open" > $EXIN
	echo "false" > $EXIN
	sleep 1
	exec 3>&-
	rm -f $EXIN
	EXLAUNCHED=0
}

voidexiftool() {
	echo "-q\n-q" > $EXIN
	for p in $@ ; do 
		echo "$p" > $EXIN
	done
	echo "-execute" > $EXIN
}

callexiftool() {
	echo "-q\n-q" > $EXIN
	for p in $@ ; do 
		echo "$p" > $EXIN
	done
	echo "-execute" > $EXIN

	IFS=$'\t' read -u 3 -t 4 -A exif_res
}
