defmodule Core.Query do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Core.Org.Session
  alias Core.{Error, Repo, Validate}

  @spec get(Ecto.Query.t(), String.t(), Session.t(), atom()) :: {:ok, any()} | {:error, [any()]}
  def get(query, id, %{tenant_id: tenant_id, permissions: _p, workspaces: _w} = session, schema) do
    from(q in query,
      where: q.tenant_id == ^tenant_id,
      where: q.id == ^id
    )
    |> permissions(session, schema)
    |> Repo.one()
    |> Validate.ecto_read(schema)
  end

  def get(_query, _id, _session, _type), do: {:error, Error.message({:user, :authorization})}

  @spec list(Ecto.Query.t(), map(), Session.t(), atom()) :: {:ok, [any(),...]} | {:error, [any()]}
  def list(query, args, %{tenant_id: tenant_id, permissions: _p, workspaces: _w} = session, schema) do
    from(q in query,
      where: q.tenant_id == ^tenant_id
    )
    |> permissions(session, schema)
    |> admin(args, session, schema)
    |> filter(args, schema)
    |> sort(args, schema)
    |> Repo.all()
    |> Validate.ecto_read(schema)
  end

  def list(_query, _args, _session, _type), do: {:error, Error.message({:user, :authorization})}

  def admin(query, %{admin: admin}, %{workspaces: workspaces}, type) when type == :workspaces do
    case admin do
      false ->
        from(q in query,
          where: q.id in ^workspaces
        )

      _ ->
        query
    end
  end

  def admin(query, %{admin: admin}, %{workspaces: workspaces}, _type) do
    case admin do
      false ->
        from(q in query,
          where: q.workspace_id in ^workspaces
        )

      _ ->
        query
    end
  end

  def permissions(query, %{permissions: permissions, workspaces: workspaces}, type) when type in [:workspace, :workspaces] do
    case permissions do
      %{update_workspace: 1} ->
        query

      _ ->
        from(q in query,
          where: q.id in ^workspaces
        )
    end
  end

  def permissions(query, %{permissions: permissions, workspaces: workspaces}, _type) do
    case permissions do
      %{update_workspace: 1} ->
        query

      _ ->
        from(q in query,
          where: q.workspace_id in ^workspaces
        )
    end
  end

  def filter(query, %{filter: filter}, schema) do
    filter
    |> Enum.reduce(query, fn
      {:email, email}, query when is_nil(email) or email == "" ->
        query

      {:email, email}, query when schema in [:users] ->
        from(q in query,
          where: ilike(q.email, ^"%#{String.downcase(email)}%")
        )

      {:name, name}, query when is_nil(name) or name == "" ->
        query

      {:name, name}, query ->
        from(q in query,
          where: ilike(q.name, ^"%#{String.downcase(name)}%")
        )

      {:status, [_|_] = status}, query ->
        from(q in query,
          where: q.status in ^status
        )

      {:status, _}, query ->
        query

      {:type, [_|_] = type}, query when schema in [:groups, :users] ->
        from(q in query,
          where: q.type in ^type
        )

      {:type, _}, query ->
        query
    end)
  end

  def sort(query, %{sort: %{field: field, order: order}}, type) when order in ["asc", "desc"] do
    case field do
      "created" when type in [:groups, :workspaces] ->
        from(q in query,
          order_by: fragment("created_at ?", ^order)
        )

      "email" ->
        from(q in query,
          order_by: fragment("lower(?) ?", q.email, ^order)
        )

      "name" when type in [:groups, :workspaces] ->
        from(q in query,
          order_by: fragment("lower(?) ?", q.name, ^order)
        )

      "status" when type in [:groups, :workspaces] ->
        from(q in query,
          order_by: fragment("status ?", ^order),
          order_by: fragment("lower(?) ASC", q.name)
        )

      "type" when type in [:groups] ->
        from(q in query,
          order_by: fragment("type ?", ^order),
          order_by: fragment("lower(?) ASC", q.name)
        )

      "updated" when type in [:groups, :workspaces] ->
        from(q in query,
          order_by: fragment("updated_at ?", ^order)
        )

      _ ->
        query
    end
  end

  def sort(query, _args, type) when type in [:groups, :users, :workspaces] do
    from(q in query,
      order_by: fragment("lower(?) ASC", q.name)
    )
  end

  def sort(query, _args, _type), do: query
end
