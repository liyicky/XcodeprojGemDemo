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
  attr_accessor :main_target
  attr_accessor :test_target

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
    @coverage_script = "logfile=${SRCROOT}/bin/logfile.txt && exec > $logfile 2>&1 && /bin/sh ${SRCROOT}/bin/coverage.sh" if (@coverage_script.nil?)
    @coverage_scheme = Xcodeproj::XCScheme.new

    project_settings     = {"CLANG_WARN_ENUM_CONVERSION"=>"YES", "GCC_WARN_UNUSED_VARIABLE"=>"YES", "GCC_WARN_ABOUT_RETURN_TYPE"=>"YES_ERROR", "GCC_PREPROCESSOR_DEFINITIONS"=>["DEBUG=1", "$(inherited)"], "ONLY_ACTIVE_ARCH"=>"YES", "CLANG_ENABLE_MODULES"=>"YES", "CLANG_CXX_LANGUAGE_STANDARD"=>"gnu++0x", "GCC_SYMBOLS_PRIVATE_EXTERN"=>"NO", "GCC_WARN_UNINITIALIZED_AUTOS"=>"YES", "CLANG_WARN_INT_CONVERSION"=>"YES", "CLANG_WARN_CONSTANT_CONVERSION"=>"YES", "GCC_OPTIMIZATION_LEVEL"=>"0", "GCC_C_LANGUAGE_STANDARD"=>"gnu99", "CLANG_WARN__DUPLICATE_METHOD_MATCH"=>"YES", "CLANG_WARN_EMPTY_BODY"=>"YES", "GCC_WARN_64_TO_32_BIT_CONVERSION"=>"YES", "ALWAYS_SEARCH_USER_PATHS"=>"NO", "CLANG_WARN_DIRECT_OBJC_ISA_USAGE"=>"YES_ERROR", "COPY_PHASE_STRIP"=>"NO", "CLANG_WARN_BOOL_CONVERSION"=>"YES", "CLANG_ENABLE_OBJC_ARC"=>"YES", "GCC_WARN_UNUSED_FUNCTION"=>"YES", "GCC_DYNAMIC_NO_PIC"=>"NO", "CLANG_WARN_OBJC_ROOT_CLASS"=>"YES_ERROR", "CODE_SIGN_IDENTITY[sdk=iphoneos*]"=>"iPhone Developer", "ARCHS"=>"$(ARCHS_STANDARD_INCLUDING_64_BIT)", "IPHONEOS_DEPLOYMENT_TARGET"=>"7.0", "SDKROOT"=>"iphoneos", "CLANG_CXX_LIBRARY"=>"libc++", "GCC_WARN_UNDECLARED_SELECTOR"=>"YES", "GCC_GENERATE_TEST_COVERAGE_FILES"=>"NO", "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"=>"NO"}


    main_target_settings = {"PRODUCT_NAME"=>"$(TARGET_NAME)", "WRAPPER_EXTENSION"=>"app", "GCC_PRECOMPILE_PREFIX_HEADER"=>"YES", "INFOPLIST_FILE"=>"#{@main_target.name}/#{@main_target.name}-Info.plist", "ASSETCATALOG_COMPILER_APPICON_NAME"=>"AppIcon", "ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME"=>"LaunchImage", "GCC_PREFIX_HEADER"=>"#{@main_target.name}/#{@main_target.name}-Prefix.pch", "GCC_GENERATE_TEST_COVERAGE_FILES"=>"YES", "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"=>"YES", "GCC_PREPROCESSOR_DEFINITIONS"=>["DEBUG=1", "COVERAGE=1"]}


    test_target_settings = {"PRODUCT_NAME"=>"$(TARGET_NAME)", "WRAPPER_EXTENSION"=>"xctest", "FRAMEWORK_SEARCH_PATHS"=>["$(SDKROOT)/Developer/Library/Frameworks", "$(inherited)", "$(DEVELOPER_FRAMEWORKS_DIR)"], "TEST_HOST"=>"$(BUNDLE_LOADER)", "ARCHS"=>"$(ARCHS_STANDARD_INCLUDING_64_BIT)", "GCC_PRECOMPILE_PREFIX_HEADER"=>"YES", "INFOPLIST_FILE"=>"#{@test_target.name}/#{@test_target.name}-Info.plist", "BUNDLE_LOADER"=>"$(BUILT_PRODUCTS_DIR)/#{@main_target.name}.app/#{@main_target.name}", "GCC_PREFIX_HEADER"=>"#{@main_target.name}/#{@main_target.name}-Prefix.pch", "VALIDATE_PRODUCT"=>"NO", "ENABLE_NS_ASSERTIONS"=>"YES", "INFOPLIST_FILE"=>"#{@test_target.name}/#{@test_target.name}-Info.plist" }


    @project.add_build_configuration("Coverage", :debug)
    @main_target.add_build_configuration("Coverage", :debug)
    @test_target.add_build_configuration("Coverage", :debug)

    project_settings.each{|key, value| @project.build_settings("Coverage")[key] = value}
    main_target_settings.each{|key, value| @main_target.build_settings("Coverage")[key] = value}
    test_target_settings.each{|key, value| @test_target.build_settings("Coverage")[key] = value}

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

    input = "source /opt/boxen/env.sh\nCOV_PATH=${SRCROOT}/Coverage\nCOV_INFO=${COV_PATH}/Coverage.info\nOBJ_ARCH_PATH=${PROJECT_TEMP_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.build/Objects-normal/i386\n\nmkdir -p ${COV_PATH}\n/usr/bin/env lcov --capture -b ${SRCROOT} -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"/Applications/Xcode.app/*\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"main.m\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n\n/usr/bin/env genhtml --output-directory ${COV_PATH} ${COV_INFO}\n"


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
