#!/usr/bin/env ruby

require '../AO_Xcodeproj/lib/ao_xcodeproj.rb'
require 'xcodeproj'

test_cat = XcodeTestProj.new("demo/GenCov/GenCov.xcodeproj", "GenCov")
# test_dog = XcodeTestProj.new("/Users/nirinth/Catode/Training/Games/iOSGamesByTutorials/ZombieCongaRW/ZombieCongaRW.xcodeproj",
#   "ZombieCongaRW")

test_cat.add_coverage_scheme
test_cat.add_versioning_scheme
test_cat.add_coverage_script
test_cat.add_observer
test_cat.add_gcov_flush
test_cat.save_project
