defmodule Core.Query do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Core.Org.Session
  alias Core.{Error, Repo, Validate}

  @spec edit(Ecto.Query.t(), map(), Session.t(), atom()) :: {:ok, any()} | {:error, [any()]}
  def edit(query, %{id: id} = args, %{tenant_id: t_id, permissions: _p, workspaces: _w} = session, schema) do
    from([q, j] in query,
      where: q.tenant_id == ^t_id,
      where: q.id == ^id
    )
    |> permissions(session, schema)
    |> filter(args, schema)
    |> Repo.one()
    |> Validate.ecto_read(schema)
  end

  def edit(_query, _id, _session, _schema), do: {:error, Error.message({:user, :authorization})}

  @spec get(Ecto.Query.t(), map(), Session.t(), atom()) :: {:ok, any()} | {:error, [any()]}
  def get(query, %{id: id} = args, %{tenant_id: t_id, permissions: _p, workspaces: _w} = session, schema) do
    from(q in query,
      where: q.tenant_id == ^t_id,
      where: q.id == ^id
    )
    |> permissions(session, schema)
    |> filter(args, schema)
    |> Repo.single()
    |> Validate.ecto_read(schema)
  end

  def get(_query, _id, _session, _schema), do: {:error, Error.message({:user, :authorization})}

  @spec list(Ecto.Query.t(), map(), Session.t(), atom()) ::
          {:ok, [any(), ...]} | {:error, [any()]}
  def list(query, args, %{tenant_id: t_id, permissions: _p, workspaces: _w} = session, schema) do
    from(q in query,
      where: q.tenant_id == ^t_id
    )
    |> permissions(session, schema)
    |> admin(args, session, schema)
    |> filter(args, schema)
    |> sort(args, schema)
    |> Repo.full()
    |> Validate.ecto_read(schema)
  end

  def list(_query, _args, _session, _schema), do: {:error, Error.message({:user, :authorization})}

  def admin(query, args, %{workspaces: workspaces}, schema) do
    id =
      case schema do
        _ when schema in [:user, :users, :workspace, :workspaces] ->
          :id

        _ ->
          :workspace_id
      end

    case args do
      %{admin: true} ->
        query

      _ when schema in [:user, :users] ->
        from(q in query,
          join: w in assoc(q, :workspaces),
          where: field(w, ^id) in ^workspaces,
          preload: [workspaces: w]
        )

      _ ->
        from(q in query,
          where: field(q, ^id) in ^workspaces
        )
    end
  end

  def permissions(query, %{permissions: permissions, workspaces: workspaces}, schema) do
    id =
      case schema do
        _ when schema in [:user, :users, :workspace, :workspaces] ->
          :id

        _ ->
          :workspace_id
      end

    case permissions do
      %{update_workspace: 1} ->
        query

      _ when schema in [:user, :users] ->
        from([q, w] in query,
          where: field(w, ^id) in ^workspaces
        )

      _ ->
        from(q in query,
          where: field(q, ^id) in ^workspaces
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

      {:status, [_ | _] = status}, query ->
        from(q in query,
          where: q.status in ^status
        )

      {:status, _}, query ->
        query

      {:type, [_ | _] = type}, query when schema in [:groups, :users] ->
        from(q in query,
          where: q.type in ^type
        )

      {:type, _}, query ->
        query

      {:workspaces, [_ | _] = work}, query when schema in [:user, :users] ->
        from([q, j] in query,
          where: j.id in ^work
        )

      {:workspaces, [_ | _] = work}, query ->
        from(q in query,
          where: q.workspace_id in ^work
        )

      {:workspaces, _}, query ->
        query
    end)
  end

  def filter(query, _args, _schema), do: query

  def sort(query, %{sort: %{field: field, order: order}}, schema) when order in ["asc", "desc"] do
    case field do
      "created" when schema in [:groups, :workspaces] ->
        case order do
          "desc" ->
            from(q in query,
              order_by: [desc: q.created_at]
            )

          _ ->
            from(q in query,
              order_by: [asc: q.created_at]
            )
        end

      "email" when schema in [:users] ->
        case order do
          "desc" ->
            from(q in query,
              order_by: fragment("lower(email) DESC")
            )

          _ ->
            from(q in query,
              order_by: fragment("lower(email) ASC")
            )
        end

      "name" when schema in [:groups, :workspaces] ->
        case order do
          "desc" ->
            from(q in query,
              order_by: fragment("lower(name) DESC")
            )

          _ ->
            from(q in query,
              order_by: fragment("lower(name) ASC")
            )
        end

      "status" when schema in [:groups, :workspaces] ->
        case order do
          "desc" ->
            from(q in query,
              order_by: [desc: q.status],
              order_by: fragment("lower(name) ASC")
            )

          _ ->
            from(q in query,
              order_by: [asc: q.status],
              order_by: fragment("lower(name) ASC")
            )
        end

      "type" when schema in [:groups] ->
        case order do
          "desc" ->
            from(q in query,
              order_by: [:desc, q.type],
              order_by: fragment("lower(name) ASC")
            )

          _ ->
            from(q in query,
              order_by: [asc: q.type],
              order_by: fragment("lower(name) ASC")
            )
        end

      "updated" when schema in [:groups, :workspaces] ->
        case order do
          "desc" ->
            from(q in query,
              order_by: [desc: q.updated_at]
            )

          _ ->
            from(q in query,
              order_by: [asc: q.updated_at]
            )
        end

      _ ->
        from(q in query,
          order_by: fragment("lower(?) ASC", q.name)
        )
    end
  end

  def sort(query, _args, schema) when schema in [:users] do
    from([q, j] in query,
      order_by: fragment("lower(?) ASC", q.name)
    )
  end

  def sort(query, _args, schema) when schema in [:groups, :workspaces] do
    from(q in query,
      order_by: fragment("lower(name) ASC")
    )
  end

  def sort(query, _args, _schema), do: query
end
