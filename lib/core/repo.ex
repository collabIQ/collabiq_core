defmodule Core.Repo do
  use Ecto.Repo, otp_app: :core
  alias Core.{Error, Repo}

  def init(_, opts) do
    {:ok, opts}
  end

  def binary_id() do
    case Ecto.UUID.bingenerate() |> Ecto.UUID.load() do
      {:ok, binary_id} ->
        binary_id
      _ ->
        {:error, Error.message({})}
    end
  end

  def destroy(changeset) do
    case Repo.delete(changeset) do
      {:ok, result} ->
        {:ok, result}
      {:error, change} ->
        {:error, Error.message(change)}
    end
  end

  def put(changeset) do
    case Repo.insert_or_update(changeset) do
      {:ok, result} ->
        {:ok, result}
      {:error, change} ->
        {:error, Error.message(change)}
    end
  end
end