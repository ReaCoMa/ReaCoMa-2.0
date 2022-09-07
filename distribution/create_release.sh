NAME="ReaCoMa 2.0"
CLI="https://github.com/flucoma/flucoma-cli/releases/download/1.0.4/FluCoMa-CLI-Mac.dmg"
OS="$1"

test -f release && rm -rf release

if [ "$OS" == "win" ]; then

fi

if [ "$OS" == "mac"]; then
	# Get CLI Binaries
	curl -s -L "$CLI" --output cli.dmg
	hdiutil attach cli.dmg
	cp -a /Volumes/FluCoMa-CLI-Mac/FluidCorpusManipulation/bin .
	hdiutil detach /Volumes/FluCoMa-CLI-Mac
	rm cli.dmg

	# Create DMG
	test -f "$NAME.dmg" && rm -f "$NAME.dmg"
	mkdir -p release
	mkdir -p "release/$NAME"
	rsync -av -q --exclude=.github --exclude=.git --exclude=assets --exclude=tests --exclude=distribution . "release/$NAME"

	appdmg distribution/dmg.json "$NAME.dmg"
fi

rm -rf release