#!/bin/zsh

file=$2
new_tags=$3

	for i in {1..${#string}}; do
		x=$string[i]
		if [[ "$x" == "$sep" ]]; then 
			echo $value
			value=""
		else
			value+=$x
		fi
	done
	echo $value


  if [[ "$1" == "get" ]]; then
	read_tags $file
	echo $tags
	exit 0
elif [[ "$1" == "set" ]]; then
	write_tags $file $new_tags
	exit 0
elif [[ "$1" == "add" ]]; then
	read_tags $file
	old_tags=$tags

	for i in {1..${#tags}}; do
		x=$string[i]
		if [[ "$x" == "," ]]; then 
			if [[ "${tags/$value/}" == "$tags" ]]; then
				tags+=$value
			fi
			value=""
		else
			value+=$x
		fi
	done
	if [[ "${tags/$value/}" == "$tags" ]]; then
		tags+=$value
	fi

	if [[ "$tags" != "$old_tags" ]]; then
		write_tags $file $tags
	fi	
elif [[ "$1" == "del" ]]; then
	read_tags $file
	old_tags=$tags

	for i in {1..${#tags}}; do
		x=$string[i]
		if [[ "$x" == "," ]]; then 
			tags=${tags/$value/}
			value=""
		else
			value+=$x
		fi
	done
	tags=${tags/$value/}

	if [[ "$tags" != "$old_tags" ]]; then
		write_tags $file $tags
	fi	
else
	echo "Unrecognized command: $1"
	exit 1
fi

read_tags() {
	tags=$(ffprobe -show_entries format_tags=comment $1 2> /dev/null | sed -n 2p)
	tags=${tags:12}
}


write_tags() {
	src_dir=$(dirname $1)
	src_file=$(filename $1)

	# {{{ writes copy of source file with tags in /tmp or target directory itself according to space availability
	filesize=$(stat -c %s $1)
	freetmp=$(/bin/df --output=avail /tmp 2> /dev/null | tail -n 1)000
	freedir=$(/bin/df --output=avail $1 2> /dev/null | tail -n 1)000

	if [[ $filesize < $freetmp ]]; then
		temp_dest="/tmp"
	elif [[ $filesize < $freedir ]]; then
		temp_dest=$src_dir
	else
		echo "Error: not enough free space in /tmp or $src_dir for file $1"
		exit 99
	fi
	# }}}

	ffmpeg -i $1 -metadata comment=$2 -codec copy $temp_dest/$src_file.wip && /bin/mv $temp_dest/$src_file.wip $1
}
