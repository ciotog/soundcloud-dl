#!/bin/bash
#Author: Source Team 
#Member : FlyinGrub 

echo ''
echo ' *----------------------------------------------------------------------------*'
echo '|      SoundcloudMusicDownloader(cURL/Wget version) |  Team SourcE rework      |'
echo ' *----------------------------------------------------------------------------*'

function downsong() { #Done!
	# Grab Info
	echo "[i] Grabbing song page"
    if $curlinstalled; then
        page=$(curl -s -L --user-agent 'Mozilla/5.0' "$url")
    else
        page=$(wget --max-redirect=1000 --trust-server-names --progress=bar -U -O- 'Mozilla/5.0' "$url")
    fi
    id=$(echo "$page" | grep -v "small" | grep -oE "data-sc-track=.[0-9]*" | grep -oE "[0-9]*" | sort | uniq)
    title=$(echo "$page" | grep -A1 "<em itemprop=\"name\">" | tail -n1 | sed 's/\\u0026/\&/g' | recode html..ascii)
    filename=$(echo "$title".mp3 | tr '/' '\\' | tr '*' '+')
    songurl=$(curl -s -L --user-agent 'Mozilla/5.0' "https://api.sndcdn.com/i1/tracks/$id/streams?client_id=$clientID" | cut -d '"' -f 4 | sed 's/\\u0026/\&/g')
	#artist=$(echo "$page" | grep byArtist | sed 's/.*itemprop="name">\([^<]*\)<.*/\1/g')
    # DL
		if [ -e "$filename" ]; then
		echo "[!] The song $filename has already been downloaded..."  && exit
	else
		echo "[-] Downloading $title..."
	fi
	if $curlinstalled; then
		curl -# -C  -L --user-agent 'Mozilla/5.0' -o "$filename" "$songurl";
	else
		wget -c --max-redirect=1000 --trust-server-names -U 'Mozilla/5.0' -O "$filename" "$songurl";
	fi
	echo "[i] Downloading of $filename finished."
	echo ''
}

function downallsongs() { #Done!
	# Grab Info
	echo "[i] Grabbing artists page"
	if $curlinstalled; then
		page=$(curl -L -s --user-agent 'Mozilla/5.0' $url)
	else
		page=$(wget --max-redirect=1000 --trust-server-names -q -U 'Mozilla/5.0' $url)
	fi
	clientID=$(echo "$page" | grep "clientID" | tr "," "\n" | grep "clientID" | cut -d '"' -f 4)
	artistID=$(echo "$page" | tr "," "\n" | grep "trackOwnerId" | head -n 1 | cut -d ":" -f 2) 
	echo "[i] Grabbing all song info"
	if $curlinstalled; then
		songs=$(curl -s -L --user-agent 'Mozilla/5.0' "https://api.sndcdn.com/e1/users/$artistID/sounds?limit=256&offset=0&linked_partitioning=1&client_id=$clientID" | tr -d "\n" | sed 's/<stream-item>/\n/g' | sed '1d')
	else 
		songs=$(wget -q --max-redirect=1000 --trust-server-names -O- -U 'Mozilla/5.0' "https://api.sndcdn.com/e1/users/$artistID/sounds?limit=256&offset=0&linked_partitioning=1&client_id=$clientID" | tr -d "\n" | sed 's/<stream-item>/\n/g' | sed '1d')
	fi
	songcount=$(echo "$songs" | wc -l)
	echo "[i] Found $songcount songs! (200 is max)"
	if [ -z "$songs" ]; then
		echo "[!] No songs found at $1" && exit
	fi
	# DL
	echo ""
	for (( i=1; i <= $songcount; i++ ))
	do	
		title=$(echo "$songs" | sed -n "$i"p | tr ">" "\n" | grep "</title" | cut -d "<" -f 1)
		filename=$(echo "$title".mp3 | tr '/' '\\' | tr '*' '+')
		if [ -e "$filename" ]; then
			echo "[!] The song $filename has already been downloaded..."  && exit
		else
			echo "[-] Downloading $title..."
		fi
		songID=$(echo "$songs" | sed -n "$i"p | tr " " "\n" | grep "</id>" | head -n 1 | cut -d ">" -f 2 | cut -d "<" -f 1)
		if $curlinstalled; then
			songurl=$(curl -s -L --user-agent 'Mozilla/5.0' "https://api.sndcdn.com/i1/tracks/$songID/streams?client_id=$clientID" | cut -d '"' -f 4 | sed 's/\\u0026/\&/g')
		else
			songurl=$(wget -q --max-redirect=1000 --trust-server-names -O- -U 'Mozilla/5.0' "https://api.sndcdn.com/i1/tracks/$songID/streams?client_id=$clientID" | cut -d '"' -f 4 | sed 's/\\u0026/\&/g')
		fi
		if $curlinstalled; then
			curl -C -# -L --user-agent 'Mozilla/5.0' -o "$filename" "$songurl";
		else
			wget -c --max-redirect=1000 --trust-server-names -U 'Mozilla/5.0' -O "$filename" "$songurl";
		fi
		echo "[i] Downloading of $filename finished."
		echo ''
	done
}

