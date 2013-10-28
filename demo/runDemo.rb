#!/usr/bin/env ruby

require '../AO_Xcodeproj/lib/ao_xcodeproj.rb'
require 'xcodeproj'

test_cat = XcodeTestProj.new("demo/TestProj/TestProj.xcodeproj", "TestProj")
# test_dog = XcodeTestProj.new("/Users/nirinth/Catode/Training/Games/iOSGamesByTutorials/ZombieCongaRW/ZombieCongaRW.xcodeproj",
#   "ZombieCongaRW")


test_cat.addCoverageScheme
# test_cat.addVersioningScheme
test_cat.addCoverageScript
test_cat.saveProject
