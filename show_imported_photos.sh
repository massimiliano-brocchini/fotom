#!/bin/zsh

. $(dirname $0)/config


# show just imported pictures
sqlite3 -init /dev/null -batch -noheader $db "SELECT '$dest/'||path FROM foto INNER JOIN just_imported ON id=foto_id; ORDER BY 1" 2> /dev/null | xargs gqview -l 

# check for any picture renamed or deleted
sqlite3 -init /dev/null -batch -noheader -separator $'\t' $db "SELECT id, path FROM foto INNER JOIN just_imported ON id=foto_id;" 2> /dev/null | while IFS=$'\t' read id foto_path; do
	if [[ ! -f "$dest/$foto_path" ]]; then
		for x in $dest/${foto_path%/*}*${foto_path##*/}; do
			if [[ -f "$x" ]]; then
				sqlite3 -init /dev/null $db "UPDATE foto SET path='${x##$dest/}' WHERE id='$id';"
			else
				sqlite3 -init /dev/null $db "UPDATE foto SET deleted='Y' WHERE id='$id';"
			fi
		done
	fi
done

sqlite3 -init /dev/null $db "DELETE FROM just_imported WHERE foto_id IS NOT NULL;"
