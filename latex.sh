#!/usr/bin/env bash

set -eo pipefail

if [ $# -eq 0 ]
	then
		echo "Usage: $(basename $0) <command> <args>"
		echo "commands:"
		echo "	activate : add latex.sh to PATH"
		echo "	init : initialize latex project"
		echo "	add : add chapter/section/subsection"
		echo "	del : delete chapter/section/subsection"
		exit 1
fi

function get_root() {
	# get root directory of project ( always git repo )
	root="$(git rev-parse --show-toplevel 2> /dev/null || true)"

	if [ "$root" -eq ""]
		then
			echo "no .git directory found, initialize latex.sh project with: '$(basename $0) init'!"
			exit 1
	fi

	echo "$root"
}

trap clear_files SIGINT
function clear_files() {
	echo "clearing up"
	cd "$(get_root)"
	latexmk -c -cd root.tex
}

case "$1" in
	add)
				# check if chapter/section/subsection exists
				if [ -e "$2" ]
				then
					echo "chapter named $2 already exists (directory exists)"
					exit 1
				fi

				# determine type
				root="$(get_root)"
				depth="$(pwd)"
				depth="$(echo ${depth#"$root"} | grep -o / | wc -l || true)"

				case "$depth" in
				0)
					type='chapter'
					;;
				1)
					type='section'
					;;
				2)
					type='subsection'
					;;
				*)
					echo "unknown tree depth (already at lowest level? (subsection))"
					exit 1
					;;
				esac

				echo "adding $type"

				# create chapter file structure
				mkdir "$2" "$2/img"
				echo "\\$type{$2}" > "$2/$2.tex"
				touch "$2/.includes_$2.tex"
				echo "\input{.includes_$2.tex}" >> "$2/$2.tex"
				echo "\subimport{$2/}{$2.tex}" >> .includes*.tex
		;;

	del)
			# delete chapter/section/subsection folder
			target="$(echo "$2" | tr -d "/")"
			if [ -d $target ]
				then
					rm -rf "$target"
					sed -i "/$target.tex/d" .includes*.tex
				else
					echo "unknown target"
					exit 1
			fi
		;;

	init)
			echo "initializing latex project..."
			git init
			;;

	compile)
			echo "compiling project to output file /main.pdf"
				cd "$(get_root)"
				latexmk -pdf -cd root.tex
				clear_files
			;;

	preview)
			if [ $# -eq 1 ]
				then
					echo "open /root.pdf to live preview your changes"
					cd "$(get_root)"
					# ignore errors by spamming 'x'
					yes x | latexmk -pvc -pdf -cd root.tex
				else
					if [ -d "$4" ]
					# TODO preview
					then
						echo "previewing chapter $4"
						yes x | latexmk -pvc -pdf -cd main/chapter.tex
						latexmk -c -cd main/chapter.tex
						exit 1
					fi
			fi
			;;
	activate)
		  PATH="$PATH:$(pwd)" bash
			;;

	*)
			echo "unknown command"
			exit 1
			;;
esac
