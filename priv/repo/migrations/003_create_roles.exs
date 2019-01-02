defmodule Core.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :name, :string, null: false
      add :permissions, :map, null: false

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

    create unique_index(:roles, [:tenant_id, :name])
    create index(:roles, [:tenant_id])
  end
end
