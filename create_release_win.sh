NAME="ReaCoMa 2.0"
CLI="https://github.com/flucoma/flucoma-cli/releases/download/1.0.4/FluCoMa-CLI-Win.zip"

# Get CLI Binaries
curl -s -L "$CLI" --output cli.dmg
hdiutil attach cli.dmg
cp -a /Volumes/FluCoMa-CLI-Win/FluidCorpusManipulation/bin .
hdiutil detach /Volumes/FluCoMa-CLI-Mac
rm cli.dmg

# Create ZIP
test -f "$NAME.dmg" && rm -f "$NAME.dmg"
test -f release && rm -rf release
mkdir -p release
mkdir -p "release/$NAME"
rsync -av -q . "release/$NAME" --exclude "$NAME" --exclude "REAPER Scripts" --exclude create_release_win.sh --exclude create_release_win.sh --exclude .github --exclude release --exclude assets --exclude tests --exclude install.bat

rsync -av -q install.bat "release"

zip -r "ReaCoMa 2.0.zip" release

rm -rf release