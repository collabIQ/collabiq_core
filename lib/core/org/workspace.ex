defmodule Core.Org.Workspace do
  @moduledoc "Module for defining the schema and changesets for workspace objects."
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Group, Session, UserWorkspace, Workspace}
  alias Core.{Color, Error, Query, Repo, Validate}

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

  @spec get_workspace(String.t(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def get_workspace(id, session) do
    from(w in Workspace)
    |> Query.get(id, session, :workspace)
  end

  def create_workspace(attrs, %{tenant_id: tenant_id, permissions: %{create_workspace: 1}, type: "agent"}) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)
    workspace = %Workspace{id: Repo.binary_id()}

    with {:ok, change} <- changeset(workspace, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def create_workspace(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  @spec update_workspace(map(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def update_workspace(%{id: id} = attrs, %{permissions: %{update_workspace: val}, type: "agent"} = session)
      when val in [1, 2] do
    with {:ok, workspace} <- get_workspace(id, session),
         {:ok, change} <- changeset(workspace, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def update_workspace(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  @spec delete_workspace(String.t(), Session) :: {:ok, %Workspace{}} | {:error, [any()]}
  def delete_workspace(id, %{permissions: %{update_workspace: val}, type: "agent"} = session)
      when val in [1, 2] do
    attrs = %{status: "deleted", deleted_at: Timex.now()}

    with {:ok, workspace} <- get_workspace(id, session),
         {:ok, change} <- changeset(workspace, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def delete_workspace(_attrs, _session), do: Error.message({:user, :authorization})

  @spec disable_workspace(String.t(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def disable_workspace(id, %{permissions: %{update_workspace: val}, type: "agent"} = session)
      when val in [1, 2] do
    attrs = %{status: "disabled", deleted_at: nil}

    with {:ok, workspace} <- get_workspace(id, session),
         {:ok, change} <- changeset(workspace, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def disable_workspace(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  @spec enable_workspace(String.t(), Session.t()) :: {:ok, %Workspace{}} | {:error, [any()]}
  def enable_workspace(id, %{permissions: %{update_workspace: val}, type: "agent"} = session)
      when val in [1, 2] do
    attrs = %{status: "active", deleted_at: nil}

    with {:ok, workspace} <- get_workspace(id, session),
         {:ok, change} <- changeset(workspace, attrs),
         {:ok, workspace} <- Repo.put(change) do
      {:ok, workspace}
    else
      error ->
        error
    end
  end

  def enable_workspace(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

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
    |> validate_color()
    |> foreign_key_constraint(:tenant_id)
    |> Validate.change()
  end

  def validate_color(%{params: %{"color" => color}} = changeset) when is_binary(color) and color != ""  do
    with {:ok, _color} <- Validate.color(color) do
      changeset
    else
      _ ->
        changeset
        |> add_error(:color, "is invalid")
    end
  end

  def validate_color(%{data: %{color: color}} = changeset) when is_binary(color) and color != "" do
    changeset
  end

  def validate_color(changeset) do
    color = Color.random

    changeset
    |> put_change(:color, color)
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
