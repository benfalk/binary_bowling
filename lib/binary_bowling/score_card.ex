defmodule BinaryBowling.ScoreCard do
  @moduledoc """
  This is a simple binary storage wrapper for BinaryBowling.Game

  It hinges on the fact that every game has a player name specified
  and that each name is unique.
  """

  alias __MODULE__, as: ScoreCard
  alias BinaryBowling.Game

  @type t :: binary()

  def new, do: <<>>

  @spec add_game(ScoreCard.t(), Game.t()) :: ScoreCard.t()
  def add_game(scorecard, game) do
    with name when byte_size(name) > 0 <- Game.playername(game),
         :not_found <- ScoreCard.game_for(scorecard, name) do
      <<scorecard::binary, byte_size(game)::16, game::binary>>
    else
      "" -> :missing_playername
      _ -> :playername_exists
    end
  end

  @spec game_for(ScoreCard.t(), String.t()) :: Game.t() | :not_found
  def game_for(scorecard, playername) do
    with {:ok, _, game, _} <- seek_game_for(scorecard, playername), do: game
  end

  @spec update_game_for(ScoreCard.t(), String.t(), (Game.t() -> {:ok, Game.t()})) ::
          ScoreCard.t() | :not_found
  def update_game_for(scorecard, playername, fun) do
    with {:ok, prev, game, rem} <- seek_game_for(scorecard, playername),
         {:ok, updated} <- fun.(game) do
      <<prev::binary, byte_size(updated)::16, updated::binary, rem::binary>>
    end
  end

  defp seek_game_for(scorecard, playername), do: seek_game_for(<<>>, scorecard, playername)

  defp seek_game_for(_, <<>>, _), do: :not_found

  defp seek_game_for(searched, <<size::16, game::bytes-size(size), rem::binary>>, playername) do
    if Game.playername(game) == playername do
      {:ok, searched, game, rem}
    else
      seek_game_for(<<searched::binary, size::16, game::binary>>, rem, playername)
    end
  end
end
