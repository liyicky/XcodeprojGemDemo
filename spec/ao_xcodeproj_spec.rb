require 'spec_helper'

describe "XcodeprojGemDemo" do

  before do
    include Spec_helper
  end

  before (:each) do
    @project      = XcodeTestProj.new("TestingProject_wY0kK5cNi8", "TestingProject")
    @project_path = @project.project_path
    @root_path    = @project.root_path
  end

  after (:each) do 
    @result       = nil
    @project      = nil
    @project_path = nil
    @root_path    = nil
    FileUtils.rm_rf("TestingProject_wY0kK5cNi8")
  end

  describe "openProject" do

  end

  describe "addVersioningScheme" do

    it "creates Versioning.xcscheme files" do
      @project.addVersioningScheme

      @result = Spec_helper::find_helper(@project_path, "/Versioning.xcscheme")
      versioning_exists = File.exist?(@result)
      versioning_exists.should == true
    end
  end

  describe "addCoverageScheme" do

    before do
      
    end

    it "creates Coverage.xcscheme files" do
      @project.addCoverageScheme

      @result = Spec_helper::find_helper(@project_path, "/Coverage.xcscheme")
      coverage_exists = File.exists?(@result)
      coverage_exists.should == true
    end


    it "should have Bash Script String in the Coverage.xcscheme" do
      @script = "/bin/sh ${SRCROOT}/bin/coverage.sh"
      @project.addCoverageScheme

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
      @project.addCoverageScheme

      @project.project.build_settings("Coverage")["GCC_GENERATE_TEST_COVERAGE_FILES"].should == ["YES"]
    end

    it "should have GCC_INSTRUMENT_PROGRAM_FLOW_ARCS equal to YES" do 
      @project.addCoverageScheme

      @project.project.build_settings("Coverage")["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"].should == ["YES"]
    end
  end

  describe "addCoverageScript" do

    it "should have a bin in the projects root directory" do
      @project.addCoverageScript

      @result = Spec_helper::find_helper(@root_path, "/bin")
      bin_exists = File.exists?(@result)
      bin_exists.should == true
    end

    it "should have coverage.sh in the project's bin" do 
      @project.addCoverageScript

      @result = Spec_helper::find_helper(@root_path, "coverage.sh")
      script_exists = File.exists?(@result)
      script_exists.should == true
    end
  end

end
