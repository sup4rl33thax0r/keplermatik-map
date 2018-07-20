./util/Merlin32 -V ./library ./src/$1.s
mv ./src/keplermatik ./build

# Add file to disk image (delete old one first)
java -jar /Applications/AppleCommander.app/Contents/Resources/Java/AppleCommander.jar -d ./build/$1.dsk $1
java -jar /Applications/AppleCommander.app/Contents/Resources/Java/AppleCommander.jar -p ./build/$1.dsk $1 bin 0x8000 < ./build/$1
# Load Disk in Emulator and run using AppleScript
osascript "./util/Virtual][Emulation.scpt"