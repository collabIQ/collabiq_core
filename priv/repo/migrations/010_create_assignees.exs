defmodule Core.Repo.Migrations.CreateAssignees do
  use Ecto.Migration

  def up do
    execute("""
      CREATE VIEW assignees AS
        SELECT
          id, tenant_id, 'user' as assignee_type, name, status, type
        FROM
          users
        WHERE
          type = 'agent'

        UNION ALL

        SELECT
          id, tenant_id, 'group' as assignee_type, name, status, type
        FROM
          groups
        WHERE
          type = 'agent'
    """)
  end

  def down do
    execute("DROP VIEW assignees")
  end
end
