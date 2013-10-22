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
      @scheme       = nil
      FileUtils.rm_rf("TestingProject_wY0kK5cNi8")
    end

    describe "test_action" do

      before do
        @scheme = Xcodeproj::XCScheme.new
        @project.project.new_target(:application, 'Main', :ios)
        @project.project.new_target(:application, 'Test', :ios)
        @project.saveProject
      end

      it "Builds a test_action in a scheme" do 
        puts @scheme
        @result = AO_scheme.new(@scheme, @main_target, @test_target, :debug)
        @result.test_action
        puts @scheme
        @scheme.should == @result
      end
    end

end