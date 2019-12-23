#!/bin/bash -l
set -ex

# Find the directory in which this script resides.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $ACTION == "swift-package" ]; then
  $DIR/build.swift $PLATFORMS spm
fi

if [ $ACTION == "xcode" ]; then
  $DIR/build.swift $PLATFORMS xcode
fi

if [ $ACTION == "pod-lint" ]; then
  bundle exec pod lib lint --verbose --fail-fast --swift-version=$SWIFT_VERSION
fi

if [ $ACTION == "carthage" ]; then
  carthage build --verbose --no-skip-current
fi
