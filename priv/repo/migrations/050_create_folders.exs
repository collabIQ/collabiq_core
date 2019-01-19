defmodule Core.Repo.Migrations.CreateFolders do
  use Ecto.Migration

  def change do
    create table(:folders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all, type: :binary_id), null: false
      add :description, :text
      add :name, :string, null: false
      add :type, :string

      timestamps([inserted_at: :created_at, type: :utc_datetime])
      add :deleted_at, :utc_datetime
    end

    create index(:folders, [:tenant_id])
    create index(:folders, [:workspace_id])
    create index(:folders, ["(lower(name))"], name: :folders_name_index)
  end
end
