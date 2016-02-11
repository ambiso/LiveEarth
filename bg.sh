#!/usr/bin/env bash
set -ue
#CONFIGURATION
workdir="$HOME/.bg/" #EMPTY working directory
tiles=4 #Size of image: 1 2 4 8 16
url="http://himawari8-dl.nict.go.jp/himawari8/img/D531106/${tiles}d/550/"
delay=20
outputfile="${workdir}final.png"

#DEPENDENCIES
declare -a deps=("montage" "feh" "wget" "xargs")
for i in "${deps[@]}"; do
    which $i > /dev/null || (echo I need "$i" to work; exit 1);
done

#SCRIPT
function cleanup {
    echo "Cleanup"
    rm -f $(for((x=0;x<$tiles;x++)); do
                for((y=0;y<$tiles;y++)); do
                    echo "$workdir${x}_${y}.png"; done; done)
}

[ -d "$workdir" ] || (mkdir "$workdir" && echo "Created $workdir")

cleanup

echo "Download"
url="${url}$(TZ='GMT' date -d "$delay minutes ago" "+%G/%m/%d/%H")$(printf '%02d' $(echo -e a=$(TZ='GMT' date -d "$delay minutes ago" '+%M') '\na-a%10' | bc))00"
for((x=0;x<$tiles;x++)); do 
    for((y=0;y<$tiles;y++)); do 
        echo "${url}_${x}_${y}.png -q -O" "$workdir${x}_${y}.png"; 
    done; 
done | xargs -P 32 -n 4 wget || (echo "Failed to download images"; exit 1)

echo "Merge"
montage -tile ${tiles} -geometry +0+0 $(
    for((y=0;y<$tiles;y++)); do
        for((x=0;x<$tiles;x++)); do
            echo "$workdir${x}_${y}.png"; done; done) "${outputfile}"

cleanup

echo "Set background"
#gsettings set org.gnome.desktop.background picture-uri "file://${outputfile}"
#gsettings set org.gnome.desktop.background picture-options 'scaled'
feh --bg-max "${outputfile}"
