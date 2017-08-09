#!/bin/bash

# Gra na przedmiot Systemy Operacyjne, PG ETI 2016
# (c) Copyright Piotr P (grupa 6, indeks 149528)
# Wymagany software do poprwnego dzialania:
# 	*zenity + java
#	*GnuPG
#	*base64 (GNU coreutils)
#	*imagemagick 6
#
# A game for Operating Systems for Computer Science on Gdansk University of Technology, PG ETI 2016
# Software needed for this to work:
# *bash
# *zenity + java
# *GnuPG
# *base64 from GNU coreutils
# *imagemagick 6

HEAD_COLOR="#EEAA33"
BODY_COLOR="#CC8888"
LEGS_COLOR="#991133"
BOOTS_COLOR="#112211"
DIRECTION=0
PLAYER_X=6
PLAYER_Y=13

GAME_PROGRESS=0
NWSE=("Go north" "Go west" "Go south" "Go east" "Examine" "Take" "Use" "Show map")
ACTIONS=("Continue" "Save")

source Data.sh

MAP=()

function is_takeable(){
	O=`echo $1|rev|cut -d" " -f1|rev`
	for qo in $TAKEABLES; do
		if [[ $qo -eq $O ]]; then
			return 1
		fi
	done
	return 0
}

function pop_object(){
	atX=$1
	atY=$2
	if [[ $atX -lt 1 ]] || [[ $atX -gt $((MAP_WIDTH-1)) ]] || [[ $atY -lt 1 ]] || [[ $atY -gt $((MAP_HEIGHT-1)) ]]; then
		echo "Out of bounds!"
	else
		ROW=${MAP[$atY]}
		if [[ ! $atX -eq 1 ]]; then
			L=''
		else
			L=`echo $ROW|cut -d, -f1-$((atX-1))`
		fi
		C=`echo $ROW|cut -d, -f$atX`
		if [[ ! $atX -eq $((MAP_WIDTH-1)) ]]; then
			R=''
		else
			R=`echo $ROW|cut -d, -f$((atX+1))-$((MAP_WIDTH-1))`
		fi
		C=`echo $C|rev|cut -d" " -f2-|rev`
		ROW="$L,$C,$R"
		MAP[$atY]=$ROW
	fi
}

function push_object(){
	atX=$1
	atY=$2
	what=$3
	if [[ $atX -lt 1 ]] || [[ $atX -gt $((MAP_WIDTH-1)) ]] || [[ $atY -lt 1 ]] || [[ $atY -gt $((MAP_HEIGHT-1)) ]]; then
		echo "Out of bounds!"
	fi
	
	#fi
}

function in_blockings(){
	for qi in $BLOCKINGS; do
		if [ $qi -eq $1 ]; then
			return 1
		fi
	done
	return 0
}

function is_blocking() {
	for wi in "$@"; do
		in_blockings $wi
		ret=$?
		if [ $ret -eq 1 ]; then
			return 1
		fi
	done
	return 0
}

function load_map(){
	MAP_WIDTH=$(head -n 1 "$1"|cut -d, -f1)
	MAP_HEIGHT=$(head -n 1 "$1"|cut -d, -f2)
	PLAYER_X=$(head -n 1 "$1"|cut -d, -f3)
	PLAYER_Y=$(head -n 1 "$1"|cut -d, -f4)
	I=0
	while read line; do
		if [ "$I" -eq 0 ]; then
			I=1
		elif [ "$I" -lt $(($MAP_HEIGHT+1)) ]; then
			MAP+=( "`echo "$line"|cut -d"," -f1-$MAP_WIDTH`" )
			let 'I=I+1'
		fi
	done < "$1"
}

function compose(){
	COMPOSE=""
	for i in "$@"; do
		COMPOSE+="-page 32x32-"
		MATHS=$(echo "32*$i"|bc)
		COMPOSE+=$MATHS
		COMPOSE+="+0 sprites.png "
	done
	COMPOSE+="-background none -compose SrcOver -flatten -"
	DATA=$(convert $COMPOSE|base64)
	IMG="<img src=\"data:image/png;base64,$DATA\"/>"
}

