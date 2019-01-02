defmodule Core.Org.Group do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{AgentGroup, ContactGroup, Group, Session, UserGroup, Workspace}
  alias Core.{Error, Repo, Validate}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "groups" do
    field(:tenant_id, :binary_id)
    field(:description, :string)
    field(:email, :string)
    field(:name, :string)
    field(:phone, :string)
    field(:status, :string, default: "active")
    field(:type, :string, default: "contact")
    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)

    belongs_to(:workspace, Workspace)
    has_many(:users_groups, UserGroup, on_replace: :delete)
    has_many(:users, through: [:users_groups, :user])
  end

  #####################
  ### API Functions ###
  #####################

  def list_groups(%{admin: admin} = args, %{
        tenant_id: tenant_id,
        permissions: permissions,
        workspaces: workspaces
      }) do
    query =
      if admin do
        case permissions do
          %{update_workspace: 1} ->
            from(g in Group,
              where: g.tenant_id == ^tenant_id
            )

          _ ->
            from(g in Group,
              where: g.tenant_id == ^tenant_id,
              where: g.workspace_id in ^workspaces
            )
        end
      else
        from(g in Group,
          where: g.tenant_id == ^tenant_id,
          where: g.workspace_id in ^workspaces
        )
      end

    query
    |> filter_groups(args)
    |> sort_groups(args)
    |> Repo.all()
    |> Validate.ecto_read(:groups)
  end

  def list_groups(_args, _session), do: {:error, Error.message({:user, :authorization})}

  def get_group(id, %{tenant_id: tenant_id, permissions: permissions, workspaces: workspaces}) do
    query =
      case permissions do
        %{update_workspace: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.tenant_id == ^tenant_id
          )

        _ ->
          from(g in Group,
            where: g.id == ^id,
            where: g.tenant_id == ^tenant_id,
            where: g.workspace_id in ^workspaces
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
  @optional [:description, :email, :phone, :status]
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

  def change_users_groups(
        %{data: %{type: type}, params: %{"users" => _users}} = changeset,
        session
      ) do
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

      {:status, [_|_] = status}, query ->
        from(q in query,
          where: q.status in ^status
        )

      {:status, _}, query ->
        query

      {:type, [_|_] = type}, query ->
        from(q in query,
          where: q.type in ^type
        )

      {:type, _}, query ->
        query

      {:workspaces, [_|_] = workspaces}, query ->
        from(q in query,
          where: q.workspace_id in ^workspaces
        )

      {:workspaces, _}, query ->
        query
    end)
  end

  def filter_groups(query, _filter), do: query

  def sort_groups(query, %{sort: %{field: field, order: "asc"}}) when field in ["created", "name", "status", "type", "updated"] do
    case field do
      "created" ->
        from(q in query,
          order_by: [asc: :created_at]
        )

      "name" ->
        from(q in query,
          order_by: fragment("lower(?) ASC", q.name)
        )

      "status" ->
        from(q in query,
          order_by: [asc: :status],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "type" ->
        from(q in query,
          order_by: [asc: :type],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "updated" ->
        from(q in query,
          order_by: [asc: :updated_at]
        )
    end
  end

  def sort_groups(query, %{sort: %{field: field, order: "desc"}}) when field in ["created", "name", "status", "type", "updated"] do
    case field do
      "created" ->
        from(q in query,
          order_by: [desc: :created_at]
        )

      "name" ->
        from(q in query,
          order_by: fragment("lower(?) DESC", q.name)
        )

      "status" ->
        from(q in query,
          order_by: [desc: :status],
          order_by: fragment("lower(?) DESC", q.name)
        )

      "type" ->
        from(q in query,
          order_by: [desc: :type],
          order_by: fragment("lower(?) DESC", q.name)
        )

      "updated" ->
        from(q in query,
          order_by: [desc: :updated_at]
        )
    end
  end

  def sort_groups(query, _args) do
    from(q in query,
      order_by: fragment("lower(?) ASC", q.name)
    )
  end
end
