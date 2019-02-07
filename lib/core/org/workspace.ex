defmodule Core.Org.Workspace do
  @moduledoc "Module for defining the schema and changesets for workspace objects."
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Group, Session, UserWorkspace, Workspace}
  alias Core.{Color, Error, Query, Repo, UUID, Validate}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "workspaces" do
    field(:tenant_id, :binary_id)
    field(:description, :string)
    field(:name, :string)
    field(:notes, :string)
    field(:status, :string, default: "active")
    field(:color, :string)
    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
    field(:deleted_at, :utc_datetime)

    has_many(:groups, Group)
    has_many(:users_workspaces, UserWorkspace, on_replace: :delete)
    has_many(:users, through: [:users_workspaces, :user])
  end

  #####################
  ### API Functions ###
  #####################
  @spec list_workspaces(map(), Session.t()) :: {:ok, [%Workspace{}, ...]} | {:error, [any()]}
  def list_workspaces(args, session) do
    from(w in Workspace)
    |> Query.list(args, session, :workspaces)
  end

  @spec get_workspace(map(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def get_workspace(args, session) do
    from(w in Workspace)
    |> Query.get(args, session, :workspace)
  end

  def create_workspace(attrs, %{tenant_id: tenant_id, permissions: %{create_workspace: 1}, type: "agent"}) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)

    with {:ok, binary_id} <- UUID.bin_gen(),
         {:ok, change} <- changeset(%Workspace{id: binary_id}, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def create_workspace(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  @spec update_workspace(map(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def update_workspace(attrs, session) do
    attrs
    |> modify_workspace(session)
  end


  @spec delete_workspace(map(), Session) :: {:ok, %Workspace{}} | {:error, [any()]}
  def delete_workspace(%{id: id}, session) do
    %{status: "deleted", deleted_at: Timex.now(), id: id}
    |> modify_workspace(session)
  end

  @spec disable_workspace(map(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def disable_workspace(%{id: id}, session) do
    %{status: "disabled", deleted_at: nil, id: id}
    |> modify_workspace(session)
  end

  @spec enable_workspace(map(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def enable_workspace(%{id: id}, session) do
    %{status: "active", deleted_at: nil, id: id}
    |> modify_workspace(session)
  end

  def modify_workspace(%{id: id} = attrs, %{permissions: %{update_workspace: v}, type: "agent"} = session) when v in [1,2] do
    with {:ok, workspace} <- get_workspace(id, session),
         {:ok, change} <- changeset(workspace, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def modify_workspace(_id, _session), do: {:error, Error.message({:user, :authorization})}

  ##################
  ### Changesets ###
  ##################
  @attrs_status ["active", "deleted", "disabled"]
  @optional [:color, :deleted_at, :description, :notes, :status]
  @required [:tenant_id, :name]

  @spec changeset(%Workspace{}, map()) :: {:ok, Ecto.Changeset.t()} | {:error, [any()]}
  def changeset(%Workspace{} = workspace, attrs) do
    workspace
    |> Repo.preload([:users_workspaces])
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> validate_inclusion(:status, @attrs_status)
    |> Color.changeset()
    |> foreign_key_constraint(:tenant_id)
    |> Validate.change()
  end



  ########################
  ### Helper Functions ###
  ########################

  def validate_update_permissions(id, %{permissions: %{update_workspace: p}, type: "agent"} = session)
      when p in [1, 2] do
    with {:ok, workspace} <- get_workspace(id, session) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end
end
