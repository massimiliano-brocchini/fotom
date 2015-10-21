#!/bin/zsh

. $(dirname $0)/config
. $(dirname $0)/helpers/exiftool.sh

trap "{ haltexiftool; exit; }" EXIT
exif_res=()

launchexiftool

for f in $@; do
	if [[ -f "$f" ]]; then
		mime=$(file -b -i "$f")
		if [[ "${mime:0:5}" != "image" ]]; then
			echo "Not recognized image: $f" >&2
			continue
		fi
	fi

	new_id=""
	file=${f##*/}
	file_name=${file:l}

#TODO: test EXIF orientation
	callexiftool -t -s3 -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal -Model -FileNumber -ImageUniqueId $f 
	data=$exif_res[1]
	model=$exif_res[2]
	filenum=$exif_res[3]
	id=$exif_res[4]

	# ImageUniqueId available only in some pictures
	if [[ -z "$id" ]]; then
		id="m${${data:0:10}//-/}${${data:11:8}//:/}"
		id=$id${${${filenum:-${file_name%.*}}//-/}: -$(( 33-${#id}))}
		id=$id${${model// /}: -$(( 33-${#id}))}
		new_id=$id
	fi

	foto_id=$(sqlite3 -init /dev/null -batch -noheader $db "SELECT id FROM foto WHERE image_unique_id='$id';" 2> /dev/null)
	if [[ -z "$foto_id" ]]; then
		dir=${data:0:4}/${data:5:2}
		mkdir -p $dest/$dir
		"cp" $f $dest/$dir/$file_name
		# re-assign correct creation date to file
		touch -d "$data" $dest/$dir/$file_name
		# assign unique id where missing
		if [[ -n "$new_id" ]]; then
			voidexiftool -P -overwrite_original_in_place -ImageUniqueId="$new_id" $dest/$dir/$file_name
		fi
		sqlite3 -init /dev/null $db "INSERT INTO foto (image_unique_id,path) VALUES ('$id','$dir/$file_name'); INSERT INTO just_imported (foto_id) SELECT id FROM foto WHERE image_unique_id='$id';" 2> /dev/null
	fi
done
