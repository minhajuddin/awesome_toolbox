defmodule AwesomeToolboxTest do
  use ExUnit.Case
  doctest AwesomeToolbox

  test "greets the world" do
    assert AwesomeToolbox.hello() == :world
  end
end
