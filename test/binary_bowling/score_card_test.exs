defmodule BinaryBowling.ScoreCardTest do
  use ExUnit.Case, async: true
  alias BinaryBowling.{Game, ScoreCard}

  describe "add_game/2" do
    test "adding a single game" do
      game = Game.new("ben")
      scorecard = ScoreCard.new() |> ScoreCard.add_game(game)
      assert scorecard == <<byte_size(game)::16, game::binary>>
    end

    test "adding a second game" do
      foo = Game.new("foo")
      barr = Game.new("barr")

      scorecard = ScoreCard.new() |> ScoreCard.add_game(foo) |> ScoreCard.add_game(barr)
      assert scorecard == <<byte_size(foo)::16, foo::binary, byte_size(barr)::16, barr::binary>>
    end

    test "adding a blank playername game" do
      assert :missing_playername == ScoreCard.new() |> ScoreCard.add_game(Game.new())
    end

    test "adding a duplicate playername" do
      foo = Game.new("foo")
      scorecard = ScoreCard.new() |> ScoreCard.add_game(foo)
      assert :playername_exists == ScoreCard.add_game(scorecard, foo)
    end
  end

  describe "game_for/2" do
    test "finding a game for given playername" do
      game = Game.new("roflcopter")
      another = Game.new("foobar")
      scorecard = ScoreCard.new() |> ScoreCard.add_game(game) |> ScoreCard.add_game(another)

      assert game == ScoreCard.game_for(scorecard, "roflcopter")
      assert another == ScoreCard.game_for(scorecard, "foobar")
    end

    test "not finding a game for given playername" do
      assert :not_found == ScoreCard.new() |> ScoreCard.game_for("elvis")
    end
  end

  describe "update_game_for/3" do
    test "updates a given players game" do
      game = Game.new("roflcopter")
      another = Game.new("foobar")
      scorecard = ScoreCard.new() |> ScoreCard.add_game(game) |> ScoreCard.add_game(another)

      updated =
        scorecard
        |> ScoreCard.update_game_for("roflcopter", &{:ok, Game.roll(&1, 7)})
        |> ScoreCard.update_game_for("roflcopter", &{:ok, Game.roll(&1, 2)})
        |> ScoreCard.update_game_for("foobar", &{:ok, Game.roll(&1, 4)})

      assert updated |> ScoreCard.game_for("roflcopter") |> Game.score() == 9
      assert updated |> ScoreCard.game_for("foobar") |> Game.score() == 4
    end
  end
end
