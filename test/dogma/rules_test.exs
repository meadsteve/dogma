defmodule Dogma.RulesTest do
  use ExUnit.Case

  alias Dogma.Rules
  alias Dogma.Script
  alias Dogma.Test.AssertingFormatter

  @formater_for_testing Dogma.Formatter.Simple

  test "returns empty list when given no scripts" do
    result = Rules.test([], @formater_for_testing)
    assert result == []
  end

  test "Config can be used to define the rules used" do
    Application.put_env(:dogma, :rule_set, Dogma.RuleSets.FakeRuleSet)
    single_script = %Script{}
    expected_script_after_run = %Script{errors: [:always_fake_error]}

    result = Rules.test([single_script], @formater_for_testing)

    assert result == [expected_script_after_run]
  end

  test "Formatter.script is called by Rules.test" do
    Application.put_env(:dogma, :rule_set, Dogma.RuleSets.FakeRuleSet)
    single_script = %Script{}
    script_after_run = %Script{errors: [:always_fake_error]}

    AssertingFormatter.start_listening
    Rules.test([single_script], AssertingFormatter)

    AssertingFormatter.assert_script_called_with script_after_run
  end

end

defmodule Dogma.RuleSets.FakeRuleSet do
  def rules, do: [{FakeRule}]
end

defmodule Dogma.Rule.FakeRule do
  def test(_script, _config = [] \\ []) do
    [:always_fake_error]
  end
end

defmodule Dogma.Test.AssertingFormatter do
  import ExUnit.Assertions

  def start_listening do
    Process.register self, __MODULE__
  end

  def script(script, _formatter \\ nil) do
    send __MODULE__, {:script, script}
    ""
  end

  def assert_script_called_with(expected_script) do
    receive do
      {:script, script}  -> assert expected_script == script
    after
      0_500 -> assert false, "formatter not called"
    end
  end
end