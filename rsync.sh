#!/bin/bash

# iOS Simulator rsync script
# xcrun simctl list | grep Booted
# xcrun simctl get_app_container <simulator ID> com.apple.DocumentsApp groups

rsync $HOME/Downloads/$1 "$HOME/Library/Developer/CoreSimulator/Devices/546F0EBB-4B21-40A1-9ADD-17E665412036/data/Containers/Shared/AppGroup/DCF4A39E-5137-42C6-9144-38348376BC99/File Provider Storage/$1"
