defmodule Core.Org.Permission do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Org.Permission

  @primary_key false
  embedded_schema do
    # creat article
    field(:c_art, :integer, default: 0)
    # create agent
    field(:c_agent, :integer, default: 0)
    # create agent group
    field(:c_ag, :integer, default: 0)
    # create contact
    field(:c_con, :integer, default: 0)
    # create contact group
    field(:c_cg, :integer, default: 0)
    # create workspace
    field(:c_ws, :integer, default: 0)
    # publish article
    field(:pub_art, :integer, default: 0)
    # update tenant
    field(:u_ten, :integer, default: 0)
    # update article
    field(:u_art, :integer, default: 0)
    # update agent
    field(:u_agent, :integer, default: 0)
    # update agent group
    field(:u_ag, :integer, default: 0)
    # update contact
    field(:u_con, :integer, default: 0)
    # update contact group
    field(:u_cg, :integer, default: 0)
    # manage roles
    field(:m_role, :integer, default: 0)
    # update workspace
    field(:u_ws, :integer, default: 0)
    # create tag
    field(:c_tag, :integer, default: 0)
    # update tag
    field(:u_tag, :integer, default: 0)
  end

  @required [
    :c_art,
    :c_ag,
    :c_agent,
    :c_cg,
    :c_con,
    :c_ws,
    :pub_art,
    :u_ag,
    :u_agent,
    :u_cg,
    :u_con,
    :u_art,
    :u_ten,
    :m_role,
    :u_ws,
    :c_tag,
    :u_tag
  ]

  def changeset(%Permission{} = permission, attrs) do
    permission
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
