#!/bin/bash -l
set -ex

if [ $ACTION == "xcode" ]; then
  if [ -n "$DESTINATION" ]; then
    xcodebuild -UseModernBuildSystem=NO -project Valet.xcodeproj -scheme "$SCHEME" -sdk $SDK -destination "$DESTINATION" -configuration Debug -PBXBuildsContinueAfterErrors=0 $XCODE_ACTION
  else
    xcodebuild -UseModernBuildSystem=NO -project Valet.xcodeproj -scheme "$SCHEME" -sdk $SDK -configuration Debug -PBXBuildsContinueAfterErrors=0 $XCODE_ACTION
  fi
fi

if [ $ACTION == "pod-lint" ]; then
  bundle exec pod lib lint --verbose --fail-fast --swift-version=$SWIFT_VERSION
fi

if [ $ACTION == "carthage" ]; then
  carthage build --verbose --no-skip-current
fi
