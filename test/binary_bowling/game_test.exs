defmodule BinaryBowling.GameTest do
  use ExUnit.Case, async: true
  alias BinaryBowling.Game

  test "new/0" do
    # 112 bits == 14 bytes
    assert <<0::112>> = Game.new()
  end

  test "new/1" do
    assert <<0::112, "ben">> = Game.new("ben")
  end

  test "score/1" do
    assert 0 == Game.new |> Game.score
  end
end
