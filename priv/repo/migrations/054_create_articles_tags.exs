defmodule Core.Repo.Migrations.CreateArticlesTags do
  use Ecto.Migration

  def change do
    create table(:articles_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :article_id, references(:groups, on_delete: :delete_all, type: :binary_id), null: false
      add :tag_id, references(:tags, on_delete: :delete_all, type: :binary_id), null: false
    end

    create unique_index(:articles_tags, [:article_id, :tag_id])
    create index(:articles_tags, [:tenant_id])
    create index(:articles_tags, [:article_id])
    create index(:articles_tags, [:tag_id])
  end
end
