NAME="ReaCoMa 2.0"
CLI="https://github.com/flucoma/flucoma-cli/releases/download/1.0.4/FluCoMa-CLI-Mac.dmg"

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
rsync -av -q .. "release/$NAME" --exclude .github --exclude release --exclude assets --exclude tests --exclude install.bat

appdmg dmg.json "$NAME.dmg"

rm -rf release