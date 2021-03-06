defmodule Core.Org.Group do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{AgentGroup, ContactGroup, Group, Session, UserGroup, Workspace}
  alias Core.{Query, Repo, Validate}

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

  def list_groups(args, %{t_id: t_id} = sess) do
    from(g in Group,
      where: g.tenant_id == ^t_id
    )
    |> Query.workspace_scope(sess, :group)
    |> Query.admin(args, sess, :group)
    |> Query.filter(args, :group)
    |> Query.sort(args, :group)
    |> Repo.full()
    |> Repo.validate_read(:groups)
  end

  def get_group(args, %{t_id: t_id} = sess) do
    from(g in Group,
      where: g.tenant_id == ^t_id
    )
    |> Query.workspace_scope(sess, :group)
    |> Query.filter(args, :group)
    |> Repo.single()
    |> Repo.validate_read(:group)
  end

  ##################
  ### Changesets ###
  ##################
  @attrs_status ["active", "deleted", "disabled"]
  @optional [:description, :email, :phone, :status]
  @required [:name]

  @spec changeset(%Group{}, map(), Session.t()) :: {:ok, Ecto.Changeset.t()} | {:error, [any(), ...]}

  def changeset(%Group{} = group, attrs, sess) do
    group
    |> Repo.preload([:users_groups])
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> validate_inclusion(:status, @attrs_status)
    |> change_users_groups(sess)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:workspace_id)
    |> Validate.change()
  end

  def change_users_groups(
        %{data: %{type: type}, params: %{"users" => _users}} = changeset,
        sess
      ) do
    case type do
      "agent" ->
        AgentGroup.change_users_groups(changeset, sess)

      "contact" ->
        ContactGroup.change_users_groups(changeset, sess)
    end
  end

  def change_users_groups(changeset, _sess), do: changeset
end
