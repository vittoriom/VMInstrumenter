#!/bin/sh
set -e

xctool -workspace VMInstrumenter_Sample.xcworkspace -scheme VMInstrumenter_Sample -sdk iphonesimulator6.1 clean build
