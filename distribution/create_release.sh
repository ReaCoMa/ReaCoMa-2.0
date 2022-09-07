NAME="ReaCoMa 2.0"
CLI_VERSION="1.0.4"
OS="$1"

test -f release && rm -rf release
rm -rf bin

if [ "$OS" == "win" ]; then
	rm -rf FluidCorpusManipulation
	CLI="https://github.com/flucoma/flucoma-cli/releases/download/$CLI_VERSION/FluCoMa-CLI-Windows.zip"
	curl -s -L "$CLI" --output cli.zip
	unzip -q cli.zip
	mv FluidCorpusManipulation/bin .
	rm -rf FluidCorpusManipulation
	rm cli.zip

	# # Create a ZIP
	mkdir -p release
	mkdir -p "release/$NAME"
	rsync -av -q --exclude=.github --exclude=.git --exclude=assets --exclude=tests --exclude=distribution . "release/$NAME"
	cp distribution/install.bat release
	cp distribution/Quick\ Start.txt release

	zip -r ReaCoMa\ 2.0.zip release
else
	CLI="https://github.com/flucoma/flucoma-cli/releases/download/$CLI_VERSION/FluCoMa-CLI-Mac.dmg"
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