defmodule Core.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all, type: :binary_id), null: false
      add :content, :text, null: false
      add :name, :string, null: false
      add :status, :string
      add :type, :string

      timestamps([inserted_at: :created_at, type: :utc_datetime])
      add :deleted_at, :utc_datetime
    end

    create index(:articles, [:tenant_id])
    create index(:articles, [:workspace_id])
    create index(:articles, ["(lower(name))"], name: :articles_name_index)
  end
end
