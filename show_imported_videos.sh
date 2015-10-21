#!/bin/zsh

. $(dirname $0)/config

# show just imported videos 
#sqlite3 -init /dev/null -batch -noheader -separator $'\t' $db "SELECT '$dest/'||path FROM video INNER JOIN just_imported ON id=video_id;" 2> /dev/null | while IFS=$'\t' read video; do
# 	seconds=$(ffprobe -show_entries format=duration $video 2> /dev/null | sed -n 2p)
#	seconds=${seconds:10}
#	screenshot=$(mktemp --suffix=fotom.jpg)
# 	ffmpeg -i $video -r 1 -s 128x128 -ss $(( seconds/2 )) -t 1 -f image2 $screenshot
# 	duration=$(ffprobe -pretty -show_entries format=duration $video 2> /dev/null | sed -n 2p)
#	duration=${duration:10}
#
#	args+="FALSE $duration $screenshot $video"
#done
#yad --list --print-all --dclick-action="tag.sh $(echo %s | cut -d ' ' -f 4)" --checklist --column=delete --column=duration --column=screenshot:IMG --column=file $args | grep ^TRUE | tr '|' ' ' | while read t d s file; do
#	if yad  --image "dialog-question" --title "Confirm Deletion" --button=gtk-yes:0 --button=gtk-no:1 --text "Delete file '$file_name'"; then
#		id=$(sqlite3 -init /dev/null -batch -noheader $db "SELECT id FROM video WHERE '$dest/'||path='$file';" 2> /dev/null)
#		rm -f $file && sqlite3 $db "UPDATE video SET deleted='Y' WHERE id='$id';"
#	fi
#done

#sqlite3 $db "DELETE FROM just_imported WHERE video_id IS NOT NULL;"
