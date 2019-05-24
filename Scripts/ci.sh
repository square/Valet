#!/bin/bash -l
set -ex

if [ $ACTION == "xcode" ]; then
  if [ -n "$DESTINATION" ]; then
    xcodebuild -project Valet.xcodeproj -scheme "$SCHEME" -sdk $SDK -destination "$DESTINATION" -configuration Debug -PBXBuildsContinueAfterErrors=0 $ACTION
  else
    xcodebuild -project Valet.xcodeproj -scheme "$SCHEME" -sdk $SDK -configuration Debug -PBXBuildsContinueAfterErrors=0 $ACTION
  fi
fi

if [ $ACTION == "pod-lint" ]; then
  bundle exec pod lib lint --verbose --fail-fast --swift-version=$SWIFT_VERSION
fi

if [ $ACTION == "carthage" ]; then
  carthage build --verbose --no-skip-current
fi
