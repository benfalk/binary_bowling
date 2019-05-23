defmodule BinaryBowling.Game do
  @moduledoc """
  The goal of this module is to store and retrieve bowling
  game data via a tight binary format.  While the underlying
  format of the binary shouldn't really need to be known to
  outside users of the module, for ease of understanding the
  internal layout is described below.

  * first two bytes reprsent the current score
  * the third byte is the games current frame and roll
  * bytes 4 through 12 are the the first 9 frames
  * bytes 13 and 14 are the last frame ( explained below )
  * bytes 15 and beyond are the players name

  Each "normal" frame of a bowling game can be represented
  by at most two possible rolls.  Because each roll can be
  represented by a max value of 10 each roll is split on a
  byte:

     roll 1    roll 2
  [ 0 0 0 0 | 0 0 0 0 ]

  Because the last frame can have an additional roll it's
  composed of two bytes:

     roll 1    roll 2      roll 3    unused
  [ 0 0 0 0 | 0 0 0 0 ] [ 0 0 0 0 | - - - - ]
  """

  alias __MODULE__, as: Game

  @type t :: binary()

  @blank_board <<0::16,  # Score
                 0::2,   # Current Roll
                 0::6,   # Current Frame
                 0::72,  # First 9 Frames
                 0::16>> # Last Frame

  @doc """
  With an optional playername, returns a new bowling game
  """
  @spec new(binary()) :: Game.t()
  def new(playername \\ "") do
    @blank_board <> playername
  end

  @spec score(Game.t()) :: non_neg_integer()
  def score(<<score::16, _::binary>>), do: score

  @spec roll(Game.t(), non_neg_integer()) :: Game.t()
  def roll(game, amount) do
    <<_::16, roll::2, frame::2, _::binary>> = game

    case {frame, roll, amount} do
      _ -> "TODO"
    end
  end
end
