#!/bin/zsh

. $(dirname $0)/config
. $(dirname $0)/helpers/exiftool.sh

trap "{ haltexiftool; exit; }" EXIT
exif_res=()

while getopts ":fv" opt; do
	case $opt in
		v)
			file_type='video'
		;;
		\?)
			echo "Invalid option: -$OPTARG use [-f or -v]" >&2
			exit 1
		;;
	esac
done
shift $((OPTIND-1))

file_type=${file_type:-'foto'}

launchexiftool

tag_ids=()
tags=()
num_tags=0


available_tags() {
	sqlite3 -init /dev/null -batch -noheader -separator $'\t' $db 'SELECT id,tag FROM tags ORDER BY tag;' 2> /dev/null | while IFS=$'\t' read id tag; do 
		tag_ids+=($id)
		tags+=($tag)
		(( num_tags++ ))
	done
}

#@params:
# 1: 'foto' / 'video'
# 2: foto or video id
# 3: batch processing (don't check assigned tags)
assigned_tags() {
	for t in $tags; do
#TODO non eseguire una query per ciascun tag, ma estrarre tutti i tag in un array associativo: tag => TRUE
		if [[ -z "$3" ]]; then
			checked=$(sqlite3 -init /dev/null -batch -noheader -separator $'\t' $db "SELECT 'TRUE' FROM ${1}_tags INNER JOIN tags ON tag_id=id WHERE ${1}_id=$2 AND tag='$t';" 2> /dev/null)
		fi
		args+=" --field=\"$t\":CHK ${checked:-FALSE}"
	done
}

#@params:
# 1: 'foto' / 'video'
# 2: foto or video id
# 3: add only mode (for batch processing)
existing_tags_changes() {
	ct=1
	for i in {1..${#res}}; do
		x=$res[i]
		if [[ "$x" == "|" ]]; then 
			if [[ "$value[ct]" == "TRUE" ]]; then
				sqlite3 -init /dev/null $db "PRAGMA foreign_keys=on; INSERT OR IGNORE INTO ${1}_tags (${1}_id,tag_id) VALUES ($2,$tag_ids[ct]);" 2> /dev/null
				if [[ "$1" == "foto" && "$keywords" == "${keywords/$tags[ct]/}" ]]; then
					voidexiftool -P -overwrite_original_in_place "-IPTC:Keywords+=$tags[ct]" "$file_name"
				fi
			elif [[ "$value[ct]" == "FALSE" && -z "$3" ]]; then 
				sqlite3 -init /dev/null $db "PRAGMA foreign_keys=on; DELETE FROM ${1}_tags WHERE ${1}_id = $2 AND tag_id = $tag_ids[ct];" 2> /dev/null
				if [[ "$1" == "foto" && "$keywords" != "${keywords/$tags[ct]/}" ]]; then
					voidexiftool -P -overwrite_original_in_place "-IPTC:Keywords-=$tags[ct]" "$file_name"
				fi
			fi
			(( ct++ ))
		else
			value[ct]+=$x
		fi
	done
}

#@params:
# 1: 'foto' / 'video'
# 2: foto or video id
new_tags() {
	new=${value[(( num_tags+1 ))]}
	if [[ "$new" != "" ]]; then
		sqlite3 -init /dev/null $db "PRAGMA foreign_keys=on; INSERT OR IGNORE INTO tags (tag) VALUES ('$new'); INSERT OR IGNORE INTO ${1}_tags (${1}_id,tag_id) SELECT $2,id FROM tags WHERE tag='$new';" 2> /dev/null
		# adds the new tag if not already present in file's metadata
		if [[  "$1" == "foto" ]]; then
 			callexiftool -s3 -IPTC:Keywords $file_name 
			if [[ "$exif_res[1]" != *$new* ]]; then
				voidexiftool -P -overwrite_original_in_place "-IPTC:Keywords+=$new" "$file_name"
			fi
		fi
	fi
}


# --------- MAIN CODE --------- 


if [[ $# -gt 1 ]]; then
	batch='true'
fi


for file_name in $@; do
	exif_res=()
	value=()

	if [[ "$file_type" == "foto" ]]; then
		callexiftool -t -s3 -ImageUniqueId -IPTC:Keywords $file_name 
		id=$exif_res[1] 
		keywords=$exif_res[2]

		file_id=$(sqlite3 -init /dev/null -batch -noheader -separator $'\t' $db "SELECT id FROM foto WHERE image_unique_id='$id';" 2> /dev/null)
	elif [[ "$file_type" == "video" ]]; then 
		file_id=$(sqlite3 -init /dev/null -batch -noheader -separator $'\t' $db "SELECT id FROM video WHERE imported_md5='$(md5sum "$file_name")';" 2> /dev/null)
	else
		exit 1
	fi

	if [[ -z "$file_id" ]]; then
		exit
	fi

	# get all available tags
	if [[ -z "$res" ]]; then
		available_tags
	fi

	# tags associated to the file
	assigned_tags $file_type $file_id $batch

	# in case of batch processing, show tag dialog just once 
	if [[ -z "$res" ]]; then
		#TODO: calcolo numero di colonne
		res=$(eval yad --title="'tag BATCH MODE (ADD ONLY)'" --form --columns=2 $args --field=_new_tag)
		# result format: TRUE|TRUE|FALSE|FALSE|new tag value|

		# cancel pressed, nothing to do
		if [[ "$res" == "" ]]; then
			exit 0
		fi
	fi

	# process existing tags association changes
	existing_tags_changes $file_type $file_id $batch

	# process new tag
	new_tags $file_type $file_id
done

# re-run this script if a new tag has been defined
if [[ "$new" != "" ]]; then
	zsh $0 $@
fi
