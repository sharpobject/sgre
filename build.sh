#!/bin/sh
rm fakesg.love fakesg.exe fakesg.zip
rm code.dat
rm assets.dat
rm swordgirlsimages.dat
cp main.lua main_again.lua
zip -r code.dat ssl/*.lua *.lua *.json loveframes
zip -r assets.dat sg_assets
zip -r swordgirlsimages.dat swordgirlsimages/300249L.jpg swordgirlsimages/200099L.jpg swordgirlsimages/200033L.jpg
cd dist_client
rm dist_client.zip
zip -r dist_client.zip *lua version.dat ssl/*lua
cd ..
cd windows
rm fakesg_windows.zip fakesg.exe
cat love.exe ../dist_client/dist_client.zip > fakesg.exe
zip -r fakesg_windows.zip fakesg.exe *dll 
cd ..
#zip -r fakesg.love ssl/*lua *.lua *json loveframes sg_assets swordgirlsimages/300249L.jpg swordgirlsimages/200099L.jpg swordgirlsimages/200033L.jpg
#echo "Build windows exe"
#cat ~/lovex/win32/love.exe fakesg.love > fakesg.exe
#echo "Zip windows exe"
#cp ~/lovex/win32/*dll .
#zip fakesg.zip *dll fakesg.exe decks/* swordgirlsimages/*
# zip images.zip swordgirlsimages/*
rm main_again.lua
