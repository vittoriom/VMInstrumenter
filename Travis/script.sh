#!/bin/sh
set -e

xcodebuild -workspace VMInstrumenter_Sample.xcworkspace -scheme VMInstrumenter_Sample -sdk iphonesimulator6.1 -arch i386 clean build
