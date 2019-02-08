defmodule Core.Org.Role do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Permission, Role}
  alias Core.{Error, Query, Repo, UUID, Validate}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "roles" do
    field(:tenant_id, :binary_id)
    field(:name, :string)
    field(:type, :string, default: "contact")
    embeds_one(:permissions, Permission, on_replace: :update)
    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  #####################
  ### API Functions ###
  #####################

  def list_roles(attrs, %{perms: %{u_role: 1}, type: "agent"} = sess) do
    from(r in Role)
    |> Query.list(attrs, sess, :roles)
  end

  def list_roles(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  defp edit_role(attrs, sess) do
    from(r in Role)
    |> Query.edit(attrs, sess, :role)
  end

  def get_role(attrs, %{perms: %{u_role: 1}, type: "agent"} = sess) do
    from(r in Role)
    |> Query.get(attrs, sess, :role)
  end

  def get_role(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  def create_role(attrs, %{t_id: t_id, perms: %{m_role: 1}, type: "agent"}) do
    with {:ok, binary_id} <- UUID.bin_gen(),
         {:ok, change} <- changeset(%Role{id: binary_id, tenant_id: t_id}, attrs),
         {:ok, role} <- Repo.put(change) do
      {:ok, role}
    else
      error ->
        error
    end
  end

  def create_role(_attrs, _session), do: {:error, Error.message({:user, :auth})}

  def update_role(attrs, sess) do
    attrs
    |> modify_role(sess)
  end

  def delete_role(%{id: id}, sess) do
    %{id: id}
    |> modify_role(sess)
  end

  def modify_role(attrs, %{perms: %{u_role: 1}, type: "agent"} = sess) do
    with {:ok, role} <- edit_role(attrs, sess),
         {:ok, change} <- changeset(role, attrs),
         {:ok, role} <- Repo.destroy(change) do
      {:ok, role}
    else
      error ->
        error
    end
  end

  def modify_role(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  ##################
  ### Changesets ###
  ##################

  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name, :type])
    |> cast_embed(:permissions)
    |> validate_required([:name, :permissions, :type])
    |> foreign_key_constraint(:role, name: :users_role_id_fkey, message: Error.error_message(:role_users))
    |> unique_constraint(:name, name: :roles_tenant_id_name_index)
    |> Validate.change()
  end
end
