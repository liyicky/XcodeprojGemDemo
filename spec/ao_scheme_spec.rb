require 'spec_helper'

describe "AO_scheme" do
  
  before do
    include Spec_helper
  end

  before (:each) do
      @project      = XcodeTestProj.new("TestingProject_wY0kK5cNi8", "TestingProject")
      @project_path = @project.project_path
      @root_path    = @project.root_path

      @scheme       = Xcodeproj::XCScheme.new
      @main_target  = @project.project.new_target(:application, 'Main', :ios)
      @test_target  = @project.project.new_target(:application, 'Test', :ios)
      @project.saveProject
    end

    after (:each) do 
      @result       = nil
      @project      = nil
      @project_path = nil
      @root_path    = nil
      @scheme       = nil
      @main_target  = nil
      @test_target  = nil
      FileUtils.rm_rf("TestingProject_wY0kK5cNi8")
    end

    describe "test_action" do

      before (:each) do
        @result       = Xcodeproj::XCScheme.new
        @scheme_build = AO_scheme.new(@result, @main_target, @test_target, :debug)
      end 

      after (:each) do
        @scheme_build = nil
      end 

      it "Builds a test_action in a scheme" do
        @scheme_build.test_action("echo script", "Main")
        @result.should_not == @scheme
      end

      it "Sets the buildConfiguration" do
        @scheme_build.test_action("echo script", "Main")

        @result = true if @result.to_s().include? "buildConfiguration = \"Main\">"
        @scheme = (true if @scheme.to_s().include? "buildConfiguration = \"Main\">") || false
        @result.should == true
        @scheme.should == false
      end

      it "Adds Testable elements" do
        @scheme_build.test_action("echo script", "Main")

        @result = true if @result.to_s().include? "TestableReference"
        @scheme = (true if @scheme.to_s().include? "TestableReference") || false
        @result.should == true
        @scheme.should == false
      end

      it "Adds script to Testable elements" do
        @scheme_build.test_action("this is the script", "Main")
        @result = @result.doc.root.elements["TestAction"]
  
        @result.to_s().should include "this is the script"
        @scheme.to_s().should_not include "this is the script"
      end
    end

    describe "profile_action" do

      before (:each) do
        @result       = Xcodeproj::XCScheme.new
        @scheme_build = AO_scheme.new(@result, @main_target, @test_target, :debug)
      end 

      after (:each) do
        @scheme_build = nil
      end 


      it "Builds a post_action in a scheme" do
        @scheme_build.profile_action

        @result.should_not == @scheme
      end

      it "Adds BuildableProductRunnable elements" do
        @scheme_build.profile_action
        @result = @result.doc.root.elements["ProfileAction"]
        @result = @result.elements["BuildableProductRunnable"]

        @result.to_s().should include "BuildableProductRunnable"
        @scheme.to_s().should_not include "BuildableProductRunnable"
      end

      
    end

end