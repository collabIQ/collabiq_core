defmodule Core.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false
      add :role_id, references(:roles, on_delete: :restrict, type: :binary_id)
      add :address, :text
      add :basic_username, :string
      add :basic_password_hash, :string
      add :email, :string
      add :email_valid, :boolean
      add :language, :string
      add :name, :string
      add :password_hash, :string
      add :phones, {:array, :map}, default: []
      add :provider, :string
      add :status, :string, null: false
      add :timezone, :string
      add :title, :string
      add :type, :string, null: false

      timestamps([inserted_at: :created_at, type: :utc_datetime])
    end

    create index(:users, [:tenant_id])
    create index(:users, [:role_id])
    create unique_index(:users, ["(lower(email))"], name: :users_email_index)
    create index(:users, ["(lower(name))"], name: :users_name_index)
  end
end
