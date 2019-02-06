defmodule Core.Repo do
  use Ecto.Repo,
    otp_app: :core,
    adapter: Ecto.Adapters.Postgres

  alias Core.{Error, Repo, UUID}

  def init(_, opts) do
    {:ok, opts}
  end

  def binary_id() do
    Ecto.UUID.bingenerate()
    |> Ecto.UUID.load()
    |> case do
      {:ok, binary_id} ->
        binary_id

      _ ->
        {:error, Error.message({})}
    end
  end

  def single(query) do
    case Repo.one(query) do
      nil ->
        nil

      struct ->
        replace_id_in_struct(struct)
    end
  end

  def full(query) do
    case Repo.all(query) do
      [] ->
        []

      list ->
        Enum.map(list, &replace_id_in_struct/1)
    end
  end

  def replace_id_in_struct(struct) do
    with {:ok, base_id} <- UUID.string_to_base(struct.id),
         result <- Map.put(struct, :id, base_id) do
      result
    else
      error ->
        error
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
