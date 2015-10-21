#!/bin/zsh

. $(dirname $0)/config

for f in $@; do
	if [[ -f "$f" ]]; then
		mime=$(file -b -i "$f")
		if [[ "${mime:0:5}" != "video" ]]; then
			echo "Not recognized video: $f" >&2
			continue
		fi
	fi

	file=$(basename $f)
	file_name=$(echo $file | tr '[:upper:]' '[:lower:]')
	md5sum $f | read orig_md5 x

#TODO: cercare video da macchine canon non convertiti e verificare se hanno una data di registrazione tra i metadati
#vedere anche i video girati dalla macchina della angela
	d=$(mediainfo --Output="General;%Encoded_Date%" $f)
	if [[ -n "$d" ]]; then
		data=$(LC_ALL=it_IT date -d "$d" "+%Y-%m-%d %X")
	else
		data=$(stat -c %y $f)
	fi

	video_id=$(echo "SELECT id FROM video WHERE original_md5='$orig_md5';" | sqlite3 -init /dev/null $db 2> /dev/null)
	if [[ -z "$video_id" ]]; then
		dir=${data:0:4}/${data:5:2}
		mkdir -p $dest/$dir
		dest_file="${file_name%%.*}.mov"

		m=$(mediainfo --Output="Video;%CodecID%" "$f")
		if [[  "$m" != "H264" ]]; then
			ffmpeg -threads "$(cat /proc/cpuinfo | grep "^processor" | wc -l)" -i "$f" -acodec mp3 -vcodec libx264 -metadata date="$data" "$dest/$dir/$dest_file"
		else
			"cp" "$f" "$dest/$dir/$dest_file"
		fi

		touch --date="$data" "$dest/$dir/$dest_file"
		md5sum "$dest/$dir/$dest_file" | read imp_md5 x
		sqlite3 -init /dev/null $db "INSERT INTO video (original_md5,imported_md5,path) VALUES ('$orig_md5','$imp_md5','$dir/$dest_file');" 2> /dev/null
		video_id=$(sqlite3 -init /dev/null -batch -noheader $db "SELECT id FROM video WHERE original_md5='$orig_md5';" 2> /dev/null)
	fi
	sqlite3 -init /dev/null $db "INSERT INTO just_imported (video_id) VALUES ($video_id);" 2> /dev/null
done
