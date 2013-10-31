#!/usr/bin/env ruby

class AO_scheme

  def initialize(scheme=nil, main_target=nil, test_target=nil, config="Debug")
    @scheme      = scheme
    @main_target = main_target
    @test_target = test_target
    @config      = config

    # @scheme.add_build_target(@main_target)
    # @scheme.add_build_target(@test_target)
  end

  def add_target(target=@main_target)

    build_action = @scheme.doc.root.elements['BuildAction']
    build_action_entries = build_action.add_element("BuildActionEntries")

    build_action_entry = build_action_entries.add_element('BuildActionEntry')
    build_action_entry.attributes['buildForTesting']      = 'YES'
    build_action_entry.attributes['buildForRunning']      = 'YES'
    build_action_entry.attributes['buildForProfiling']    = 'YES'
    build_action_entry.attributes['buildForArchiving']    = 'YES'
    build_action_entry.attributes['buildForAnalyzing']    = 'YES'

    buildable_reference(build_action_entry, "app")

  end

  def buildable_reference(element, type, macro_exp=false)
    target = (@main_target if type == "app") || (@test_target if type == "xctest")
    type = ("#{@main_target.name}.app" if type == "app") || ("#{@test_target.name}.xctest" if type == "xctest")
    buildable_reference = (element.add_element('BuildableReference') if macro_exp == false) || (element.add_element('MacroExpansion').add_element('BuildableReference') if macro_exp == true)


    buildable_reference.attributes['BuildableIdentifier'] = 'primary'
    buildable_reference.attributes['BlueprintIdentifier'] = target.uuid
    buildable_reference.attributes['BuildableName']       = type
    buildable_reference.attributes['BlueprintName']       = target.name
    buildable_reference.attributes['ReferencedContainer'] = "container:#{target.project.path.basename}"

  end


  def test_action(script=nil)
    ta = @scheme.doc.root.elements['TestAction']
    ta.attributes['buildConfiguration'] = @config

    ta_testables = ta.elements['Testables']
    ta_testable_reference = ta_testables.add_element('TestableReference')
    ta_testable_reference.attributes['skipped'] = 'NO'
    buildable_reference(ta_testable_reference, "xctest")


    ta_post_action = ta.add_element("PostActions")
    ta_execute_action = ta_post_action.add_element("ExecutionAction")
    ta_execute_action.attributes["ActionType"] = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction"
    ta_action_content = ta_execute_action.add_element("ActionContent")
    ta_action_content.attributes["title"] = "Run Script"
    ta_action_content.attributes["scriptText"] = script
    ta_env_buildable = ta_action_content.add_element("EnvironmentBuildable")
    buildable_reference(ta_env_buildable, "app")

    buildable_reference(ta, "app", true)

  end

  def profile_action
    pa = @scheme.doc.root.elements['ProfileAction']
    pa_build_prod_runnable = pa.add_element('BuildableProductRunnable')
    buildable_reference(pa_build_prod_runnable, "app")
  end

  def launch_action
    la = @scheme.doc.root.elements['LaunchAction']
    la.attributes["buildConfiguration"] = @config
    la_buildable_product_runnable = la.add_element("BuildableProductRunnable")

    buildable_reference(la_buildable_product_runnable, "app")
  end

  def save(path, name, shared=false)
    @scheme.save_as(path, name, shared)
  end

end
