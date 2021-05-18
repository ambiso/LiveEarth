#!/bin/sh

bgpath="$(realpath "$XDG_DATA_HOME/../bin/")"
echo Installing bg.sh to "$bgpath"
cp bg.sh "$bgpath"

sdpath="$XDG_DATA_HOME"/systemd/user
echo Installing systemd units "liveearth.{service,timer}" to "$sdpath"
mkdir -p "$sdpath"
cp liveearth.service liveearth.timer "$sdpath"

echo Enabling timer
systemctl enable --user liveearth.timer
systemctl start --user liveearth.timer