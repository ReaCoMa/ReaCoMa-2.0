#!/bin/sh
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED='\033[0;31m'
BRORANGE='\033[0:33m'
YELLOW='\033[1:33m'

NC='\033[0m' # No Color

echo "$BOLD---- ReaCoMa 2.0 Installer Script ----$NORMAL"
echo "This installer will download ReaCoMa, ReaImGui and the FluCoMa CLI Executables.\nAll temporary files such as .zip will be downloaded to your user downloads folder and removed afterwards\n"

ARCH=`uname -m`
DISTRO=`uname`
REAIMGUI_VERSIONED_URL="https://github.com/cfillion/reaimgui/releases/download/v0.5.4"

# The extension of the shared library will be determined by the DISTRO
if [ $DISTRO == "Darwin" ]
then
    REACOMA_LOCATION="$HOME/Library/ApplicationSupport/REAPER/Scripts/ReaCoMa-2.0"
    DYLIB_OUTPUT="$HOME/Library/ApplicationSupport/REAPER/UserPlugins" 
    EXT=".dylib"
else
    REACOMA_LOCATION="$HOME/.config/REAPER/Scripts/ReaCoMa-2.0"
    DYLIB_OUTPUT="$HOME/.config/REAPER/UserPlugins" 
    EXT=".so"
fi

# Download ReaCoMa to the UserScripts place
if [ -d "$REACOMA_LOCATION" ]
then
    cd $REACOMA_LOCATION && git pull > /dev/null 2>&1
    echo "$BRORANGE\n1. ReaCoMa exists at $REACOMA_LOCATION so invoked git pull"
else
    git clone https://github.com/ReaCoMa/ReaCoMa-2.0.git "$REACOMA_LOCATION" > /dev/null 2>&1
    echo "$BRORANGE\n1. ReaCoMa downloaded to $REACOMA_LOCATION"
fi


if [ $ARCH == "arm64" ]
then
    echo "$BRORANGE\n2. ARM64 Architecture Identified for ImGui$NC"
    FILE="reaper_imgui-arm64$EXT"
fi

if [ $ARCH == "x86_64" ]
then
    echo "$BRORANGE\n2. x86_64 architecture identified for ImGui$NC"
    FILE="reaper_imgui-x86_64$EXT"
fi

CONCAT_OUTPUT="$DYLIB_OUTPUT/$FILE"
curl -s -L "$REAIMGUI_VERSIONED_URL/$FILE" --output "$DYLIB_OUTPUT/$FILE" >> /dev/null

# Get FluCoMa CLI Tools
if [ $DISTRO == "Darwin" ]
then
    FLUCOMA_RELEASE="https://github.com/flucoma/flucoma-cli/releases/download/1.0.0.RC1b/FluCoMa-CLI-Mac-RC1b.zip"
else
    FLUCOMA_RELEASE="https://github.com/flucoma/flucoma-cli/releases/download/1.0.0.RC1b/FluCoMa-CLI-Linux-RC1b.zip"
fi

ZIP_LOCATION="$HOME/Downloads/flucoma-cli.zip"
curl -s -L $FLUCOMA_RELEASE --output $ZIP_LOCATION
unzip -o -q "$HOME/Downloads/flucoma-cli.zip" -d "$HOME/Downloads/"
mkdir -p "/opt/flucoma-cli"
cp -r "$HOME/Downloads/FluidCorpusManipulation/bin/" "/usr/local/bin/flucoma-cli/"
echo "$BRORANGE\n3. Executables copied to /usr/local/bin/flucoma-cli$NC"

echo "$BRORANGE\n4. Cleaning Up Files...$NC"
rm -r $ZIP_LOCATION
rm -r "$HOME/Downloads/FluidCorpusManipulation"

echo "$RED\nDONE! Now run one of the scripts from REAPER"
