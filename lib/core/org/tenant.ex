defmodule Core.Org.Tenant do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.{Error, Repo, Validate}
  alias Core.Org.{Tenant, Session}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "tenants" do
    field(:name, :string)
    field(:status, :string, default: "active")
    field(:type, :string, default: "trial")
    field(:deleted_at, :utc_datetime)

    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
  end

  #####################
  ### API Functions ###
  #####################

  @spec get_tenant(Session.t()) :: {:ok, %Tenant{}} | {:error, [any()]}
  def get_tenant(%{t_id: t_id, perms: %{u_ten: 1}, type: "agent"}) do
    from(t in Tenant,
      where: t.id == ^t_id
    )
    |> Repo.single()
    |> Repo.validate_read(:tenant)
  end

  def get_tenant(_session), do: Error.message({:user, :auth})

  def create_tenant(attrs) do
    with {:ok, change} <- changeset(%Tenant{}, attrs),
         {:ok, tenant} <- Repo.put(change) do
      {:ok, tenant}
    else
      error ->
        error
    end
  end

  @spec update_tenant(map(), Session.t()) :: {:ok, %Tenant{}} | {:error, [any()]}
  def update_tenant(attrs, %{perms: %{u_ten: 1}, type: "agent"} = session) do
    with {:ok, tenant} <- get_tenant(session),
         {:ok, change} <- changeset(tenant, attrs),
         {:ok, tenant} <- Repo.put(change) do
      {:ok, tenant}
    else
      error ->
        error
    end
  end

  def update_tenant(_attrs, _session), do: Error.message({:user, :auth})

  @spec delete_tenant(Session.t()) :: {:ok, %Tenant{}} | {:error, [any()]}
  def delete_tenant(%{perms: %{u_ten: 1}, type: "agent"} = session) do
    attrs = %{status: "deleted", deleted_at: Timex.now()}

    with {:ok, tenant} <- get_tenant(session),
         {:ok, change} <- changeset(tenant, attrs),
         {:ok, tenant} <- Repo.put(change) do
      {:ok, tenant}
    else
      error ->
        error
    end
  end

  def delete_tenant(_session), do: Error.message({:user, :auth})

  @spec enable_tenant(Session.t()) :: {:ok, %Tenant{}} | {:error, [any()]}
  def enable_tenant(%{perms: %{u_ten: 1}, type: "agent"} = session) do
    attrs = %{status: "active", deleted_at: nil}

    with {:ok, tenant} <- get_tenant(session),
         {:ok, change} <- changeset(tenant, attrs),
         {:ok, tenant} <- Repo.put(change) do
      {:ok, tenant}
    else
      error ->
        error
    end
  end

  def enable_tenant(_session), do: Error.message({:user, :auth})

  ##################
  ### Changesets ###
  ##################
  @attrs_status ["active", "deleted", "suspended"]
  @attrs_type ["basic", "enterprise", "private", "trial"]
  @optional [:type]
  @required [:name]

  @spec changeset(%Tenant{}, map()) :: {:ok, Ecto.Changeset.t()} | {:error, [any()]}
  def changeset(%Tenant{} = tenant, attrs) do
    tenant
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> validate_inclusion(:status, @attrs_status)
    |> validate_inclusion(:type, @attrs_type)
    |> unique_constraint(:name)
    |> Validate.change()
  end
end
