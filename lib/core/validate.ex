defmodule Core.Validate do
  @moduledoc false
  alias Core.Error
  alias Core.Org.{Assignee, Group, Role, Session, Tenant, User, Workspace}

  def binary_id(id) when is_binary(id) do
    regex = ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
    if id =~ regex do
      {:ok, id}
    else
      :error
    end
  end
  def binary_id(_), do: :error

  def color(hex) when is_binary(hex) do
    regex = ~r"^#([A-Fa-f0-9]{6})\z"
    if hex =~ regex do
      {:ok, hex}
    else
      :error
    end
  end
  def color(_), do: :error

  @spec change(Ecto.Changeset.t()) :: {:ok, Ecto.Changeset.t()} | {:error, list()}
  def change(change) do
    case change.valid? do
      true -> {:ok, change}
      _    -> {:error, Error.message(change)}
    end
  end

  def changeset(change) do
    case change.valid? do
      true -> :ok
      _    -> Error.message(change)
    end
  end

  @spec account_match(any(), any()) :: :ok | {:error, [any()]}
  def account_match(a, b) do
    case a === b do
      true ->
        :ok
      _ ->
        {:error, Error.message({:user, :authorization})}
    end
  end

  def ecto_read(%Tenant{} = data, _type), do: {:ok, data}
  def ecto_read(%Assignee{} = data, _type), do: {:ok, data}
  def ecto_read([%Assignee{} | _] = data, _type), do: {:ok, data}
  def ecto_read(%Group{} = data, _type), do: {:ok, data}
  def ecto_read([%Group{} | _] = data, _type), do: {:ok, data}
  def ecto_read(%Role{} = data, _type), do: {:ok, data}
  def ecto_read([%Role{} | _] = data, _type), do: {:ok, data}
  def ecto_read(%Session{} = data, _type), do: {:ok, data}
  def ecto_read(%User{} = data, _type), do: {:ok, data}
  def ecto_read([%User{} | _] = data, _type), do: {:ok, data}
  def ecto_read(%Workspace{} = data, _type), do: {:ok, data}
  def ecto_read([%Workspace{} | _] = data, _type), do: {:ok, data}
  def ecto_read(_, :login) do
    {:error, Error.message({:login, :invalid})}
  end
  def ecto_read([], type) do
    {:error, Error.message({type, :not_found})}
  end
  def ecto_read(struct, type) when is_nil(struct) do
    {:error, Error.message({type, :not_found})}
  end
  def ecto_read(_, _) do
    {:error, Error.message({})}
  end
end
