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
      game = Game.new("ben") |> do_rolls(for _ <- 1..20, do: 0)
      # Game is over with no score, frame has been advanced
      # to the last possible roll, and all frame data is empty
      assert <<1::1, 0::15, 1::2, 9::6, 0::88, "ben">> = game
    end

    test "one strike" do
      game = "ben" |> Game.new() |> Game.roll(10)
      assert <<0::1, 10::15, 0::2, 1::6, 10::4, 0::84, "ben">> = game
    end

    test "two strikes" do
      game = "ben" |> Game.new() |> do_rolls([10, 10])
      assert <<0::1, 30::15, 0::2, 2::6, 10::4, 0::4, 10::4, 0::76, "ben">> = game
    end

    test "three strikes" do
      game = "ben" |> Game.new() |> do_rolls([10, 10, 10])
      assert <<0::1, 60::15, 0::2, 3::6, 10::4, 0::4, 10::4, 0::4, 10::4, 0::68, "ben">> = game
    end

    test "12 strikes ( perfect game )" do
      game = Game.new("ben") |> do_rolls(for _ <- 1..12, do: 10)

      assert game |> Game.details() == """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 300
             Frames: 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 10 10
             """
    end

    test "The Bigger Choke" do
      game = Game.new("ben") |> do_rolls(for _ <- 1..11, do: 10) |> Game.roll(9)

      assert game |> Game.details() == """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 299
             Frames: 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 10 9
             """
    end

    test "The Big Choke" do
      game =
        Game.new("ben")
        |> do_rolls(for _ <- 1..8, do: 10)
        |> Game.roll(0)
        |> Game.roll(0)
        |> Game.roll(7)
        |> Game.roll(3)
        |> Game.roll(5)

      assert game |> Game.details() == """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 299
             Frames: 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 10 0 | 0 0 | 7 3 5
             """
    end

    test "The Spare Master" do
      game = Game.new("ben") |> do_rolls(Stream.cycle([9, 1]) |> Stream.take(21))

      assert game |> Game.details() == """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 190
             Frames: 9 1 | 9 1 | 9 1 | 9 1 | 9 1 | 9 1 | 9 1 | 9 1 | 9 1 | 9 1 9
             """
    end

    test "The Sparing Striker" do
      game = Game.new("ben") |> do_rolls(Stream.cycle([9, 1, 10]) |> Stream.take(17))

      assert game |> Game.details() == """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 200
             Frames: 9 1 | 10 0 | 9 1 | 10 0 | 9 1 | 10 0 | 9 1 | 10 0 | 9 1 | 10 9 1
             """
    end

    test "The Big Finish" do
      game = Game.new("ben") |> do_rolls(for _ <- 1..18, do: 1) |> do_rolls([10, 10, 10])

      assert game |> Game.details() === """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 48
             Frames: 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 10 10 10
             """
    end

    test "The Super Swinger" do
      game = Game.new("ben") |> do_rolls(Stream.cycle([10, 10, 0, 0]) |> Stream.take(15))

      assert game |> Game.details() == """
             Player: ben
             Status: Game Over
             Ball: 3
             Frame: 10
             Score: 110
             Frames: 10 0 | 10 0 | 0 0 | 10 0 | 10 0 | 0 0 | 10 0 | 10 0 | 0 0 | 10 10 0
             """
    end
  end

  defp do_rolls(game, rolls) do
    Enum.reduce(rolls, game, fn roll, game ->
      Game.roll(game, roll)
    end)
  end
end
