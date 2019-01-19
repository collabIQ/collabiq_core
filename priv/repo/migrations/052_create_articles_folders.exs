defmodule Core.Repo.Migrations.CreateArticlesFolders do
  use Ecto.Migration

  def change do
    create table(:articles_folders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all, type: :binary_id), null: false
      add :article_id, references(:groups, on_delete: :delete_all, type: :binary_id), null: false
      add :folder_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
    end

    create unique_index(:articles_folders, [:article_id, :folder_id])
    create index(:articles_folders, [:tenant_id])
    create index(:articles_folders, [:article_id])
    create index(:articles_folders, [:folder_id])
    create index(:articles_folders, [:workspace_id])
  end
end
