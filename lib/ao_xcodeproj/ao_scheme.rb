#!/usr/bin/env ruby

class AO_scheme

  def initialize(scheme=nil, main_target=nil, test_target=nil, type=nil)
    @scheme      = scheme
    @main_target = main_target
    @test_target = test_target
    @type        = type

    @scheme.add_build_target(@main_target)
    @scheme.add_build_target(@test_target)
  end

  def test_action(script=nil, config=nil)
    ta = @scheme.doc.root.elements['TestAction']
    ta.attributes['buildConfiguration'] = config

    ta_post_action = ta.add_element("PostActions")
    ta_execute_action = ta_post_action.add_element("ExecutionAction")
    ta_execute_action.attributes["ActionType"] = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction"
    ta_action_content = ta_execute_action.add_element("ActionContent")
    ta_action_content.attributes["title"] = "Run Script"
    ta_action_content.attributes["scriptText"] = script
    ta_env_buildable = ta_action_content.add_element("EnvironmentBuildable")
    ta_buildable_ref = ta_env_buildable.add_element("BuildableReference")
    ta_buildable_ref.attributes["BuildableIdentifier"] = "primary"
    ta_buildable_ref.attributes["BlueprintIdentifier"] = @main_target.uuid
    ta_buildable_ref.attributes["BuildableName"]       = "#{@main_target.name}.app"
    ta_buildable_ref.attributes["BlueprintName"]       = "#{@main_target.name}"
    ta_buildable_ref.attributes["ReferencedContainer"] = "container:#{@main_target.project.path.basename}"

    # Testables (Adds the Test Target)
    ta_testables = ta.elements['Testables']
    ta_testable_reference = ta_testables.add_element('TestableReference')
    ta_testable_reference.attributes['skipped'] = 'NO'
    ta_testable_buildable_ref = ta_testable_reference.add_element('BuildableReference')
    ta_testable_buildable_ref.attributes["BuildableIdentifier"] = "primary"
    ta_testable_buildable_ref.attributes["BlueprintIdentifier"] = @test_target.uuid
    ta_testable_buildable_ref.attributes["BuildableName"]       = "#{@test_target.name}.xctest"
    ta_testable_buildable_ref.attributes["BlueprintName"]       = "#{@test_target.name}"
    ta_testable_buildable_ref.attributes["ReferencedContainer"]  = "container:#{@test_target.project.path.basename}"
  end

  def profile_action
    pa = @scheme.doc.root.elements['ProfileAction']
    pa_build_prod_runnable = pa.add_element('BuildableProductRunnable')
    pa_buildable_ref = pa_build_prod_runnable.add_element('BuildableReference')
    pa_buildable_ref.attributes['BuildableIdentifier'] = 'primary'
    pa_buildable_ref.attributes['BlueprintIdentifier'] = @main_target.uuid
    pa_buildable_ref.attributes['BuildableName']       = "#{@main_target.name}.app"
    pa_buildable_ref.attributes['BlueprintName']       = @main_target.name
    pa_buildable_ref.attributes['ReferenceContainer']  = "container:#{@main_target.project.path.basename}"
  end

  def save(path, name)
    @scheme.save_as(path, name, @type)
  end

end