#!/bin/bash -l
set -ex

IFS=','; PLATFORMS=$(echo $1); unset IFS

sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes

if [[ ${PLATFORMS[*]} =~ 'iOS_12' ]]; then
	sudo ln -s /Applications/Xcode_10.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 12.4.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'iOS_11' ]]; then
	find /Applications/Xcode_9.4.1.app/Contents -iname iOS.simruntime
	find /Applications/Xcode_9.4.1.app/Contents -iname watchOS.simruntime
	find /Applications/Xcode_9.4.1.app/Contents -iname tvOS.simruntime
	sudo ln -s /Applications/Xcode_9.4.1.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 11.4.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'tvOS_12' ]]; then
	sudo ln -s /Applications/Xcode_10.3.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/tvOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/tvOS\ 12.4.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'tvOS_11' ]]; then
	sudo ln -s /Applications/Xcode_9.4.1.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/tvOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/tvOS\ 11.4.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'watchOS_5' ]]; then
	sudo ln -s /Applications/Xcode_10.3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/watchOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS\ 5.3.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'watchOS_4' ]]; then
	sudo ln -s /Applications/Xcode_9.4.1.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/watchOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS\ 4.3.simruntime
fi

xcrun simctl list runtimes
