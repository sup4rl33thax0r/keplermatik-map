#!/bin/bash        
# Add file to disk image (delete old one first)
java -jar /Applications/AppleCommander.app/Contents/Resources/Java/AppleCommander.jar -d $1.dsk $1
java -jar /Applications/AppleCommander.app/Contents/Resources/Java/AppleCommander.jar -p $1.dsk $1 bin 0x8000 < $1
# Load Disk in Emulator and run using AppleScript
osascript "Virtual][Emulation.scpt"