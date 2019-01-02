defmodule Core.Org.UserGroupNotify do
  @moduledoc "Module for defining the schema and changesets for workspace objects."
  use Ecto.Schema
  alias Core.Org.{Group, Tenant, User, Workspace}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_groups_notify" do
    belongs_to(:tenant, Tenant)
    belongs_to(:group, Group)
    belongs_to(:user, User)
    belongs_to(:workspace, Workspace)
  end
end
