#!/bin/bash
echo "Removing previous Vessel.app if it exists"
rm -rf binaries
mkdir binaries

echo "Extracting Atom-Shell to binaries dir"
cp -r .atom-shell/Atom.app binaries/

echo "Copying Atom.app to Vessel.app"
cp -R binaries/Atom.app binaries/Vessel.app

echo "Renaming Atom to Vessel"
mv binaries/Vessel.app/Contents/MacOS/Atom binaries/Vessel.app/Contents/MacOS/Vessel

echo "Removing Atom Icon"
rm ./binaries/Vessel.app/Contents/Resources/atom.icns

echo "Making app dir"
mkdir -p ./binaries/Vessel.app/Contents/Resources/app
