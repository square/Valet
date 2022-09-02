#!/bin/bash -l
set -ex

IFS=','; PLATFORMS=$(echo $1); unset IFS

sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes

if [[ ${PLATFORMS[*]} =~ 'iOS_13' ]]; then
	sudo ln -s /Applications/Xcode_11.7.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 13.7.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'tvOS_13' ]]; then
	sudo ln -s /Applications/Xcode_11.7.app/Contents/Developer/Platforms/AppleTVOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/tvOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/tvOS\ 13.4.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'watchOS_6' ]]; then
	sudo ln -s /Applications/Xcode_11.7.app/Contents/Developer/Platforms/WatchOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS\ 6.2.simruntime
fi

xcrun simctl list runtimes
