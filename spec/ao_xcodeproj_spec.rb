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
      @project.project.build_settings("Coverage")["GCC_GENERATE_TEST_COVERAGE_FILES"].should == ["YES"]
    end

    it "should have GCC_INSTRUMENT_PROGRAM_FLOW_ARCS equal to YES" do
      @project.project.build_settings("Coverage")["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"].should == ["YES"]
    end

     it "should have SDKROOT equal to iphoneos" do
      @project.project.build_settings("Coverage")["SDKROOT"].should == ["iphoneos"]
    end

     it "should have ARCHS equal to ARCHS_STANDARD_INCLUDEING_64_BIT" do
       @project.project.build_settings("Coverage")["ARCHS"].should == ["$(ARCHS_STANDARD_INCLUDING_64_BIT)"]
     end

     it "should have FRAMEWORK_SEARCH_PATHS equal to the Debug Scheme's search paths" do
       debug_search_paths = @project.project.build_settings("Debug")["FRAMEWORK_SEARCH_PATHS"]
       @project.project.build_settings("Coverage")["FRAMEWORK_SEARCH_PATHS"].should == debug_search_paths
     end

     it "should have GCC_PREPROCESSOR_DEFINITIONS equal to COVERAGE=1" do
       @project.project.build_settings("Coverage")["GCC_PREPROCESSOR_DEFINITIONS"].should == ["COVERAGE=1"]
     end

     it "should IPHONE_DEVELOPMENT_TARGET equal to 7.0" do
       @project.project.build_settings("Coverage")["IPHONE_DEVELOPMENT_TARGET"].should == ["7.0"]
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

