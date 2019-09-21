#!/bin/bash -l
set -ex

if [ $ACTION == "swift-package" ]; then
  swift package generate-xcodeproj --output generated/
  if [ -n "$DESTINATION" ]; then
    xcodebuild -project generated/Valet.xcodeproj -scheme "Valet-Package" -sdk $SDK -destination "$DESTINATION" -configuration Release -PBXBuildsContinueAfterErrors=0 build
  else
    xcodebuild -project generated/Valet.xcodeproj -scheme "Valet-Package" -sdk $SDK -configuration Release -PBXBuildsContinueAfterErrors=0 build
  fi
fi

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
