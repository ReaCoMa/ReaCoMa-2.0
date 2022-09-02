#!/bin/sh

echo "---- ReaCoMa 2.0 Installer Script ----"
echo "This installer will download ReaCoMa, ReaImGui and the FluCoMa CLI Executables.\nAll temporary files such as .zip will be downloaded to your user downloads folder and removed afterwards\n"

ARCH=`uname -m`
DISTRO=`uname`
REAIMGUI_VERSIONED_URL="https://github.com/cfillion/reaimgui/releases/download/v0.7"

# The extension of the shared library will be determined by the DISTRO
if [ $DISTRO == "Darwin" ]
then
    REATEAM="$HOME/Library/Application Support/REAPER/Scripts/ReaTeam Extensions"
    LUA_LOCATION="$REATEAM/API"
    REACOMA_LOCATION="$HOME/Library/Application Support/REAPER/Scripts/ReaCoMa-2.0"
    DYLIB_OUTPUT="$HOME/Library/Application Support/REAPER/UserPlugins" 
    EXT=".dylib"
else
    REATEAM="$HOME/.config/REAPER/Scripts/ReaTeam Extensions"
    LUA_LOCATION="$REATEAM/API"
    REACOMA_LOCATION="$HOME/.config/REAPER/Scripts/ReaCoMa-2.0"
    DYLIB_OUTPUT="$HOME/.config/REAPER/UserPlugins" 
    EXT=".so"
fi

echo "$LUA_LOCATION"

# Download ReaCoMa to the UserScripts place
if [ -d "$REACOMA_LOCATION" ]
then
    cd "$REACOMA_LOCATION" && git pull > /dev/null 2>&1
    echo "1. ReaCoMa exists at '$REACOMA_LOCATION' so invoked git pull"
else
    git clone https://github.com/ReaCoMa/ReaCoMa-2.0.git "$REACOMA_LOCATION" > /dev/null 2>&1
    echo "1. ReaCoMa downloaded to '$REACOMA_LOCATION'"
fi

# Download ImGui
if [ "$ARCH" == "arm64" ]
then
    echo "2. ARM64 Architecture Identified for ImGui"
    FILE="reaper_imgui-arm64$EXT"
fi

if [ "$ARCH" == "x86_64" ]
then
    echo "2. x86_64 architecture identified for ImGui"
    FILE="reaper_imgui-x86_64$EXT"
fi

CONCAT_OUTPUT="$DYLIB_OUTPUT/$FILE"
curl -s -L "$REAIMGUI_VERSIONED_URL/$FILE" --output "$DYLIB_OUTPUT/$FILE" >> /dev/null

# imgui.lua file
mkdir -p "$REATEAM" && echo "Creating ReaTeam folder"
mkdir -p "$LUA_LOCATION" && echo "Creating API folder"
curl -s -L "$REAIMGUI_VERSIONED_URL/imgui.lua" --output "$LUA_LOCATION/imgui.lua"

# Get FluCoMa CLI Tools
if [ "$DISTRO" == "Darwin" ]
then
    FLUCOMA_RELEASE='https://github.com/flucoma/flucoma-cli/releases/download/1.0.2/FluCoMa-CLI-Mac.dmg'
else
    FLUCOMA_RELEASE='https://github.com/flucoma/flucoma-cli/releases/download/1.0.2/FluCoMa-CLI-Linux.tar.gz'
fi

# make the folder for the binaries
BINARY_LOCATION="$REACOMA_LOCATION"
mkdir -p "$BINARY_LOCATION"

if [ "$DISTRO" == "Darwin" ]
then
    ZIP_LOCATION="$HOME/Downloads/flucoma-cli.dmg"
    curl -s -L "$FLUCOMA_RELEASE" --output "$ZIP_LOCATION"
    hdiutil attach "$ZIP_LOCATION"
    echo "3. Executables copied to $BINARY_LOCATION"
    cp -a /Volumes/FluCoMa-CLI-Mac/FluidCorpusManipulation/bin "$BINARY_LOCATION"
    echo "4. Cleaning Up Files..."
    hdiutil detach /Volumes/FluCoMa-CLI-Mac
else
    ZIP_LOCATION="$HOME/Downloads/flucoma-cli.tar.gz"
    curl -s -L "$FLUCOMA_RELEASE" --output "$ZIP_LOCATION"
    tar -xvf "$ZIP_LOCATION"
    echo "3. Executables copied to $BINARY_LOCATION"
    cp -a "$HOME/Downloads/FluidCorpusManipulation/bin" "$BINARY_LOCATION"
    echo "4. Cleaning Up Files..."
    rm -rf "$ZIP_LOCATION"
fi

echo "DONE! Now run one of the scripts from REAPER"
