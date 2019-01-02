defmodule Core.Repo.Migrations.CreateUsersGroupsNotify do
  use Ecto.Migration

  def change do
    create table(:users_groups_notify, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :group_id, references(:groups, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
    end

    create unique_index(:users_groups_notify, [:group_id, :user_id])
    create index(:users_groups_notify, [:tenant_id])
    create index(:users_groups_notify, [:group_id])
    create index(:users_groups_notify, [:user_id])
  end
end
