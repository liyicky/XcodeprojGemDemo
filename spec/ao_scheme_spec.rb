require 'spec_helper'

describe "AO_scheme" do
  
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

    describe "test_action" do

      before (:each) do
        @scheme = Xcodeproj::XCScheme.new
        @main_target = @project.project.new_target(:application, 'Main', :ios)
        @test_target = @project.project.new_target(:application, 'Test', :ios)
        @project.saveProject
      end

      after (:each) do
        @scheme      = nil
        @main_target = nil
        @test_target = nil
      end

      it "Builds a test_action in a scheme" do
        @result = Xcodeproj::XCScheme.new
        build = AO_scheme.new(@result, @main_target, @test_target, :debug)
        build.test_action("echo script", "Main")

        @result.should_not == @scheme
      end

      it "Sets the buildConfiguration" do
        build = AO_scheme.new(@scheme, @main_target, @test_target, :debug)
        build.test_action("echo script", "Main")
        build.save(@project_path,  "MainScheme")

        @result = true if @scheme.to_s().include? "buildConfiguration = \"Main\">"
        @result.should == true
      end
    end

end