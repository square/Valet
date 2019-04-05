#!/bin/bash -l
set -ex

if [ -n "$DESTINATION" ]; then
  xcodebuild -project Valet.xcodeproj -scheme "$SCHEME" -sdk $SDK -destination "$DESTINATION" -configuration Debug -PBXBuildsContinueAfterErrors=0 $ACTION
else
  xcodebuild -project Valet.xcodeproj -scheme "$SCHEME" -sdk $SDK -configuration Debug -PBXBuildsContinueAfterErrors=0 $ACTION
fi
