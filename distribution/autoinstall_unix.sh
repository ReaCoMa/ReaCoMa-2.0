#! /bin/bash

CLI_VERSION="1.0.4"
# ReaCoMa URLs
MAC="https://github.com/ReaCoMa/ReaCoMa-2.0/releases/latest/download/ReaCoMa.2.0.dmg"
NIX="https://github.com/ReaCoMa/ReaCoMa-2.0/releases/latest/download/ReaCoMa.2.0.tar.gz"
ARCH=`uname -m`
DISTRO=`uname`
REAIMGUI_VERSIONED_URL="https://github.com/cfillion/reaimgui/releases/download/v0.7"

echo "---- ReaCoMa 2.0 Installer Script ----"
echo "This installer will download ReaCoMa and ReaImGui.\nAll temporary files such as .zip will be downloaded to your user downloads folder and removed afterwards\n"

# The extension of the shared library will be determined by the DISTRO
if [ $DISTRO = "Darwin" ]
then
    REATEAM="$HOME/Library/Application Support/REAPER/Scripts/ReaTeam Extensions"
    REACOMA_LOCATION="$HOME/Library/Application Support/REAPER/Scripts"
    LIB_OUTPUT="$HOME/Library/Application Support/REAPER/UserPlugins" 
    EXT=".dylib"
    curl -sL "$MAC" --output reacoma.dmg
    hdiutil attach reacoma.dmg -quiet
    mkdir -p "$REACOMA_LOCATION"
    mkdir -p "$REATEAM"
    mkdir -p "$LIB_OUTPUT"
    rsync -av -q /Volumes/ReaCoMa/ReaCoMa\ 2.0 "$REACOMA_LOCATION"
    hdiutil detach /Volumes/ReaCoMa -quiet
    rm -rf reacoma.dmg
else
    REATEAM="$HOME/.config/REAPER/Scripts/ReaTeam Extensions"
    REACOMA_LOCATION="$HOME/.config/REAPER/Scripts"
    LIB_OUTPUT="$HOME/.config/REAPER/UserPlugins" 
    EXT=".so"
    curl -sL "$NIX" --output reacoma.tar.gz
    mkdir -p "$REACOMA_LOCATION"
    mkdir -p "$REATEAM"
    mkdir -p "$LIB_OUTPUT"
    tar -xvf reacoma.tar.gz
    rsync -av -q release/ReaCoMa\ 2.0 "$REACOMA_LOCATION"
    rm -rf reacoma.tar.gz
fi

# Download ImGui
if [ "$ARCH" = "arm64" ]
then
    echo "ARM64 Architecture Identified for ImGui"
    FILE="reaper_imgui-arm64$EXT"
fi

if [ "$ARCH" = "x86_64" ]
then
    echo "x86_64 architecture identified for ImGui"
    FILE="reaper_imgui-x86_64$EXT"
fi

CONCAT_OUTPUT="$LIB_OUTPUT/$FILE"
curl -s -L "$REAIMGUI_VERSIONED_URL/$FILE" --output "$LIB_OUTPUT/$FILE" >> /dev/null

# imgui.lua file
LUA_LOCATION="$REATEAM/API"
mkdir -p "$REATEAM" && echo "Creating ReaTeam folder"
mkdir -p "$LUA_LOCATION" && echo "Creating API folder"
curl -s -L "$REAIMGUI_VERSIONED_URL/imgui.lua" --output "$LUA_LOCATION/imgui.lua"

echo "DONE! Now run one of the scripts from REAPER"
