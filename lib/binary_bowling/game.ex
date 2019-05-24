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
  @type error_msg :: :game_over

  @blank_board <<
    # Game Over Flag
    0::1,
    # Score
    0::15,
    # Current Roll
    0::2,
    # Current Frame
    0::6,
    # First 9 Frames
    0::72,
    # Last Frame
    0::16
  >>

  @doc """
  With an optional playername, returns a new bowling game
  """
  @spec new(binary()) :: Game.t()
  def new(playername \\ "") do
    @blank_board <> playername
  end

  @spec score(Game.t()) :: non_neg_integer()
  def score(<<_::1, score::15, _::binary>>), do: score

  @spec roll(Game.t(), non_neg_integer()) :: Game.t() | {:error, error_msg}
  def roll(<<1::1, _::binary>>), do: {:error, :game_over}

  def roll(game, amount) when is_integer(amount) do
    game
    |> add_roll(amount)
    |> calculate_score
  end

  @spec details(Game.t()) :: String.t()
  def details(<<over::1, score::15, roll::2, frame::6, frames::bytes-size(11), name::binary>>) do
    frame_formatter = fn
      {r1, r2} -> "#{r1} #{r2} | "
      {r1, r2, r3} -> "#{r1} #{r2} #{r3}"
    end

    """
    Player: #{name}
    Status: #{if over == 0, do: "Playing", else: "Game Over"}
    Ball: #{roll + 1}
    Frame: #{frame + 1}
    Score: #{score}
    Frames: #{each_frame(frames, frame_formatter)}
    """
  end

  defp add_roll(<<s::16, roll::2, frame::6, frames::bytes-size(11), n::binary>>, amount) do
    <<prior::bytes-size(frame), roll1::4, roll2::4, rem::binary>> = frames

    case {frame, roll, amount} do
      {9, 0, 10} ->
        <<s::16, 1::2, frame::6, prior::binary, 10::4, 0::4, rem::binary, n::binary>>

      {9, 1, 10} ->
        <<s::16, 2::2, frame::6, prior::binary, roll1::4, 10::4, rem::binary, n::binary>>

      {9, 1, _} ->
        if amount + roll1 == 10 do
          <<s::16, 2::2, frame::6, prior::binary, roll1::4, amount::4, rem::binary, n::binary>>
        else
          game_over(
            <<s::16, 1::2, frame::6, prior::binary, roll1::4, amount::4, rem::binary, n::binary>>
          )
        end

      {9, 2, _} ->
        game_over(
          <<s::16, 2::2, frame::6, prior::binary, roll1::4, roll2::4, amount::4, 0::4, n::binary>>
        )

      {_, 0, 10} ->
        <<s::16, 0::2, frame + 1::6, prior::binary, 10::4, 0::4, rem::binary, n::binary>>

      {_, 0, _} ->
        <<s::16, 1::2, frame::6, prior::binary, amount::4, 0::4, rem::binary, n::binary>>

      {_, 1, _} ->
        <<s::16, 0::2, frame + 1::6, prior::binary, roll1::4, amount::4, rem::binary, n::binary>>
    end
  end

  defp calculate_score(<<over::1, _::15, postion::8, frames::bytes-size(11), n::binary>>) do
    score =
      frame_list(frames)
      |> Enum.chunk_every(3, 1, [])
      |> Enum.reduce(0, fn
        [{10, 0}, {10, 0}, {a, _}], sum ->
          sum + 20 + a

        [{10, 0}, {a, b}, {_, _}], sum ->
          sum + 10 + a + b

        [{a, b}, {c, _}, _], sum when a + b == 10 ->
          sum + 10 + c

        [{a, b}, _, _], sum ->
          sum + a + b

        _unknown, sum ->
          # IO.inspect(unknown)
          sum
      end)

    <<over::1, score::15, postion::8, frames::binary, n::binary>>
  end

  defp game_over(<<_::1, score::15, rem::binary>>), do: <<1::1, score::15, rem::binary>>

  defp frame_list(frames) do
    each_frame(frames, & &1)
  end

  defp each_frame(frames, fun) do
    do_each_frame(frames, fun, [])
  end

  defp do_each_frame(<<roll1::4, roll2::4, roll3::4, _::4>>, fun, acc) do
    Enum.reverse([fun.({roll1, roll2, roll3}) | acc])
  end

  defp do_each_frame(<<roll1::4, roll2::4, remaining::binary>>, fun, acc) do
    do_each_frame(remaining, fun, [fun.({roll1, roll2}) | acc])
  end
end
