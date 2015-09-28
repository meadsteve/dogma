defmodule Dogma.Rules do
  @moduledoc """
  Responsible for running of the appropriate rule set on a given set of scripts
  with the appropriate configuration.
  """

  alias Dogma.Formatter
  alias Dogma.Script

  @default_rule_set Dogma.RuleSet.All

  @doc """
  Runs the rules in the current rule set on the given scripts.
  """
  def test(scripts, formatter) do
    test_set = selected_set
    scripts
      |> Enum.map(&Task.async(fn -> test_script(&1, formatter, test_set) end))
      |> Enum.map(&Task.await/1)
  end


  @doc """
  Returns currently selected rule set, as specified in the mix config.

  Defaults to `Dogma.RuleSet.All`
  """
  def selected_set do
    set_module = Application.get_env :dogma, :rule_set, @default_rule_set
    Code.ensure_compiled set_module
    set_module
  end

  defp test_script(script, formatter, rule_set) do
    rules  = rule_set.rules
    errors = script |> Script.run_tests( rules )
    script = %Script{ script | errors: errors }
    Formatter.script( script, formatter )
    script
  end
end
