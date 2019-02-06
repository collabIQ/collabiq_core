defmodule Core.UUID do
  alias Core.Error

  def bin_gen() do
    {:ok, Ecto.UUID.bingenerate()}
  end

  def string_gen() do
    Ecto.UUID.bingenerate()
    |> Ecto.UUID.load()
    |> case do
      {:ok, uuid_string} ->
        {:ok, uuid_string}

      _ ->
        {:error, Error.message({})}
    end
  end

  def bin_to_string(bin) do
    bin
    |> Ecto.UUID.load()
    |> case do
      {:ok, uuid_string} ->
        {:ok, uuid_string}

      _ ->
        {:error, Error.message({})}
    end
  end

  def string_to_bin(string) do
    string
    |> Ecto.UUID.dump()
    |> case do
      {:ok, uuid_bin} ->
        {:ok, uuid_bin}

      _ ->
        {:error, Error.message({})}
    end
  end

  def base_to_string(base) do
    with {:ok, bin} <- url_decode(base),
         {:ok, string} <- bin_to_string(bin) do
      {:ok, string}
    else
      error ->
        error
    end
  end

  def string_to_base(string) do
    with {:ok, bin} <- string_to_bin(string),
         {:ok, base} <- url_encode(bin) do
      {:ok, base}
    else
      error ->
        error
    end
  end

  def url_encode(bin) do
    {:ok, Base.url_encode64(bin, padding: false)}
  end

  def url_decode(base) do
    case Base.url_decode64(base, padding: false) do
      {:ok, bin} ->
        {:ok, bin}

      _ ->
        {:error, Error.message({})}
    end
  end
end