function downset() {  #done!
	# Grab Info
	echo "[i] Grabbing set page"
    url="$url"
    if $curlinstalled; then
		page=$(curl -L -s --user-agent 'Mozilla/5.0' $url)
    else
        page=$(wget --max-redirect=1000 --trust-server-names --progress=bar -U -O- 'Mozilla/5.0' "$url")
    fi
    settitle=$(echo "$page" | grep -A1 "<em itemprop=\"name\">" | tail -n1 | recode -q html..ascii) &>/dev/null
    songs=$(echo "$page" | grep -oE "data-sc-track=.[0-9]*" | grep -oE "[0-9]*" | sort | uniq) &>/dev/null
    echo "[i] Found set "$settitle""

    if [ -z "$songs" ]; then
        echo "[!] No songs found"
        exit 1
    fi
    songcount=$(echo "$songs" | wc -l)
    echo "[i] Found $songcount songs"
	# DL
    for (( numcursong=1; numcursong <= $songcount; numcursong++ ))
    do
        id=$(echo "$songs" | sed -n "$numcursong"p)
        title=$(echo "$page" | grep data-sc-track | grep $id | grep -oE 'rel=.nofollow.>[^<]*' | sed 's/rel="nofollow">//' | sed 's/\\u0026/\&/g' | recode html..ascii) &>/dev/null
        if [[ "$title" == "Play" ]] ; then
            title=$(echo "$page" | grep $id | grep id | grep -oE "\"title\":\"[^\"]*" | sed 's/"title":"//' | sed 's/\\u0026/\&/g' | recode html..ascii)
        fi
		#artist=$(echo "$page" | grep -A3 $id | grep byArtist | cut -d"\"" -f2)
        filename=$(echo "$title".mp3 | tr '/' '\\')
        		if [ -e "$filename" ]; then
			echo "[!] The song $filename has already been downloaded..."  && exit
		else
			echo "[-] Downloading $title..."
		fi
        if $curlinstalled; then
            songurl=$(curl -s -L --user-agent 'Mozilla/5.0' "https://api.sndcdn.com/i1/tracks/$id/streams?client_id=$clientID" | cut -d '"' -f 4 | sed 's/\\u0026/\&/g')
        else
            songurl=$(wget -q --max-redirect=1000 --trust-server-names -U -O- 'Mozilla/5.0' "https://api.sndcdn.com/i1/tracks/$id/streams?client_id=$clientID" | cut -d '"' -f 4 | sed 's/\\u0026/\&/g')
        fi
		if $curlinstalled; then
			curl -C -# -L --user-agent 'Mozilla/5.0' -o "$filename" "$songurl";
		else
			wget -c --max-redirect=1000 --trust-server-names -U 'Mozilla/5.0' -O "$filename" "$songurl";
		fi
		echo "[i] Downloading of $filename finished."
		echo ''
    done
}

