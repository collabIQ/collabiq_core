defmodule Core.Org.UserWorkspace do
  @moduledoc "Module for defining the schema and changesets for workspace objects."
  use Ecto.Schema
  alias Core.Org.{Tenant, User, Workspace}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_workspaces" do
    belongs_to(:tenant, Tenant)
    belongs_to(:workspace, Workspace)
    belongs_to(:user, User)
  end
end
