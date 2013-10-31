require 'spec_helper'

describe "AO_Xcodeproj" do

  before do
    include Spec_helper
  end

  before  do
    @project      = XcodeTestProj.new("TestingProject_wY0kK5cNi8", "TestingProject")
    @project_path = @project.project_path
    @root_path    = @project.root_path
    @main_target  = @project.project.new_target(:application, 'Main', :ios)
    @test_target  = @project.project.new_target(:application, 'Test', :ios)
  end

  after (:each) do
    @result       = nil
    @project      = nil
    @project_path = nil
    @root_path    = nil
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

    it "should have GCC_GENERATE_TEST_COVERAGE_FILES equal to YES" do
      @project.project.build_settings("Coverage")["GCC_GENERATE_TEST_COVERAGE_FILES"].should == "YES"
    end

    it "should have GCC_INSTRUMENT_PROGRAM_FLOW_ARCS equal to YES" do
      @project.project.build_settings("Coverage")["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"].should == "YES"
    end

     it "should have SDKROOT equal to iphoneos" do
      @project.project.build_settings("Coverage")["SDKROOT"].should == "iphoneos"
    end

     it "should have ARCHS equal to ARCHS_STANDARD_INCLUDEING_64_BIT" do
       @project.project.build_settings("Coverage")["ARCHS"].should == "$(ARCHS_STANDARD_INCLUDING_64_BIT)"
     end

     it "should have FRAMEWORK_SEARCH_PATHS equal to the Debug Scheme's search paths" do
       debug_search_paths = ["$(SDKROOT)/Developer/Library/Frameworks", "$(inherited)", "$(DEVELOPER_FRAMEWORKS_DIR)"]
       @project.project.build_settings("Coverage")["FRAMEWORK_SEARCH_PATHS"].should == debug_search_paths
     end

     it "should have GCC_PREPROCESSOR_DEFINITIONS equal to COVERAGE=1" do
       @project.project.build_settings("Coverage")["GCC_PREPROCESSOR_DEFINITIONS"].should == ["DEBUG=1", "COVERAGE=1"]

     end

     it "should IPHONE_DEVELOPMENT_TARGET equal to 7.0" do
       @project.project.build_settings("Coverage")["IPHONEOS_DEPLOYMENT_TARGET"].should == "7.0"
     end

     it "should have OTHER_CFLAGS set" do
       @project.project.build_settings("Coverage")["OTHER_CFLAGS\[arch=*\]"].should ==  ["-fprofile-arcs", "-ftest-coverage"]
     end

    it "should have GCC_PREFIX_HEADER set to test_target.name-Prefix.pch" do
      @project.project.build_settings("Coverage")["GCC_PREFIX_HEADER"].should == "#{@test_target.name }/#{@test_target.name}-Prefix.pch"
    end

    it "should have INFOPLIST_FILE set to test_target.name-Info.plist" do
      @project.project.build_settings("Coverage")["INFOPLIST_FILE"].should == "#{@test_target.name }/#{@test_target.name}-Info.plist"
    end

    it "should have VERSIONING_SYSTEM set to apple-generic" do
      @project.project.build_settings("Coverage")["VERSIONING_SYSTEM"].should == "apple-generic"
    end
     it "should set BUNDLE_LOADER to main_target.app" do
      @project.project.build_settings("Coverage")["BUNDLE_LOADER"].should == "$(BUILT_PRODUCTS_DIR)/#{@main_target.name}.app/#{@main_target.name}"
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

