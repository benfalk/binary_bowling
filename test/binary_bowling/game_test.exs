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
    assert 0 == Game.new() |> Game.score()
  end

  describe "roll/2" do
    test "twenty gutter balls" do
      game =
        Enum.reduce(1..20, Game.new("ben"), fn _, game ->
          Game.roll(game, 0)
        end)

      # Game is over with no score, frame has been advanced
      # to the last possible roll, and all frame data is empty
      assert <<1::1, 0::15, 1::2, 9::6, 0::88, "ben">> = game
    end

    test "one strike" do
      game = "ben" |> Game.new() |> Game.roll(10)
      assert <<0::1, 10::15, 0::2, 1::6, 10::4, 0::84, "ben">> = game
    end
  end
end
