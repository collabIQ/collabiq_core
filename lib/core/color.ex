defmodule Core.Color do
  @chars "abcdef0123456789"

  def random() do
    chars =
      @chars
      |> String.graphemes()

    hex =
      1..6
      |> Enum.map(fn(_x) -> Enum.random(chars) end)
      |> Enum.join("")

    "#" <> hex
  end
end
