require 'spec_helper'

describe "AO_Xcodeproj" do

  before  do
    include Spec_helper
    @project      = XcodeTestProj.new("TestingProject_wY0kK5cNi8", "TestingProject")
    @xcproj       = @project.project
    @project_path = @project.project_path
    @root_path    = @project.root_path
    @main_target  = @project.main_target
    @test_target  = @project.test_target
  end

  after (:each) do
    @result       = nil
  end

  after do
    FileUtils.rm_rf("TestingProject_wY0kK5cNi8")
  end

  describe "openProject" do

  end

  describe "addVersioningScheme" do

    it "creates Versioning.xcscheme files" do
      @project.addVersioningScheme

      @result = Spec_helper::find_file_helper(@project_path, "/Versioning.xcscheme")
      versioning_exists = File.exist?(@result)
      versioning_exists.should == true
    end
  end

  describe "addCoverageScheme" do

    before do
      @project.addCoverageScheme
    end

    it "creates Coverage.xcscheme files" do
      @result = Spec_helper::find_file_helper(@project_path, "/Coverage.xcscheme")
      coverage_exists = File.exists?(@result)
      coverage_exists.should == true
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

    it "should set Coverage Build Settings for the Project" do
      @xcproj.build_settings("Coverage")["GCC_GENERATE_TEST_COVERAGE_FILES"].should == "YES"
      @xcproj.build_settings("Coverage")["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"].should == "YES"
      @xcproj.build_settings("Coverage")["SDKROOT"].should == "iphoneos"
      @xcproj.build_settings("Coverage")["ARCHS"].should == "$(ARCHS_STANDARD_INCLUDING_64_BIT)"
      @xcproj.build_settings("Coverage")["IPHONEOS_DEPLOYMENT_TARGET"].should == "7.0"
      @xcproj.build_settings("Coverage")["CLANG_WARN_ENUM_CONVERSION"].should == "YES"
    end

    it "should set Coverage Build Settings for the Main Target" do
      @main_target.build_settings("Coverage")["PRODUCT_NAME"].should == "$(TARGET_NAME)"
      @main_target.build_settings("Coverage")["WRAPPER_EXTENSION"].should == "app"
      @main_target.build_settings("Coverage")["GCC_PRECOMPILE_PREFIX_HEADER"].should == "YES"
      @main_target.build_settings("Coverage")["INFOPLIST_FILE"].should == "#{@main_target.name}/#{@main_target.name}-Info.plist"
      @main_target.build_settings("Coverage")["ASSETCATALOG_COMPILER_APPICON_NAME"].should == "AppIcon"
      @main_target.build_settings("Coverage")["ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME"].should == "LaunchImage"
      @main_target.build_settings("Coverage")["GCC_PREFIX_HEADER"].should == "#{@main_target.name}/#{@main_target.name}-Prefix.pch"
    end

  end

  describe "addCoverageScript" do

    it "should have a bin in the projects root directory" do
      @project.addCoverageScript

      @result = Spec_helper::find_file_helper(@root_path, "/bin")
      bin_exists = File.exists?(@result)
      bin_exists.should == true
    end

    it "should have coverage.sh in the project's bin" do
      @project.addCoverageScript

      @result = Spec_helper::find_file_helper(@root_path, "coverage.sh")
      script_exists = File.exists?(@result)
      script_exists.should == true
    end
  end

end

