NAME="ReaCoMa 2.0"
CLI="https://github.com/flucoma/flucoma-cli/releases/download/1.0.4/FluCoMa-CLI-Mac.dmg"
IMGUI="https://github.com/cfillion/reaimgui/releases/download/v0.7"

# Get CLI Binaries
curl -s -L "$CLI" --output cli.dmg
hdiutil attach cli.dmg
cp -a /Volumes/FluCoMa-CLI-Mac/FluidCorpusManipulation/bin .
hdiutil detach /Volumes/FluCoMa-CLI-Mac
rm cli.dmg


# Create DMG
test -f "$NAME.dmg" && rm -f "$NAME.dmg"
test -f release && rm -rf release
mkdir -p release
mkdir -p "release/$NAME"
rsync -av -q . "release/$NAME" --exclude "$NAME" --exclude "REAPER Scripts" --exclude create_release.sh --exclude .github --exclude release --exclude assets --exclude tests

appdmg ./dmg.json ./ReaCoMa\ 2.0.dmg

# Alias(es)
# test -f "REAPER Scripts" && rm -f "REAPER Scripts"
# ln -s ~/Library/Application\ Support/REAPER/Scripts REAPER\ Scripts

rm -rf release