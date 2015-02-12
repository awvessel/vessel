#!/bin/bash
CPATH=`pwd`
ZIPFILE=../vessel-$1.zip

echo "Installing dependencies"
cd binaries/Vessel.app/Contents/Resources/app
npm install --production -q . 1> /dev/null 2> /dev/null

echo "Codesign"
cd $CPATH/binaries
codesign --deep --force --verbose --sign '3rd Party Mac Developer Application: AWeber Systems' Vessel.app

cd $CPATH/binaries
if [ -e "$ZIPFILE" ]
then
  echo "Removing previous zipfile"
  rm $ZIPFILE
fi

echo "Creating zipfile"
zip -r -9 $ZIPFILE Vessel.app
