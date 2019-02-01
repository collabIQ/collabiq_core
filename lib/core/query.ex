defmodule Core.Query do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Core.{Error, Repo, Validate}

  def get(query, id, %{tenant_id: tenant_id, permissions: _p, workspaces: _w} = session, type) do
    from(q in query,
      where: q.tenant_id == ^tenant_id,
      where: q.id == ^id
    )
    |> permissions(session, type)
    |> Repo.one()
    |> Validate.ecto_read(type)
  end

  def get(_query, _id, _session, _type), do: {:error, Error.message({:user, :authorization})}

  def list(query, args, %{tenant_id: tenant_id, permissions: _p, workspaces: _w} = session, type) do
    from(q in query,
      where: q.tenant_id == ^tenant_id
    )
    |> permissions(session, type)
    |> admin(args, session, type)
    |> filter(args)
    |> sort(args, type)
    |> Repo.all()
    |> Validate.ecto_read(type)
  end

  def list(_query, _args, _session, _type), do: {:error, Error.message({:user, :authorization})}

  def filter(query, %{filter: _f} = args) do
    query
    |> filter_handle(args)
  end

  def filter(query, _args) do
    query
  end

  def admin(query, %{admin: admin}, %{workspaces: workspaces}, :workspaces) do
    case admin do
      false ->
        from(q in query,
          where: q.id in ^workspaces
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

  def sort(query, %{sort: %{field: field}} = args, :users) when field in ["created", "email", "name", "status", "type", "updated"] do
    query
    |> sort_handle(args)
  end

  def sort(query, %{sort: %{field: field}} = args, :workspaces) when field in ["created", "name", "status", "updated"] do
    query
    |> sort_handle(args)
  end

  def sort(query, _sort, type) when type in [:users, :workspaces] do
    from(q in query,
      order_by: fragment("lower(?) ASC", q.name)
    )
  end

  def sort(query, _args, _type) do
    query
  end

  def filter_handle(query, %{filter: filter}) do
    filter
    |> Enum.reduce(query, fn
      {:email, email}, query when is_nil(email) or email == "" ->
        query

      {:email, email}, query ->
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

      {:type, [_|_] = type}, query ->
        from(q in query,
          where: q.type in ^type
        )

      {:type, _}, query ->
        query
    end)
  end

  def sort_handle(query, %{sort: %{field: field, order: "asc"}}, type) do
    case field do
      "created" ->
        from(q in query,
          order_by: [asc: :created_at]
        )

      "email" ->
        from(q in query,
          order_by: [asc: :email]
        )

      "name" ->
        from(q in query,
          order_by: fragment("lower(?) ASC", q.name)
        )

      "status" ->
        from(q in query,
          order_by: [asc: :status],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "type" ->
        from(q in query,
          order_by: [asc: :type],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "updated" ->
        from(q in query,
          order_by: [asc: :updated_at]
        )
    end
  end

  def sort_handle(query, %{sort: %{field: field, order: "desc"}}) do
    case field do
      "created" ->
        from(q in query,
          order_by: [desc: :created_at]
        )

      "email" ->
        from(q in query,
          order_by: [desc: :created_at]
        )

      "name" ->
        from(q in query,
          order_by: fragment("lower(?) DESC", q.name)
        )

      "status" ->
        from(q in query,
          order_by: [desc: :status],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "type" ->
        from(q in query,
          order_by: [desc: :type],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "updated" ->
        from(q in query,
          order_by: [desc: :updated_at]
        )
    end
  end
end