function downallsets() { 
    allsetsurl="$url"
    echo "   [i] Grabbing user sets page"
    if $curlinstalled; then
        allsetspage=$(curl -L -s --user-agent 'Mozilla/5.0' "$allsetsurl")
    else
        allsetspage=$(wget --max-redirect=1000 --trust-server-names --progress=bar -U -O- 'Mozilla/5.0' "$allsetsurl")
    fi
    allsetsnumpages=$(countpages "$allsetspage")
    echo "   [i] $allsetsnumpages user sets pages found"
    for (( allsetsnumcurpage=1; allsetsnumcurpage <= $allsetsnumpages; allsetsnumcurpage++ )) ; do
        if [ "$allsetsnumcurpage" != "1" ]; then
            echo "   [i] Grabbing user sets page $allsetsnumcurpage"
            if $curlinstalled; then
                allsetspage=$(curl -L --user-agent 'Mozilla/5.0' "$allsetsurl?page=$allsetsnumcurpage")
            else
                allsetspage=$(wget --max-redirect=1000 --trust-server-names --progress=bar -U -O- 'Mozilla/5.0' "$allsetsurl?page=$allsetsnumcurpage")
            fi
        fi

        allsetssets=$(echo "$allsetspage" | grep -A1 "li class=\"set\"" | grep "<h3>" | sed 's/.*href="\([^"]*\)">.*/\1/g')

        if [ -z "$allsetssets" ]; then
            echo "   [!] No sets found on user sets page $allsetsnumcurpage"
            continue
        fi

        allsetssetscount=$(echo "$allsetssets" | wc -l)
        echo "[i] Found $allsetssetscount set(s) on user sets page $allsetsnumcurpage"

        for (( allsetsnumcurset=1; allsetsnumcurset <= $allsetssetscount; allsetsnumcurset++ ))
        do
            allsetsseturl=$(echo "$allsetssets" | sed -n "$allsetsnumcurset"p)
            echo "[i] Grabbing set $allsetsnumcurset page"
            downset "http://soundcloud.com$allsetsseturl"
        done
    done
}

function show_help() {
    echo ""
    echo "[i] Usage: `basename $0` [url]"
    echo "    With url like :"
    echo "        http://soundcloud.com/user (Download all of one user's songs)"
    echo "        http://soundcloud.com/user/song-name (Download one single song)"
    echo "        http://soundcloud.com/user/sets (Download all of one user's sets)"
    echo "        http://soundcloud.com/user/sets/set-name (Download one single set)"
    echo ""
    echo "   Downloaded file names like : "title.mp3""
    echo ""
}

if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
    show_help
    exit 1
fi

curlinstalled=`command -V curl &>/dev/null`
wgetinstalled=`command -V wget &>/dev/null`
if $curlinstalled; then
  echo "[i] Using" `curl -V` | cut -c-21
elif $wgetinstalled; then
  echo "[i] Using" `wget -V` "cURL is prefered" | cut -c-24
else
  echo "[!] cURL or Wget need to be installed."; exit 1;
fi
command -v recode &>/dev/null || { echo "[!] Recode needs to be installed."; exit 1; }

url=$(echo "$1" | sed 's-.*soundcloud.com/-http://soundcloud.com/-' | cut -d "?" -f 1)
echo "[i] Using URL $url"

clientID="b45b1aa10f1ac2941910a7f0d10f8e28"

if [[ "$(echo "$url" | cut -d "/" -f 4)" == "" ]] ; then
    echo "[!] Bad URL!"
    show_help
    exit 1
elif [[ "$(echo "$url" | cut -d "/" -f 5)" == "" ]] ; then
    echo "[i] Detected download type : All of one user's songs"
    downallsongs 
elif [[ "$(echo "$url" | cut -d "/" -f 5)" == "sets" ]] && [[ "$(echo "$url" | cut -d "/" -f 6)" == "" ]] ; then
    echo "[i] Detected download type : All of one user's sets"
    downallsets 
elif [[ "$(echo "$url" | cut -d "/" -f 5)" == "sets" ]] ; then
    echo "[i] Detected download type : One single set"
    downset
else
    echo "[i] Detected download type : One single song"
    downsong
fi