function compose_player(){
	(echo -n "$DATA"|base64 -d)>".tmp_sprite.png"
	DATA=$(convert -page 32x32-$(echo "32*$DIRECTION"|bc)+0 player_mask.png -fill $HEAD_COLOR -opaque yellow -fill $BODY_COLOR -opaque red -fill $LEGS_COLOR -opaque LIME -fill $BOOTS_COLOR -opaque blue -background none -flatten -|\
	convert -page 32x32-$(echo "32*$DIRECTION"|bc)+0 player.png -page 32x32+0+0 - -background none -compose multiply -flatten -|\
	convert -page 32x32+0+0 .tmp_sprite.png -page 32x32+0+0 - -background none -compose SrcOver -flatten -|\
	base64)
	IMG="<img src=\"data:image/png;base64,$DATA\"/>"
	#rm .tmp_player.png
}

function mk_image(){
	if test -z $1; then
		zenity --warning --text "No input file."
	elif [ ! -e "$1" ]; then
		echo "No such file: $1"
		zenity --error --text "No such file $1"
	else
		IMG="<img src=\"data:$(mimetype -b $1);base64,$(base64 $1)\"/>"
	fi
}

if [ "$#" -lt 1 ]; then
	echo "Please specify the map."
	echo "To load use $0 [map.csv] [savegame.file]"
	echo "To use zenity dialog replace files with -dialog"
	echo "Example: $0 -dialog save.pgp"
	exit 3
elif [ "$#" -eq 1 ]; then
	echo "To load use $0 [map.csv] [savegame.file]"
	echo "To use zenity dialog replace files with -dialog"
	echo "Example: $0 -dialog save.pgp"
	if [ "$1" == "-dialog" ]; then
		"Using zenity dialog to select map."
		MAP=$(zenity --file-selection --title "Select map")
		if [ ! -e "$MAP" ]; then
			echo "$MAP not found!"
			zenity --error --text "$MAP not found!"
			exit 3
		fi
	elif [ -e "$1" ]; then
		echo "Loading map $1"
		MAP="$1"
	else
		echo "Map $1 not found!"
		zenity --error --text "Map $1 not found!"
		exit 3
	fi
	load_map "$MAP"
	
	HEAD_COLOR=$(zenity --color-selection --title "Select head color")
	BODY_COLOR=$(zenity --color-selection --title "Select body color")
	LEGS_COLOR=$(zenity --color-selection --title "Select legs color")
	BOOTS_COLOR=$(zenity --color-selection --title "Select boots color")
elif [ "$#" -eq 2 ]; then
	if [ "$1" == "-dialog" ]; then
		"Using zenity dialog to select map."
		MAP=$(zenity --file-selection --title "Select map")
		if [ ! -e "$MAP" ]; then
			echo "$MAP not found!"
			zenity --error --text "$MAP not found!"
			exit 3
		fi
	elif [ -e "$1" ]; then
		echo "Loading map $1"
		MAP="$1"
	else
		echo "Map $1 not found!"
		zenity --error --text "Map $1 not found!"
		exit 3
	fi
	load_map "$MAP"
	if [ "$2" == "-dialog" ]; then
		echo "Using zenity dialog to select save."
		FILE=$(zenity --file-selection --title "Select game file")
		if [ ! -e "$FILE" ]; then
			echo "Not selected!"
			exit 1
		fi
	else
		echo "Trying to load file $2.gpg or $2."
		#Check if file to load exists
		if [ -e "$2.gpg" ]; then
			FILE="$2.gpg"
		elif [ -e "$2" ]; then
			FILE="$2"
		else
			echo "Failed to locate $1.gpg or $1!"
			zenity --error --text "Failed to locate $1.gpg or $1!"
			exit 1
		fi
	fi
	
	#Decrypt our savegame
	PASSWORD=$(zenity --password --title "Decryption: $FILE")
	echo "$PASSWORD"|gpg --batch --yes -o ".game_save.tmp" -d --passphrase-fd 0 "$FILE"
	
	if [ "$?" != "0" ]; then
		echo "Bad password!"
		zenity --error --text "Bad password!"
		exit 2
	else
		echo "File decrypted!"
	fi
	cat ".game_save.tmp" | zenity --text-info --title "Save contents" --height 150
	HEAD_COLOR=$(head -n 1 .game_save.tmp|cut -d" " -f1)
	BODY_COLOR=$(head -n 1 .game_save.tmp|cut -d" " -f2)
	LEGS_COLOR=$(head -n 1 .game_save.tmp|cut -d" " -f3)
	BOOTS_COLOR=$(head -n 1 .game_save.tmp|cut -d" " -f4)
	PLAYER_X=$(head -n 1 .game_save.tmp|cut -d" " -f5)
	PLAYER_Y=$(head -n 1 .game_save.tmp|cut -d" " -f6)
	DIRECTION=$(head -n 1 .game_save.tmp|cut -d" " -f7)
	rm ".game_save.tmp"
