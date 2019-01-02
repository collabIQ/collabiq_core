defmodule Core.Work.Task do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{AgentGroup, ContactGroup, Group, Session, UserGroup, Workspace}
  alias Core.Work.{Task}
  alias Core.{Error, Repo, Validate}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do
    field(:tenant_id, :binary_id)
    field(:assignee_id, :binary_id, default: nil)
    field(:ticket_id, :binary_id, default: nil)
    field(:workspace_id, :binary_id, default: nil)
    field(:description, :string)
    field(:status, :string, default: "open")
    field(:title, :string)
    field(:type, :string, default: "task")
    field(:due_at, :utc_datetime, usec: false)
    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
  end

  #####################
  ### API Functions ###
  #####################

  def list_groups(args, %{tenant_id: tenant_id, groups: groups, permissions: permissions, workspaces: workspaces}) do
    query =
      case permissions do
        %{update_group: 1, update_workspace: 1} ->
          from(g in Group,
            where: g.tenant_id == ^tenant_id
          )

        %{update_group: 1} ->
          from(g in Group,
            where: g.tenant_id == ^tenant_id,
            where: g.workspace_id in ^workspaces
          )

        _ ->
          from(g in Group,
            where: g.tenant_id == ^tenant_id,
            where: g.id in ^groups
          )
      end

    query
    |> filter_groups(args)
    |> sort_groups(args)
    |> Repo.all()
    |> Validate.ecto_read(:groups)
  end

  def list_groups(_args, _session), do: {:error, Error.message({:user, :authorization})}

  def get_group(id, %{tenant_id: tenant_id, groups: groups, permissions: permissions, workspaces: workspaces}) do
    query =
      case permissions do
        %{update_group: 1, update_workspace: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.tenant_id == ^tenant_id
          )

        %{update_group: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.tenant_id == ^tenant_id,
            where: g.workspace_id in ^workspaces
          )

        _ ->
          from(g in Group,
            where: g.id == ^id,
            where: g.tenant_id == ^tenant_id,
            where: g.id in ^groups
          )
      end

    query
    |> Repo.one()
    |> Validate.ecto_read(:group)
  end

  def get_group(_id, _session), do: {:error, Error.message({:user, :authorization})}

  ##################
  ### Changesets ###
  ##################
  @attrs_status ["active", "deleted", "disabled"]
  @optional [:description, :email, :status]
  @required [:tenant_id, :name, :workspace_id]

  @spec changeset(%Group{}, map(), Session.t()) :: {:ok, Ecto.Changeset.t()} | {:error, [any()]}

  def changeset(%Group{} = group, attrs, session) do
    group
    |> Repo.preload([:users_groups])
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> validate_inclusion(:status, @attrs_status)
    |> change_users_groups(session)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:workspace_id)
    |> Validate.change()
  end

  def change_users_groups(%{data: %{type: type}, params: %{"users" => _users}} = changeset, session) do
    case type do
      "agent" ->
        AgentGroup.change_users_groups(changeset, session)

      "contact" ->
        ContactGroup.change_users_groups(changeset, session)
    end
  end

  def change_users_groups(changeset, _session), do: changeset

  ########################
  ### Helper Functions ###
  ########################
  def filter_groups(query, %{filter: filter}) do
    filter
    |> Enum.reduce(query, fn
      {:name, name}, query ->
        from(q in query,
          where: ilike(q.name, ^"%#{String.downcase(name)}%")
        )

      {:status, status}, query ->
        from(q in query,
          where: q.status == ^to_string(status)
        )
    end)
  end

  def filter_groups(query, _filter), do: query

  def sort_groups(query, %{sort: %{field: field, order: order}}) when field in [:created_at, :name, :updated_at] do
    query
    |> order_by({^order, ^field})
  end

  def sort_groups(query, _args) do
    query
    |> order_by({:asc, :name})
  end
end
