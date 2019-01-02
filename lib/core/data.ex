defmodule Core.Data do
  import Ecto.Query, warn: false
  alias Core.Org.{Group, User, Workspace}
  alias Core.Repo

  def dataloader(default_params) do
    Dataloader.Ecto.new(Repo, [query: &dataloader_query/2, default_params: default_params])
  end

  def dataloader_query(Group = query, %{session: %{tenant_id: tenant_id, permissions: permissions, workspaces: workspaces}} = args) do
    args = Map.drop(args, [:session])

    case permissions do
      %{update_workspace: 1} ->
        from(q in query,
          where: q.tenant_id == ^tenant_id
        )

      _ ->
        from(q in query,
          where: q.tenant_id == ^tenant_id,
          where: q.id in ^workspaces
        )
    end
    |> Group.filter_groups(args)
    |> Group.sort_groups(args)
  end

  def dataloader_query(User = query, %{session: %{tenant_id: tenant_id}} = args) do
    args = Map.drop(args, [:session])

    query =
      from(q in query,
        where: q.tenant_id == ^tenant_id
      )

    query
    |> User.filter_users(args)
    |> User.sort_users(args)
  end

  def dataloader_query(Workspace = query, %{session: %{tenant_id: tenant_id, permissions: permissions, workspaces: workspaces}} = args) do
    args = Map.drop(args, [:session])

    case permissions do
      %{update_workspace: 1} ->
        from(q in query,
          where: q.tenant_id == ^tenant_id
        )

      _ ->
        from(q in query,
          where: q.tenant_id == ^tenant_id,
          where: q.id in ^workspaces
        )
    end
    |> Workspace.filter_workspaces(args)
    |> Workspace.sort_workspaces(args)
  end

  def dataloader_query(query, _args) do
    query
  end
end
