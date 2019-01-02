defmodule Core.Org.Role do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Permission, Role}
  alias Core.{Error, Repo, Validate}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "roles" do
    field(:tenant_id, :binary_id)
    field(:name, :string)
    embeds_one(:permissions, Permission, on_replace: :update)
    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
  end

  #####################
  ### API Functions ###
  #####################

  def list_roles(%{tenant_id: tenant_id, permissions: %{update_role: 1}, type: "agent"}) do
    query =
      from(r in Role,
        where: r.tenant_id == ^tenant_id
      )

    query
    |> Repo.all()
    |> Validate.ecto_read(:roles)
  end
  def list_roles(_session), do: {:error, Error.message({:user, :authorization})}
  def get_role(id, %{tenant_id: tenant_id, permissions: %{update_role: 1}, type: "agent"}) do
    query =
      from(r in Role,
        where: r.tenant_id == ^tenant_id,
        where: r.id == ^id
      )

    query
    |> Repo.one()
    |> Validate.ecto_read(:role)
  end

  def get_role(_id, _session), do: {:error, Error.message({:user, :authorization})}

  def create_role(attrs, %{tenant_id: tenant_id, permissions: %{update_role: 1}, type: "agent"}) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)

    with {:ok, change} <- changeset(%Role{}, attrs),
         {:ok, role} <- Repo.put(change) do
      {:ok, role}
    else
      error ->
        error
    end
  end

  def create_role(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def update_role(%{id: id} = attrs, %{tenant_id: tenant_id} = session) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)

    with {:ok, role} <- get_role(id, session),
         {:ok, change} <- changeset(role, attrs),
         {:ok, role} <- Repo.put(change) do
      {:ok, role}
    else
      error ->
        error
    end
  end

  def delete_role(id, session) do
    attrs = %{}

    with {:ok, role} <- get_role(id, session),
         {:ok, change} <- changeset(role, attrs),
         {:ok, role} <- Repo.destroy(change) do
      {:ok, role}
    else
      error ->
        error
    end
  end

  ##################
  ### Changesets ###
  ##################

  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:tenant_id, :name])
    |> cast_embed(:permissions)
    |> validate_required([:tenant_id, :name, :permissions])
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:role, name: :users_role_id_fkey, message: Error.error_message(:role_users))
    |> unique_constraint(:name, name: :roles_tenant_id_name_index)
    |> Validate.change()
  end
end
