defmodule Core.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all, type: :binary_id), null: false
      add :description, :text
      add :email, :string
      add :name, :string, null: false
      add :phone, :string
      add :status, :string, null: false
      add :type, :string, null: false

      timestamps([inserted_at: :created_at, type: :utc_datetime])
      add :deleted_at, :utc_datetime
    end

    create index(:groups, [:tenant_id])
    create index(:groups, [:workspace_id])
    create index(:groups, ["(lower(name))"], name: :groups_name_index)
  end
end
