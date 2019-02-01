defmodule Core.Data do
  import Ecto.Query, warn: false
  alias Core.Org.{Group, User, Workspace}
  alias Core.{Query, Repo}

  def dataloader(default_params) do
    Dataloader.Ecto.new(Repo, [query: &dataloader_query/2, default_params: default_params])
  end

  def dataloader_query(Group = query, %{session: session} = args) do
    args = Map.drop(args, [:session])

    query
    |> Query.permissions(session, :groups)
    |> Query.filter(args, :groups)
    |> Query.sort(args, :groups)
  end

  def dataloader_query(User = query, %{session: session} = args) do
    args = Map.drop(args, [:session])

    query
    |> Query.permissions(session, :users)
    |> Query.filter(args, :users)
    |> Query.sort(args, :users)
  end

  def dataloader_query(Workspace = query, %{session: session} = args) do
    args = Map.drop(args, [:session])

    query
    |> Query.permissions(session, :workspaces)
    |> Query.filter(args, :workspaces)
    |> Query.sort(args, :workspaces)
  end

  def dataloader_query(query, _args) do
    query
  end
end
