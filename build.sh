#!/bin/sh
rm fakesg.love fakesg.exe fakesg.zip
zip -r fakesg.love *.lua *json
echo "Build windows exe"
cat ~/lovex/love.exe fakesg.love > fakesg.exe
echo "Zip windows exe"
cp ~/lovex/*dll .
zip fakesg.zip *dll fakesg.exe decks/*
zip images.zip swordgirlsimages/*
rm *dll
