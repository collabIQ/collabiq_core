defmodule Core.Repo.Migrations.CreateWorkspaces do
  use Ecto.Migration

  def change do
    create table(:workspaces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :color, :string
      add :description, :text
      add :name, :string, null: false
      add :notes, :text
      add :status, :string, null: false

      timestamps([inserted_at: :created_at, type: :utc_datetime])
      add :deleted_at, :utc_datetime
    end

    create index(:workspaces, [:tenant_id])
    create index(:workspaces, ["(lower(name))"], name: :workspaces_name_index)
  end
end
