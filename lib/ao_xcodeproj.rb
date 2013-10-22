#!/usr/bin/env ruby

require 'xcodeproj'
require 'debugger'


class XcodeTestProj

  attr_accessor :project
  attr_accessor :project_name
  attr_accessor :project_path
  attr_accessor :root_path
  attr_accessor :coverage_script

  def initialize(project_path=nil, project_name=nil)
    @project_path = project_path
    @project_name = project_name

    if @project_path[".xcodeproj"] == nil
      @root_path  = @project_path
    elsif @project_path[".xcodeproj"] != nil then
      @root_path  = File.expand_path("..", @project_path)
    end

    self.openProject

  end

  def openProject

    #Creates a new Xcodeproj
    if (@project_path.nil?)
      print "Enter a path for a new Xcodeproj: "
      @root_path = gets.strip.to_s()
      @project_path = @root_path + "/#{@project_name}.xcodeproj"
      @project = Xcodeproj::Project.new(@project_path)
      @project.new_target(:application, 'Xcode', :ios)
      @main_target = @project.targets.find { |target| target.name == "Xcode"}
      @test_target = @project.targets.find { |target| target.name == "#{@project_name}Tests" }

    #Opens existing Xcodeproj
    elsif (@project_path.include? ".xcodeproj")
      @project = Xcodeproj::Project::open(@project_path)
      @main_target = @project.targets.find { |target| target.name == @project_name}
      @test_target = @project.targets.find { |target| target.name == "#{@project_name}Tests" }

      puts "Opened #{@project_name} : #{@main_target.uuid}"
      
    #Creates a new Xcodeproj in the root dir
    else
      @project_path = @project_path + "/#{@project_name}.xcodeproj"
      @project = Xcodeproj::Project.new(@project_path)
      @project.new_target(:application, 'Xcode', :ios)
      @project.new_target(:bundle, 'Tests', :ios)
      @main_target = @project.targets.find { |target| target.name == "Xcode"}
      @test_target = @project.targets.find { |target| target.name == "Tests"}  
    end
  end

  def addTestTargets
    @coverage_target = @project.new_target(:bundle, "Coverage", :ios)
    @test_flight_target = @project.new_target(:bundle, "TestFlight", :ios)
  end

  def addCoverageScheme(coverage_script=nil)

    @coverage_script = coverage_script
    @coverage_script = "/bin/sh ${SRCROOT}/bin/coverage.sh" if (@coverage_script.nil?) 

    @coverage_scheme = Xcodeproj::XCScheme.new
    @coverage_scheme.add_build_target(@main_target)
    @coverage_scheme.add_build_target(@test_target)

    # Configures the Scheme's TestAction ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## 
    test_action = @coverage_scheme.doc.root.elements['TestAction']
    test_action.attributes['buildConfiguration'] = 'Coverage'

    # Post Actions (Adds the Script)
    ta_post_action = test_action.add_element("PostActions")
    ta_execute_action = ta_post_action.add_element("ExecutionAction")
    ta_execute_action.attributes["ActionType"] = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction"
    ta_action_content = ta_execute_action.add_element("ActionContent")
    ta_action_content.attributes["title"] = "Run Script"
    ta_action_content.attributes["scriptText"] = @coverage_script
    ta_env_buildable = ta_action_content.add_element("EnvironmentBuildable")
    ta_buildable_ref = ta_env_buildable.add_element("BuildableReference")
    ta_buildable_ref.attributes["BuildableIdentifier"] = "primary"
    ta_buildable_ref.attributes["BlueprintIdentifier"] = @main_target.uuid
    ta_buildable_ref.attributes["BuildableName"]       = "#{@main_target.name}.app"
    ta_buildable_ref.attributes["BlueprintName"]       = "#{@main_target.name}"
    ta_buildable_ref.attributes["ReferencedContainer"]  = "container:#{@main_target.project.path.basename}"

    # Testables (Adds the Test Target)
    ta_testables = test_action.elements['Testables']
    ta_testable_reference = ta_testables.add_element('TestableReference')
    ta_testable_reference.attributes['skipped'] = 'NO'
    ta_testable_buildable_ref = ta_testable_reference.add_element('BuildableReference')
    ta_testable_buildable_ref.attributes["BuildableIdentifier"] = "primary"
    ta_testable_buildable_ref.attributes["BlueprintIdentifier"] = @test_target.uuid
    ta_testable_buildable_ref.attributes["BuildableName"]       = "#{@test_target.name}.xctest"
    ta_testable_buildable_ref.attributes["BlueprintName"]       = "#{@test_target.name}"
    ta_testable_buildable_ref.attributes["ReferencedContainer"]  = "container:#{@test_target.project.path.basename}"

    
    ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##


    # Configures the Scheme's ProfileAction ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
    profile_action = @coverage_scheme.doc.root.elements['ProfileAction']
    pa_build_prod_runnable = profile_action.add_element('BuildableProductRunnable')
    pa_buildable_ref = pa_build_prod_runnable.add_element('BuildableReference')
    pa_buildable_ref.attributes['BuildableIdentifier'] = 'primary'
    pa_buildable_ref.attributes['BlueprintIdentifier'] = @main_target.uuid
    pa_buildable_ref.attributes['BuildableName']       = "#{@main_target.name}.app"
    pa_buildable_ref.attributes['BlueprintName']       = @main_target.name
    pa_buildable_ref.attributes['ReferenceContainer']  = "container:#{@main_target.project.path.basename}"
    ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## 

    @project.add_build_configuration("Coverage", :debug)
    @project.build_settings("Coverage")["GCC_GENERATE_TEST_COVERAGE_FILES"] = ["YES"]
    @project.build_settings("Coverage")["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"] = ["YES"]
    @coverage_scheme.save_as(@project_path, "Coverage", false)
  end

  def addCoverageScript
    @project.save
    bin_path = "#{@root_path}/bin"
    Dir.mkdir(bin_path) unless File.exist?(bin_path)

    input = "COV_PATH=${SRCROOT}/Coverage\nCOV_INFO=${COV_PATH}/Coverage.info\nOBJ_ARCH_PATH=${OBJECT_FILE_DIR}-normal/${VALID_ARCHS}\n\nmkdir -p ${COV_PATH}\n/usr/bin/env lcov --capture -b ${SRCROOT} -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"/Applications/Xcode5-DP6.app/*\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n/usr/bin/env lcov --remove ${COV_INFO} \"main.m\" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}\n\n/usr/bin/env genhtml --output-directory ${COV_PATH} ${COV_INFO}\n"

    script = File.new("#{bin_path}/coverage.sh", "w+")
    script.write(input)

  end

  def addVersioningScheme
    @versioning_scheme = Xcodeproj::XCScheme.new
    @versioning_scheme.add_build_target(@main_target)
    @versioning_scheme.save_as(@project_path, "Versioning", false)

    @project.add_build_configuration("Versioning", :debug)
  end

  def saveProject
    @project.save
  end
end

