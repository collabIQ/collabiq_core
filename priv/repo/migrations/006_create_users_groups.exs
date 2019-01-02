defmodule Core.Repo.Migrations.CreateUsersGroups do
  use Ecto.Migration

  def change do
    create table(:users_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :group_id, references(:groups, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all, type: :binary_id), null: false
    end

    create unique_index(:users_groups, [:group_id, :user_id])
    create index(:users_groups, [:tenant_id])
    create index(:users_groups, [:group_id])
    create index(:users_groups, [:user_id])
    create index(:users_groups, [:workspace_id])
  end
end
