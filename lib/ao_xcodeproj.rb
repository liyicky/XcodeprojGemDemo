#!/usr/bin/env ruby

require 'xcodeproj'
require 'debugger'
require '../AO_Xcodeproj/lib/ao_xcodeproj/ao_scheme'


class XcodeTestProj

  attr_accessor :project
  attr_accessor :project_name
  attr_accessor :project_path
  attr_accessor :xcproj_path
  attr_accessor :coverage_script
  attr_accessor :main_target
  attr_accessor :test_target
  attr_accessor :class_prefix

  def initialize(project_path=nil, project_name=nil)
    @project_path = project_path
    @project_name = project_name
    @xcproj_path  = "#{@project_path}/#{@project_name}.xcodeproj"
  end

  def new_project
    @project = Xcodeproj::Project.new(@xcproj_path)
    @class_prefix = @project.objects[0].attributes["CLASSPREFIX"]
    @project.new_target(:application, 'Main', :ios)
    @project.new_target(:bundle, 'Test', :ios)
    @main_target = @project.targets.find { |target| target.name == "Main"}
    @test_target = @project.targets.find { |target| target.name == "Test"}

    main_target_directory = "#{@project_path}/#{@main_target.name}"
    test_target_directory = "#{@project_path}/#{@test_target.name}"

    FileUtils.mkdir_p(main_target_directory) unless File.directory?(main_target_directory)
    FileUtils.mkdir_p(test_target_directory) unless File.directory?(test_target_directory)

  end

  def open_project

    #Creates a new Xcodeproj
    if (@project_path.nil?)
      print "Enter a path for a new Xcodeproj: "
      @root_path = gets.strip.to_s()
      @project_path = "#{@project_name}.xcodeproj"
      @project = Xcodeproj::Project.new(@project_path)
      @project.new_target(:application, 'Xcode', :ios)
      @main_target = @project.targets.find { |target| target.name == "Main"}
      @test_target = @project.targets.find { |target| target.name == "#{@project_name}Test" }

    #Opens existing Xcodeproj
    elsif (@project_path.include? ".xcodeproj")
      @project = Xcodeproj::Project::open(@project_path)
      @class_prefix = @project.objects[0].attributes["CLASSPREFIX"]
      @main_target = @project.targets.find { |target| target.name == @project_name}
      @test_target = @project.targets.find { |target| target.name == "#{@project_name}Tests" }
      puts "Opened #{@project_name} : #{@main_target.uuid}"
    end
  end

  def add_coverage_scheme(coverage_script=nil)
    @coverage_script = coverage_script
    @coverage_script = "/bin/sh ${SRCROOT}/bin/coverage.sh" if (@coverage_script.nil?)
    @coverage_scheme = Xcodeproj::XCScheme.new

    project_settings     = {"CLANG_WARN_ENUM_CONVERSION"=>"YES", "GCC_WARN_UNUSED_VARIABLE"=>"YES", "GCC_WARN_ABOUT_RETURN_TYPE"=>"YES_ERROR", "GCC_PREPROCESSOR_DEFINITIONS"=>["DEBUG=1", "$(inherited)"], "ONLY_ACTIVE_ARCH"=>"YES", "CLANG_ENABLE_MODULES"=>"YES", "CLANG_CXX_LANGUAGE_STANDARD"=>"gnu++0x", "GCC_SYMBOLS_PRIVATE_EXTERN"=>"NO", "GCC_WARN_UNINITIALIZED_AUTOS"=>"YES", "CLANG_WARN_INT_CONVERSION"=>"YES", "CLANG_WARN_CONSTANT_CONVERSION"=>"YES", "GCC_OPTIMIZATION_LEVEL"=>"0", "GCC_C_LANGUAGE_STANDARD"=>"gnu99", "CLANG_WARN__DUPLICATE_METHOD_MATCH"=>"YES", "CLANG_WARN_EMPTY_BODY"=>"YES", "GCC_WARN_64_TO_32_BIT_CONVERSION"=>"YES", "ALWAYS_SEARCH_USER_PATHS"=>"NO", "CLANG_WARN_DIRECT_OBJC_ISA_USAGE"=>"YES_ERROR", "COPY_PHASE_STRIP"=>"NO", "CLANG_WARN_BOOL_CONVERSION"=>"YES", "CLANG_ENABLE_OBJC_ARC"=>"YES", "GCC_WARN_UNUSED_FUNCTION"=>"YES", "GCC_DYNAMIC_NO_PIC"=>"NO", "CLANG_WARN_OBJC_ROOT_CLASS"=>"YES_ERROR", "CODE_SIGN_IDENTITY[sdk=iphoneos*]"=>"iPhone Developer", "ARCHS"=>"$(ARCHS_STANDARD_INCLUDING_64_BIT)", "IPHONEOS_DEPLOYMENT_TARGET"=>"7.0", "SDKROOT"=>"iphoneos", "CLANG_CXX_LIBRARY"=>"libc++", "GCC_WARN_UNDECLARED_SELECTOR"=>"YES", "GCC_GENERATE_TEST_COVERAGE_FILES"=>"NO", "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"=>"NO"}
    main_target_settings = {"PRODUCT_NAME"=>"$(TARGET_NAME)", "WRAPPER_EXTENSION"=>"app", "GCC_PRECOMPILE_PREFIX_HEADER"=>"YES", "INFOPLIST_FILE"=>"#{@main_target.name}/#{@main_target.name}-Info.plist", "ASSETCATALOG_COMPILER_APPICON_NAME"=>"AppIcon", "ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME"=>"LaunchImage", "GCC_PREFIX_HEADER"=>"#{@main_target.name}/#{@main_target.name}-Prefix.pch", "GCC_GENERATE_TEST_COVERAGE_FILES"=>"YES", "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"=>"YES", "GCC_PREPROCESSOR_DEFINITIONS"=>["$(inherited)", "COVERAGE=1"]}
    test_target_settings = {"PRODUCT_NAME"=>"$(TARGET_NAME)", "WRAPPER_EXTENSION"=>"xctest", "FRAMEWORK_SEARCH_PATHS"=>["$(SDKROOT)/Developer/Library/Frameworks", "$(inherited)", "$(DEVELOPER_FRAMEWORKS_DIR)"], "TEST_HOST"=>"$(BUNDLE_LOADER)", "ARCHS"=>"$(ARCHS_STANDARD_INCLUDING_64_BIT)", "GCC_PRECOMPILE_PREFIX_HEADER"=>"YES", "INFOPLIST_FILE"=>"#{@test_target.name}/#{@test_target.name}-Info.plist", "BUNDLE_LOADER"=>"$(BUILT_PRODUCTS_DIR)/#{@main_target.name}.app/#{@main_target.name}", "GCC_PREFIX_HEADER"=>"#{@main_target.name}/#{@main_target.name}-Prefix.pch", "VALIDATE_PRODUCT"=>"NO", "ENABLE_NS_ASSERTIONS"=>"YES", "INFOPLIST_FILE"=>"#{@test_target.name}/#{@test_target.name}-Info.plist", "GCC_PREPROCESSOR_DEFINITIONS"=>["$(inherited)", "COVERAGE=1"]}


    @project.add_build_configuration("Coverage", :debug)
    @main_target.add_build_configuration("Coverage", :debug)
    @test_target.add_build_configuration("Coverage", :debug)

    project_settings.each{|key, value| @project.build_settings("Coverage")[key] = value}
    main_target_settings.each{|key, value| @main_target.build_settings("Coverage")[key] = value}
    test_target_settings.each{|key, value| @test_target.build_settings("Coverage")[key] = value}

    build_coverage = AO_scheme.new(@coverage_scheme, @main_target, @test_target, "Coverage")
    build_coverage.add_target
    build_coverage.test_action(@coverage_script)
    build_coverage.launch_action
    build_coverage.profile_action
    build_coverage.save(@project_path, "Coverage")
  end

  def add_coverage_script
    @project.save
    bin_path = "#{@project_path}/bin"
    Dir.mkdir(bin_path) unless File.exist?(bin_path)

    input = "source /opt/boxen/env.sh\nCOV_PATH=${SRCROOT}/Coverage\nCOV_INFO=${COV_PATH}/Coverage.info\nOBJ_ARCH_PATH=${PROJECT_TEMP_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.build/Objects-normal/i386\n\nmkdir -p ${COV_PATH}\n/usr/bin/env lcov --capture -b ${SRCROOT} -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"/Applications/Xcode.app/*\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"main.m\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n\n/usr/bin/env genhtml --output-directory ${COV_PATH} ${COV_INFO}\n"

    script = File.new("#{bin_path}/coverage.sh", "w+")
    script.write(input)
  end

  def add_observer
    observer_path = "#{@project_path}/#{@test_target.name}/#{@test_target.name}Observer.m"
    observer      = File.new(observer_path, "w+") && @test_target.add_file_references([@project.new_file(observer_path)]) unless File.exists? observer_path

    File.open(observer_path, "w+") do |ln|
      ln.puts "//"
      ln.puts "// #{@test_target.name}Observer.m"
      ln.puts "//"
      ln.puts "// Created by Liygem on #{Date.today}"
      ln.puts "//\n\n"
      ln.puts "#ifdef COVERAGE \n\n"
      ln.puts "#import <XCTest/XCTest.h> \n\n"
      ln.puts "@interface #{@test_target.name}Observer : XCTestObserver"
      ln.puts "@end \n\n"
      ln.puts "@implementation #{@test_target.name}Observer \n\n"
      ln.puts "+ (void)load"
      ln.puts "{"
      ln.puts "\t[[NSUserDefaults standardUserDefaults] setValue:@\"XCTestLog,#{@test_target.name}Observer\" forKey:XCTestObserverClassKey];"
      ln.puts "} \n\n"
      ln.puts "- (void)stopObserving"
      ln.puts "{"
      ln.puts "\t[super stopObserving];"
      ln.puts "\tUIApplication *application = [UIApplication sharedApplication];"
      ln.puts "\tid<UIApplicationDelegate> delegate = [application delegate];"
      ln.puts "\t[delegate applicationWillResignActive:application];"
      ln.puts "} \n\n"
      ln.puts "@end \n\n"
      ln.puts "#endif //COVERAGE"
    end
  end

  def add_gcov_flush
    line_number              = 0
    stop_number              = 0
    after_flush_number       = 0
    done_adding_flush        = false
    app_delegate_path        = "#{@project_path}/#{@main_target.name}/#{@class_prefix}AppDelegate.m"
    tmp_application_delegate = File.new("#{app_delegate_path}.tmp", "w+")
    application_delegate     = File.open(app_delegate_path, "r+") do |file|
      file.each_line do |ln|
        line_number+=1
        tmp_application_delegate << ln if done_adding_flush == false
        if ln.strip == "- (void)applicationWillResignActive:(UIApplication *)application"
          tmp_application_delegate.puts "{"
          tmp_application_delegate.puts "#ifdef COVERAGE //This was added for Unit Testing on #{Date.today}"
          tmp_application_delegate.puts "\t__gcov_flush();"
          tmp_application_delegate.puts "#endif          //COVERAGE"
          after_flush_number = line_number + 2
          done_adding_flush  = true
        end
      end
    end

    application_delegate = File.open(app_delegate_path, "r+") do |file|
      file.each_line do |ln|
        stop_number+=1
        if stop_number < after_flush_number
          #skip line
        else
          tmp_application_delegate << ln
        end
      end
    end
    FileUtils.mv "#{app_delegate_path}.tmp", app_delegate_path, :force => true
  end

  def add_versioning_scheme
    @versioning_scheme = Xcodeproj::XCScheme.new
    @versioning_scheme.add_build_target(@main_target)
    @versioning_scheme.save_as(@project_path, "Versioning", false)

    @project.add_build_configuration("Versioning", :debug)
  end

  def save_project
    @project.save
  end
end
