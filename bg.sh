#!/usr/bin/env bash
set -ue
#CONFIGURATION
workdir="$HOME/.bg/" #Clobberful working directory
tiles=4 #Size of image: 1 2 4 8 16
url="http://himawari8-dl.nict.go.jp/himawari8/img/D531106/${tiles}d/550/"
delay=120 #Images are only available after a certain (varying) delay
outputfile="${workdir}final.png"

#DEPENDENCIES
declare -a deps=("montage" "wget" "xargs")
if [ "$(uname)" != "Darwin" ]; then
  deps+=("feh")
fi
for i in "${deps[@]}"; do
    which $i > /dev/null || (echo Please install "$i" for me to work; exit 1);
done

#SCRIPT
function cleanup {
    echo "Cleanup"
    rm -f $(for((x=0;x<$tiles;x++)); do
                for((y=0;y<$tiles;y++)); do
                    echo "$workdir${x}_${y}.png"; done; done)
}

echo Working directory: "${workdir}"

[ -d "$workdir" ] || (mkdir "$workdir" && echo "Created $workdir")

cleanup

echo "Download"
time="$(date +%s -d "$delay minutes ago")"
url="${url}$(TZ='GMT' date -d "@${time}" "+%G/%m/%d/%H")$(printf '%02d' $(echo -e a=$(TZ='GMT' date -d "@${time}" '+%M') '\na-a%10' | bc))00"
for((x=0;x<$tiles;x++)); do 
    for((y=0;y<$tiles;y++)); do 
        echo "${url}_${x}_${y}.png -q -O" "$workdir${x}_${y}.png"; 
    done; 
done | xargs -P 32 -n 4 wget || (echo "Failed to download images"; exit 1)

echo "Check files"
for((x=0;x<$tiles;x++)); do
    for((y=0;y<$tiles;y++)); do
        if [ $(sha512sum "$workdir${x}_${y}.png" | awk '{print $1}') == '4de86fff28860a348f5db6c8e838ca7de0d0f82acce8c9087734d97d287e806142caf3fe93ed0ecf6e998ff30701a077adc01927c07accd43b0b9e1ca26ebc34' ]; then #Hash of "No image"-image
            echo "At least one image empty; aborting"
            exit 1
        fi
    done
done

echo "Merge"
montage -tile ${tiles} -geometry +0+0 $(
    for((y=0;y<$tiles;y++)); do
        for((x=0;x<$tiles;x++)); do
            echo "$workdir${x}_${y}.png"; done; done) "${outputfile}"

cleanup

echo "Set background"
#gsettings set org.gnome.desktop.background picture-uri "file://${outputfile}"
#gsettings set org.gnome.desktop.background picture-options 'scaled'
if [ "$(uname)" == "Darwin" ]; then
  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"${outputfile}\""
else
  feh --bg-max "${outputfile}"
fi
