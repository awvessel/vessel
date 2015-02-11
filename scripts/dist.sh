#!/bin/bash
CPATH=`pwd`
ZIPFILE=../vessel-$1.zip

echo "Installing dependencies"
cd binaries/Vessel.app/Contents/Resources/app
npm install --production -q . 1> /dev/null 2> /dev/null

cd $CPATH/binaries
if [ -e "$ZIPFILE" ]
then
  echo "Removing previous zipfile"
  rm $ZIPFILE
fi

echo "Creating zipfile"
zip $ZIPFILE Vessel.app
