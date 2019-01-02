defmodule Core.Repo.Migrations.CreateUsersWorkspaces do
  use Ecto.Migration

  def change do
    create table(:users_workspaces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all, type: :binary_id), null: false
    end

    create unique_index(:users_workspaces, [:workspace_id, :user_id])
    create index(:users_workspaces, [:tenant_id])
    create index(:users_workspaces, [:user_id])
    create index(:users_workspaces, [:workspace_id])
  end
end
