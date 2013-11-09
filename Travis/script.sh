#!/bin/sh
set -e

xctool -workspace VMInstrumenter_Sample.xcworkspace -scheme VMInstrumenter_Sample build test
