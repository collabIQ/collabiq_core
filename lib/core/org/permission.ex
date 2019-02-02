defmodule Core.Org.Permission do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Org.Permission

  @primary_key false
  embedded_schema do
    # 0 = no, 1 = yes
    field(:create_article, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:create_agent, :integer, default: 0)
    field(:create_agent_group, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:create_contact, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:create_contact_group, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:create_workspace, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:publish_article, :integer, default: 0)
    field(:update_tenant, :integer, default: 0)
    field(:update_article, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:update_agent, :integer, default: 0)
    # 0 = no, 1 = all, 2 = yes for groups where the user is a member
    field(:update_agent_group, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:update_contact, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:update_contact_group, :integer, default: 0)
    # 0 = no, 1 = yes
    field(:update_role, :integer, default: 0)
    # 0 = no, 1 = yes all, 2 = yes for workspaces where the user is a member
    field(:update_workspace, :integer, default: 0)
  end

  @required [
    :create_article,
    :create_group,
    :create_user,
    :create_workspace,
    :publish_article,
    :update_article,
    :update_tenant,
    :update_group,
    :update_role,
    :update_user,
    :update_workspace
  ]

  def changeset(%Permission{} = permission, attrs) do
    permission
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
