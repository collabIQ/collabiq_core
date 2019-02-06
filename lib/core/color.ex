defmodule Core.Color do
  import Ecto.Changeset

  @chars "abcdef0123456789"

  def changeset(%{params: %{"color" => color}} = changeset)
      when is_binary(color) and color != "" do
    with {:ok, _color} <- validate(color) do
      changeset
    else
      _ ->
        changeset
        |> add_error(:color, "is invalid")
    end
  end

  def changeset(%{data: %{color: color}} = changeset) when is_binary(color) and color != "" do
    changeset
  end

  def changeset(changeset) do
    color = random()

    changeset
    |> put_change(:color, color)
  end

  def random() do
    chars =
      @chars
      |> String.graphemes()

    hex =
      1..6
      |> Enum.map(fn _x -> Enum.random(chars) end)
      |> Enum.join("")

    "#" <> hex
  end

  def validate(hex) when is_binary(hex) do
    regex = ~r"^#([A-Fa-f0-9]{6})\z"

    if hex =~ regex do
      {:ok, hex}
    else
      :error
    end
  end

  def validate(_), do: :error
end
