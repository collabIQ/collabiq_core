defmodule Core.Repo do
  use Ecto.Repo,
    otp_app: :core,
    adapter: Ecto.Adapters.Postgres

  alias Core.Kb.Article
  alias Core.Org.{Group, Role, Session, Tenant, User, Workspace}
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

  def validate_read(%Tenant{} = data, _type), do: {:ok, data}
  def validate_read(%Article{} = data, _type), do: {:ok, data}
  def validate_read([%Article{} | _] = data, _type), do: {:ok, data}
  def validate_read(%Group{} = data, _type), do: {:ok, data}
  def validate_read([%Group{} | _] = data, _type), do: {:ok, data}
  def validate_read(%Role{} = data, _type), do: {:ok, data}
  def validate_read([%Role{} | _] = data, _type), do: {:ok, data}
  def validate_read(%Session{} = data, _type), do: {:ok, data}
  def validate_read(%User{} = data, _type), do: {:ok, data}
  def validate_read([%User{} | _] = data, _type), do: {:ok, data}
  def validate_read(%Workspace{} = data, _type), do: {:ok, data}
  def validate_read([%Workspace{} | _] = data, _type), do: {:ok, data}
  def validate_read(_, :login) do
    {:error, Error.message({:login, :invalid})}
  end
  def validate_read([], type) do
    {:error, Error.message({type, :not_found})}
  end
  def validate_read(struct, type) when is_nil(struct) do
    {:error, Error.message({type, :not_found})}
  end
  def validate_read(_, _) do
    {:error, Error.message({})}
  end
end
