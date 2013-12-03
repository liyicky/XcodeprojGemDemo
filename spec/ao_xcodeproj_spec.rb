require 'spec_helper'

describe "AO_Xcodeproj" do

  before do
    include Spec_helper
  end

  before  do
    @project      = XcodeTestProj.new("TestingProject_wY0kK5cNi8", "TestingProject")
    @project_path = @project.project_path
    @root_path    = @project.root_path
  end

  after (:each) do
    @result       = nil
  end

  after do
    FileUtils.rm_rf("TestingProject_wY0kK5cNi8")
  end

  describe "open_project" do

  end

  describe "add_versioning_scheme" do

    it "creates Versioning.xcscheme files" do
      @project.add_versioning_scheme

      @result = Spec_helper::find_file_helper(@project_path, "/Versioning.xcscheme")
      File.exist?(@result).should == true
    end
  end

  describe "add_coverage_scheme" do

    before do
      @project.add_coverage_scheme
    end

    it "creates Coverage.xcscheme files" do
      @result = Spec_helper::find_file_helper(@project_path, "/Coverage.xcscheme")
      File.exists?(@result).should == true
    end


    it "should have Bash Script String in the Coverage.xcscheme" do
      @script = "/bin/sh ${SRCROOT}/bin/coverage.sh"
      coverage_scheme_path = []
      Find.find(@project_path) do |path|
        coverage_scheme_path << path if path =~ /.*Coverage\.xcscheme$/
      end

      coverage_scheme = File.open(coverage_scheme_path[0]).read
      for li in coverage_scheme.each_line
          li = li.split("= ")
          li = li.at(1).to_s().split(">")
          li = li.at(0).to_s().split("\"")
          li = li.at(1).to_s()
          @result = li if (li == @script)
      end
      @result.should == @script
    end

    it "should have GCC_GENERATE_TEST_COVERAGE_FILES and GCC_INSTRUMENT_PROGRAM_FLOW equal to NO" do
      @project.project.build_settings("Coverage")["GCC_GENERATE_TEST_COVERAGE_FILES"].should == "NO"
      @project.project.build_settings("Coverage")["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"].should == "NO"
    end

    it "should have SDKROOT equal to iphoneos" do
      @project.project.build_settings("Coverage")["SDKROOT"].should == "iphoneos"
    end

    it "should have ARCHS equal to ARCHS_STANDARD_INCLUDEING_64_BIT" do
      @project.project.build_settings("Coverage")["ARCHS"].should == "$(ARCHS_STANDARD_INCLUDING_64_BIT)"
    end

    it "should have FRAMEWORK_SEARCH_PATHS equal to the Debug Scheme's search paths" do
      debug_search_paths =
      @project.project.build_settings("Coverage")["FRAMEWORK_SEARCH_PATHS"].should == debug_search_paths
    end

    it "should have GCC_PREPROCESSOR_DEFINITIONS equal to COVERAGE=1" do
      @project.main_target.build_settings("Coverage")["GCC_PREPROCESSOR_DEFINITIONS"].should == ["$(inherited)", "COVERAGE=1"]
    end

    it "should IPHONE_DEVELOPMENT_TARGET equal to 7.0" do
      @project.project.build_settings("Coverage")["IPHONEOS_DEPLOYMENT_TARGET"].should == "7.0"
    end
  end

  describe "add_coverage_script" do

    it "should have a bin in the projects root directory" do
      @project.add_coverage_script

      @result = Spec_helper::find_file_helper(@root_path, "/bin")
      File.exists?(@result).should == true
    end

    it "should have coverage.sh in the project's bin" do
      @project.add_coverage_script

      @result = Spec_helper::find_file_helper(@root_path, "coverage.sh")
      File.exists?(@result).should == true
    end
  end

  describe "add_observer" do

    before do
      @project.add_observer
    end

    it "should add an observer file to the project" do
      @result = Spec_helper::find_file_helper(@root_path, "#{@project.test_target.name}Observer.m")
      File.exists?(@result).should == true
    end

    it "should add a test directory if one doesn't exist" do
      dir = "#{@root_path}/#{@project.test_target.name}"
      File.directory?(dir).should == true
    end
  end

  describe "add_gcov_flush" do
    before do
      @project.add_gcov_flush
    end
    it "should add gcov_flush() to the application's delegate" do
      app_delegate = File.open("#{@root_path}/#{@project.main_target.name}/#{@project.class_prefix}AppDelegate").read
      if app_delegate == "- (void)applicationWillResignActive:(UIApplication *)application" then app_delegate do |ln|
        ln.readline
        ln.readline
        ln.should == "#ifdef COVERAGE"
        ln.should == "\t__gcov_flush();"
        ln.should == "#endif"
        end
      end
    end

  end

end

