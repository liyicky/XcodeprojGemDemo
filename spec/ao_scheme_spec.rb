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

    describe "add_target" do

      before (:each) do
        @result       = Xcodeproj::XCScheme.new
        @scheme_build = AO_scheme.new(@result, @main_target, @test_target)
      end

      after (:each) do
        @scheme_build = nil
      end

      it "Sets BuildActionEntries elements" do

        @scheme_build.add_target

        @result = true if @result.to_s().include? "BuildActionEntries"
        @scheme = (true if @scheme.to_s().include? "BuildActionEntries") || false
        @result.should == true
        @scheme.should == false
      end

      it "Sets BuildActionEntry elements" do
        @scheme_build.add_target

        @result = @result.doc.root.elements['BuildAction'].elements['BuildActionEntries'].elements['BuildActionEntry']

        buildForTesting   = @result.attributes['buildForTesting']
        buildForRunning   = @result.attributes['buildForRunning']
        buildForProfiling = @result.attributes['buildForProfiling']
        buildForArchiving = @result.attributes['buildForArchiving']
        buildForAnalyzing = @result.attributes['buildForAnalyzing']

        buildForTesting.should   == "YES"
        buildForRunning.should   == "YES"
        buildForProfiling.should == "YES"
        buildForArchiving.should == "YES"
        buildForAnalyzing.should == "YES"
      end

    end

    describe "buildable_reference" do

      before (:each) do
        @result       = Xcodeproj::XCScheme.new
        @scheme_build = AO_scheme.new(@result, @main_target, @test_target)
        @element      = @result.doc.root.elements['TestAction'].elements['Testables']
      end

      after (:each) do
        @scheme_build = nil
        @element      = nil
      end

      it "Returns a BuildableReference for a .app" do
        @scheme_build.buildable_reference(@element, "app", false)
        @result = true if @element.to_s().include? "BuildableReference"
        @result.should == true
      end

      it "Sets BuildableReference elements for .app" do
        @scheme_build.buildable_reference(@element, "app", false)

        buildableIdentifier   = @element.elements['BuildableReference'].attributes['BuildableIdentifier']
        blueprintIdentifier   = @element.elements['BuildableReference'].attributes['BlueprintIdentifier']
        buildableName         = @element.elements['BuildableReference'].attributes['BuildableName']
        blueprintName         = @element.elements['BuildableReference'].attributes['BlueprintName']
        referencedContainer   = @element.elements['BuildableReference'].attributes['ReferencedContainer']

        buildableIdentifier.should   == "primary"
        blueprintIdentifier.should   == @main_target.uuid
        buildableName.should         == "#{@main_target.name}.app"
        blueprintName.should         == "#{@main_target.name}"
        referencedContainer.should   == "container:#{@main_target.project.path.basename}"
      end

      it "Sets BuildableReference elements for .xctest" do
        @scheme_build.buildable_reference(@element, "xctest", false)

        buildableIdentifier   = @element.elements['BuildableReference'].attributes['BuildableIdentifier']
        blueprintIdentifier   = @element.elements['BuildableReference'].attributes['BlueprintIdentifier']
        buildableName         = @element.elements['BuildableReference'].attributes['BuildableName']
        blueprintName         = @element.elements['BuildableReference'].attributes['BlueprintName']
        referencedContainer   = @element.elements['BuildableReference'].attributes['ReferencedContainer']

        buildableIdentifier.should   == "primary"
        blueprintIdentifier.should   == @test_target.uuid
        buildableName.should         == "#{@test_target.name}.xctest"
        blueprintName.should         == "#{@test_target.name}"
        referencedContainer.should   == "container:#{@test_target.project.path.basename}"
      end

      it "Wraps BuildableReference inside MacroExpansion" do
        @scheme_build.buildable_reference(@element, "app", true)
        @result = true if @element.to_s().include? "MacroExpansion"
        @result.should == true
      end

    end

    describe "test_action" do

      before (:each) do
        @result       = Xcodeproj::XCScheme.new
        @scheme_build = AO_scheme.new(@result, @main_target, @test_target)
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

      it "Adds a MacroExpansion" do
        @scheme_build.test_action("echo liyickywashere", "Main")
        @result = @result.doc.root.elements['TestAction']
        @result = true if @result.to_s().include? "MacroExpansion"
        @scheme = (true if @scheme.to_s().include? "MacroExpansion") || false

        @result.should == true
        @scheme.should == false
      end
    end

    describe "profile_action" do

      before (:each) do
        @result       = Xcodeproj::XCScheme.new
        @scheme_build = AO_scheme.new(@result, @main_target, @test_target)
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
