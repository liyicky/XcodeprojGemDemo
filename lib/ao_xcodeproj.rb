#!/usr/bin/env ruby

require 'xcodeproj'
require 'debugger'
require '../AO_Xcodeproj/lib/ao_xcodeproj/ao_scheme'


class XcodeTestProj

  attr_accessor :project
  attr_accessor :project_name
  attr_accessor :project_path
  attr_accessor :root_path
  attr_accessor :coverage_script

  def initialize(project_path=nil, project_name=nil)
    @project_path = project_path
    @project_name = project_name

    if @project_path[".xcodeproj"] == nil
      @root_path  = @project_path
    elsif @project_path[".xcodeproj"] != nil then
      @root_path  = File.expand_path("..", @project_path)
    end

    self.openProject

  end

  def openProject

    #Creates a new Xcodeproj
    if (@project_path.nil?)
      print "Enter a path for a new Xcodeproj: "
      @root_path = gets.strip.to_s()
      @project_path = @root_path + "/#{@project_name}.xcodeproj"
      @project = Xcodeproj::Project.new(@project_path)
      @project.new_target(:application, 'Xcode', :ios)
      @main_target = @project.targets.find { |target| target.name == "Main"}
      @test_target = @project.targets.find { |target| target.name == "#{@project_name}Test" }

    #Opens existing Xcodeproj
    elsif (@project_path.include? ".xcodeproj")
      @project = Xcodeproj::Project::open(@project_path)
      @main_target = @project.targets.find { |target| target.name == @project_name}
      @test_target = @project.targets.find { |target| target.name == "#{@project_name}Tests" }
      puts "Opened #{@project_name} : #{@main_target.uuid}"

    #Creates a new Xcodeproj in the root dir
    else
      @project_path = @project_path + "/#{@project_name}.xcodeproj"
      @project = Xcodeproj::Project.new(@project_path)
      @project.new_target(:application, 'Main', :ios)
      @project.new_target(:bundle, 'Test', :ios)
      @main_target = @project.targets.find { |target| target.name == "Main"}
      @test_target = @project.targets.find { |target| target.name == "Test"}
    end
  end

  def addTestTargets
    @project.new_target(:bundle, "Coverage", :ios)
    @project.new_target(:bundle, "TestFlight", :ios)
  end

  def addCoverageScheme(coverage_script=nil)
    @coverage_script = coverage_script
    @coverage_script = "/bin/sh ${SRCROOT}/bin/coverage.sh" if (@coverage_script.nil?)
    @coverage_scheme = Xcodeproj::XCScheme.new

    coverage_build_settings = { "ALWAYS_SEARCH_USER_PATHS"=>"NO", "CLANG_CXX_LANGUAGE_STANDARD"=>"gnu++0x", "CLANG_CXX_LIBRARY"=>"libc++", "CLANG_ENABLE_OBJC_ARC"=>"YES", "CLANG_WARN_BOOL_CONVERSION"=>"YES", "CLANG_WARN_CONSTANT_CONVERSION"=>"YES", "CLANG_WARN_DIRECT_OBJC_ISA_USAGE"=>"YES_ERROR", "CLANG_WARN_EMPTY_BODY"=>"YES", "CLANG_WARN_ENUM_CONVERSION"=>"YES", "CLANG_WARN_INT_CONVERSION"=>"YES", "CLANG_WARN_OBJC_ROOT_CLASS"=>"YES_ERROR", "CLANG_ENABLE_MODULES"=>"YES", "GCC_C_LANGUAGE_STANDARD"=>"gnu99", "GCC_WARN_64_TO_32_BIT_CONVERSION"=>"YES", "GCC_WARN_ABOUT_RETURN_TYPE"=>"YES_ERROR", "GCC_WARN_UNDECLARED_SELECTOR"=>"YES", "GCC_WARN_UNINITIALIZED_AUTOS"=>"YES", "GCC_WARN_UNUSED_FUNCTION"=>"YES", "GCC_WARN_UNUSED_VARIABLE"=>"YES", "ONLY_ACTIVE_ARCH"=>"YES", "COPY_PHASE_STRIP"=>"YES", "GCC_DYNAMIC_NO_PIC"=>"NO", "GCC_OPTIMIZATION_LEVEL"=>"0", "GCC_SYMBOLS_PRIVATE_EXTERN"=>"NO", "GCC_GENERATE_TEST_COVERAGE_FILES"=>"YES", "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"=>"YES", "SDKROOT"=>"iphoneos", "IPHONEOS_DEPLOYMENT_TARGET"=>"7.0", "ARCHS"=>"$(ARCHS_STANDARD_INCLUDING_64_BIT)", "TEST_HOST"=>"$(BUNDLE_LOADER)", "WRAPPER_EXTENSION"=>"xctest", "GCC_PREFIX_HEADER"=>"#{@main_target.name }/#{@main_target.name}-Prefix.pch", "GCC_PRECOMPILE_PREFIX_HEADER"=>"YES", "INFOPLIST_FILE"=>"#{@test_target.name }/#{@test_target.name}-Info.plist", "VERSIONING_SYSTEM"=>"apple-generic", "PRODUCT_NAME"=>"$(TARGET_NAME)", "VALIDATE_PRODUCT"=>"NO", "ENABLE_NS_ASSERTIONS"=>"YES", "ONLY_ACTIVE_ARCH"=>"YES",  }


    @project.add_build_configuration("Coverage", :debug)
    @project.build_settings("Coverage")["FRAMEWORK_SEARCH_PATHS"] = ["$(SDKROOT)/Developer/Library/Frameworks", "$(inherited)", "$(DEVELOPER_FRAMEWORKS_DIR)"]
    @project.build_settings("Coverage")["GCC_PREPROCESSOR_DEFINITIONS"] = ["DEBUG=1", "COVERAGE=1"]
    @project.build_settings("Coverage")["OTHER_CFLAGS\[arch=*\]"] = ["-fprofile-arcs", "-ftest-coverage"]
    #@project.build_settings("Coverage")["BUNDLE_LOADER"] = "$(BUILT_PRODUCTS_DIR)/#{@main_target.name}.app/#{@main_target.name}"
    for i in coverage_build_settings
      key   = i[0]
      value = i[1]
      @project.build_settings("Coverage")["#{key}"] = "#{value}"
    end

    #puts @project.build_configuration_list.build_settings("Debug")

    buildCoverage = AO_scheme.new(@coverage_scheme, @main_target, @test_target, "Coverage")
    buildCoverage.add_target
    buildCoverage.test_action(@coverage_script)
    buildCoverage.launch_action
    buildCoverage.profile_action
    buildCoverage.save(@project_path, "Coverage")

  end

  def addCoverageScript
    @project.save
    bin_path = "#{@root_path}/bin"
    Dir.mkdir(bin_path) unless File.exist?(bin_path)

    input = "COV_PATH=${SRCROOT}/Coverage\nCOV_INFO=${COV_PATH}/Coverage.info\nOBJ_ARCH_PATH=${OBJECT_FILE_DIR}-normal/${VALID_ARCHS}\n\nmkdir -p ${COV_PATH}\n/usr/bin/env lcov --capture -b ${SRCROOT} -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"/Applications/Xcode5-DP6.app/*\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"main.m\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n\n/usr/bin/env genhtml --output-directory ${COV_PATH} ${COV_INFO}\n"

    script = File.new("#{bin_path}/coverage.sh", "w+")
    script.write(input)

  end

  def addVersioningScheme
    @versioning_scheme = Xcodeproj::XCScheme.new
    @versioning_scheme.add_build_target(@main_target)
    @versioning_scheme.save_as(@project_path, "Versioning", false)

    @project.add_build_configuration("Versioning", :debug)
  end

  def saveProject
    @project.save
  end
end
