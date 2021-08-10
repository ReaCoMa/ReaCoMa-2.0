#!/bin/sh
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED='\033[0;31m'
BRORANGE='\033[0:33m'
YELLOW='\033[1:33m'

NC='\033[0m' # No Color

echo "$BOLD---- ReaCoMa 2.0 Installer Script ----$NORMAL"
echo "This installer will download ReaCoMa, ReaImGui and the FluCoMa Command-Line Executables. All temporary files such as .zip will be downloaded to your user downloads folder and removed afterwards"

REACOMA_LOCATION="$HOME/Library/Application\ Support/REAPER/Scripts/ReaCoMa-2.0"
# Download ReaCoMa to the UserScripts place
if [ -d "$REACOMA_LOCATION" ]
then
    rm -r $REACOMA_LOCATION
fi
echo "$BOLD---- Downloading ReaCoMa ----$NORMAL"
git clone https://github.com/ReaCoMa/ReaCoMa-2.0.git "$REACOMA_LOCATION" >> /dev/null

# Get ImGui
echo "$BOLD---- Installing ImGui ----$NORMAL"
ARCH=`uname -m`
DISTRO=`uname`
DYLIB_OUTPUT="$HOME/Library/Application Support/REAPER/UserPlugins" 
REAIMGUI_VERSIONED_URL="https://github.com/cfillion/reaimgui/releases/download/v0.5.4"

if [ $ARCH == "arm64" ]
then
    echo "$BRORANGE\nINFO: ARM64 Architecture Identified$NC"
    FILE="reaper_imgui-arm64.dylib"
fi

if [ $ARCH == "X86_64" ]
then
    echo "$BRORANGE\nINFO: X86_64 architecture identified$NC"
    FILE="reaper_imgui-x86_64.dylib"
fi

if [ $ARCH == "i386" ]
then
    echo "$BRORANGE\nINFO: Running ARM64 in Rosetta possibly...$NC"
    FILE="reaper_imgui-i386.dylib"
fi

CONCAT_OUTPUT="$DYLIB_OUTPUT/$FILE"
curl -s -L "$REAIMGUI_VERSIONED_URL/$FILE" --output "$DYLIB_OUTPUT/$FILE" >> /dev/null

# Get FluCoMa CLI Tools
echo "$BOLD---- Downloading FluCoMa Command-Line Tools ----$NORMAL"
if [ $DISTRO == "Darwin" ]; then
    FLUCOMA_RELEASE="https://github.com/flucoma/flucoma-cli/releases/download/1.0.0.RC1b/FluCoMa-CLI-Mac-RC1b.zip"
fi

ZIP_LOCATION="$HOME/Downloads/flucoma-cli.zip"
curl -s -L $FLUCOMA_RELEASE --output $ZIP_LOCATION
unzip -o -q "$HOME/Downloads/flucoma-cli.zip" -d "$HOME/Downloads/"
mkdir -p "/usr/local/bin/flucoma-cli"
cp -r "$HOME/Downloads/FluidCorpusManipulation/bin/" "/usr/local/bin/flucoma-cli/"
echo "$BRORANGE\nINFO: Executables copied to /usr/local/bin/flucoma-cli$NC"

echo "$BOLD---- ReaCoMA has been installed! ----$NORMAL"
echo "$BRORANGE\nINFO: Cleaning Up Files...$NC"
rm -r $ZIP_LOCATION
rm -r "$HOME/Downloads/FluidCorpusManipulation"

echo "$RED\nDONE! Now run one of the scripts from REAPER"
