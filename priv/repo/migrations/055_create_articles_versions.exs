defmodule Core.Repo.Migrations.CreateArticlesVersions do
  use Ecto.Migration

  def change do
    create table(:articles_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :content, :text, null: false
      add :status, :string

      timestamps([inserted_at: :created_at, type: :utc_datetime])
      add :deleted_at, :utc_datetime
    end

    create index(:articles_versions, [:tenant_id])
    create index(:articles_versions, [:user_id])
  end
end