fi

while true; do
opt=$(zenity --list --height 300 --title "Menu" --text "Game paused" --cancel-label "Quit" --ok-label "Do" --column "Actions" ${ACTIONS[@]})
	
	if [[ $? -eq 1 ]]; then
		echo "Bye"
		break
	fi
	
	case "$opt" in
		"${ACTIONS[0]}" )
		while true; do
			opt=$(zenity --list --height 300 --title "Actions" --text "What to do next?" --cancel-label "Menu" --ok-label "Do" --column "Directions" "${NWSE[@]}")
		
			if [[ $? -eq 1 ]]; then
				break
			fi
		
			case $opt in
			
				"${NWSE[0]}" )
				DIRECTION=1
				if [[ $PLAYER_Y -gt 1 ]]; then
					is_blocking $(echo ${MAP[$((PLAYER_Y-1))]}|cut -d, -f$PLAYER_X)
					if [ $? -eq 0 ]; then
						let 'PLAYER_Y=PLAYER_Y-1'
					else
						zenity --info --text "Something is blocking the path!"
					fi
				else
					zenity --info --text "Cannot move there!"
				fi
				;;
				"${NWSE[1]}" )
				DIRECTION=2
				if [[ $PLAYER_X -gt 1 ]]; then
					is_blocking $(echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X-1)))
					if [ $? -eq 0 ]; then
						let 'PLAYER_X=PLAYER_X-1'
					else
						zenity --info --text "Something is blocking the path!"
					fi
				else
					zenity --info --text "Cannot move there!"
				fi
				;;
				"${NWSE[2]}" )
				DIRECTION=0
				if [[ $PLAYER_Y -lt $((MAP_HEIGHT-1)) ]]; then
					is_blocking $(echo ${MAP[$((PLAYER_Y+1))]}|cut -d, -f$PLAYER_X)
					if [ $? -eq 0 ]; then
						let 'PLAYER_Y=PLAYER_Y+1'
					else
						zenity --info --text "Something is blocking the path!"
					fi
				else
					zenity --info --text "Cannot move there!"
				fi
				;;
				"${NWSE[3]}" )
				DIRECTION=3
				if [[ $PLAYER_X -lt $((MAP_WIDTH-1)) ]]; then
					is_blocking $(echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X+1)))
					if [ $? -eq 0 ]; then
						let 'PLAYER_X=PLAYER_X+1'
					else
						zenity --info --text "Something is blocking the path!"
					fi
				else
					zenity --info --text "Cannot move there!"
				fi
				;;
				
				"${NWSE[4]}" )
				case $DIRECTION in
					1 )
					if [[ $((PLAYER_Y-1)) -gt 1 ]]; then
						INFRONT=${NAMES[`echo ${MAP[$((PLAYER_Y-1))]}|cut -d, -f$PLAYER_X|rev|cut -d" " -f1|rev`]}
					else
						INFRONT="end of the world"
					fi
					;;
					2 )
					if [[ $((PLAYER_X-1)) -gt 1 ]]; then
						INFRONT=${NAMES[`echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X-1))|rev|cut -d" " -f1|rev`]}
					else
						INFRONT="end of the world"
					fi
					;;
					0 )
					if [[ $((PLAYER_Y+1)) -lt $((MAP_HEIGHT-1)) ]]; then
						INFRONT=${NAMES[`echo ${MAP[$((PLAYER_Y+1))]}|cut -d, -f$PLAYER_X|rev|cut -d" " -f1|rev`]}
					else
						INFRONT="end of the world"
					fi
					;;
					3 )
					if [[ $((PLAYER_X+1)) -lt $((MAP_WIDTH-1)) ]]; then
						INFRONT=${NAMES[`echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X+1))|rev|cut -d" " -f1|rev`]}
					else
						INFRONT="end of the world"
					fi
					;;
				"${NWSE[5]}" )
					case $DIRECTION in
						1 )
							if [[ $PLAYER_Y -gt 1 ]]; then
								is_takeable `echo ${MAP[$((PLAYER_Y-1))]}|cut -d, -f$PLAYER_X`
								if [ $? -eq 1 ]; then
									pop_object $PLAYER_X $((PLAYER_Y-1)) `echo ${MAP[$((PLAYER_Y-1))]}|cut -d, -f$PLAYER_X|rev|cut -d" " -f1|rev`
								else
									zenity --warning --text "Nothing to take!"
								fi
							else
								zenity --warning --text "Cannot take nothing!"
							fi
						;;
						2 )
							if [[ $PLAYER_X -gt 1 ]]; then
								is_takeable `echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X-1))`
								if [ $? -eq 1 ]; then
									pop_object $((PLAYER_X-1)) $PLAYER_Y `echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X-1))|rev|cut -d" " -f1|rev`
								else
									zenity --warning --text "Nothing to take!"
								fi
							else
								zenity --warning --text "Cannot take nothing!"
							fi
						;;
						0 )
							if [[ $PLAYER_Y -lt $((MAP_HEIGHT-1)) ]]; then
								is_takeable `echo ${MAP[$((PLAYER_Y+1))]}|cut -d, -f$PLAYER_X`
								if [ $? -eq 1 ]; then
									pop_object $PLAYER_X $((PLAYER_Y+1)) `echo ${MAP[$((PLAYER_Y+1))]}|cut -d, -f$PLAYER_X|rev|cut -d" " -f1|rev`
								else
									zenity --warning --text "Nothing to take!"
								fi
							else
								zenity --warning --text "Cannot take nothing!"
							fi
						;;
						3 )
							if [[ $PLAYER_X -lt $((MAP_WIDTH-1)) ]]; then
								is_takeable `echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X+1))`
								if [ $? -eq 1 ]; then
									pop_object $((PLAYER_X+1)) $PLAYER_Y `echo ${MAP[$PLAYER_Y]}|cut -d, -f$((PLAYER_X+1))|rev|cut -d" " -f1|rev`
								else
									zenity --warning --text "Nothing to take!"
								fi
							else
								zenity --warning --text "Cannot take nothing!"
							fi
						;;
					esac
					;;
				esac
				zenity --info --text "Below you ${NAMES[`echo ${MAP[$PLAYER_Y]}|rev|cut -d, -f$PLAYER_X|rev`]}.\nIn front of you $INFRONT."
				;;
				
				"${NWSE[7]}" )
				echo "Rendering, please wait..."
				RENDER_START=$(date +%s)
			
				RENDER="<!DOCTYPE html><HTML><BODY><STYLE TYPE=\"text/css\">*{margin:0;padding:0;}</STYLE><DIV ALIGN=\"center\"><TABLE CELLPADDING=\"0\" CELLSPACING=\"0\" STYLE=\"padding:0;margin:0;\">"
				for (( y=$((PLAYER_Y-3)); y<=$((PLAYER_Y+3)); y++ )); do
					RENDER+="<TR STYLE=\"padding:0;margin:0;\">"
					for (( x=$((PLAYER_X-3)); x<=$((PLAYER_X+3)); x++ )); do
						if [[ $x -ge 1 ]] && [[ $x -lt $MAP_WIDTH ]] && [[ $y -ge 1 ]] && [[ $y -lt $MAP_HEIGHT ]]; then
							compose $(echo "${MAP[$y]}"|cut -d, -f$x)
							if [[ $y == $PLAYER_Y ]] && [[ $x == $PLAYER_X ]]; then
								compose_player
							fi
						else
							IMG="<IMG WIDTH=\"32\" HEIGHT=\"32\" />";
						fi
							#mk_image ".tmp_sprite.png"
							RENDER+="<TD STYLE=\"padding:0;margin:0;\">$IMG</TD>"
					done
					RENDER+="</TR>"
				done
				RENDER+="</TABLE></DIV></BODY></HTML>"
				RENDER_END=$(date +%s)
				let 'RENDER_END=RENDER_END-RENDER_START'
				echo "Rendered in $RENDER_END s"
				(echo "$RENDER")|zenity --text-info --html --filename=/dev/stdin --width 320 --height 320
				;;
				*)
				;;
			esac
			
			#echo "$GAME_PROGRESS"
		done
		;;
		"${ACTIONS[1]}" )
		SAVE=$(zenity --file-selection --save --title "Save game")
		if [[ $? -eq 0 ]]; then
			PASSWORD=$(zenity --password --title "Encryption: $SAVE")
			echo -n "$HEAD_COLOR $BODY_COLOR $LEGS_COLOR $BOOTS_COLOR " > .game_save.tmp
			echo -n "$PLAYER_X $PLAYER_Y $DIRECTION" >> .game_save.tmp
			echo "$PASSWORD"|gpg --batch --yes -c --passphrase-fd 0 ".game_save.tmp"
			mv ".game_save.tmp.gpg" "$SAVE.gpg"
			rm .game_save.tmp
		fi
		;;
		* ) echo "?" ;;
	esac
	
done

rm .tmp_*.png