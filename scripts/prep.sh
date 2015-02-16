#!/bin/bash
echo "Removing previous Vessel.app if it exists"
rm -rf binaries
mkdir binaries

echo "Removing Atom Icon"
rm ./binaries/Vessel.app/Contents/Resources/atom.icns

echo "Making app dir"
mkdir -p ./binaries/Vessel.app/Contents/Resources/app

echo "Removing dependency logfile"
rm -f node_modules/moment/sauce_connect.log
