defmodule Core.Kb.Article do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Kb.{Article}
  alias Core.Org.{Workspace}
  alias Core.{Error, Repo, Validate}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "articles" do
    field(:tenant_id, :binary_id)
    field(:workspace_id, :binary_id)
    field(:content, :string)
    field(:name, :string)
    field(:pinned, :boolean, default: false)
    field(:status, :string, default: "active")
    field(:type, :string)

    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
    field(:deleted_at, :utc_datetime)
  end

  #####################
  ### API Functions ###
  #####################
  def list_articles(%{admin: admin} = args, %{tenant_id: tenant_id, permissions: permissions, type: type, workspaces: workspaces}) do
    query =
      if admin do
        case permissions do
          %{update_workspace: 1} ->
            from(a in Article,
              where: a.tenant_id == ^tenant_id
            )

          _ ->
            from(a in Article,
              where: a.tenant_id == ^tenant_id,
              where: a.workspace_id in ^workspaces
            )
        end
      else
        from(a in Article,
            where: a.tenant_id == ^tenant_id,
            where: a.workspace_id in ^workspaces
          )
      end

    query =
      case type do
        "agent" ->
          query

        _ ->
          from(q in query,
            where: q.type == ^"contact"
          )
      end


    query
    |> filter_articles(args)
    |> sort_articles(args)
    |> Repo.all()
    |> Validate.ecto_read(:articles)
  end

  def get_article(id, %{tenant_id: tenant_id, permissions: permissions, type: type, workspaces: workspaces}) do
    query =
      from(a in Article,
        where: a.tenant_id == ^tenant_id,
        where: a.id == ^id
      )

    query =
      case permissions do
        %{update_workspace: 1} ->
          query

        _ ->
          from(q in query,
            where: q.workspace_id in ^workspaces
          )
      end

    query =
      case type do
        "agent" ->
          query

        _ ->
          from(q in query,
            where: q.type == "contact"
          )
      end

    query
    |> Repo.one()
    |> Validate.ecto_read(:article)
  end

  def get_article(_id, _session), do: {:error, Error.message({:user, :authorization})}

  # def create_article(%{workspace_id: workspace_id} = attrs, %{tenant_id: tenant_id, permissions: %{create_article: 1}, type: "agent"} = session) do
  #   attrs = Map.put(attrs, :tenant_id, tenant_id)
  #   article = %Article{id: Repo.binary_id()}

  #   with {:ok, _workspace} <- Workspace.get_workspace(workspace_id, session),
  #        {:ok, change} <- changeset(article, attrs),
  #        {:ok, article} <- Repo.put(change) do
  #     {:ok, article}
  #   else
  #     error ->
  #       error
  #   end
  # end

  # def create_article(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  ##################
  ### Changesets ###
  ##################

  @optional [:pinned]
  @required [:content, :name, :status, :tenant, :type, :workspace_id]

  def changeset(%Article{} = article, attrs, session) do
    article
    |> Repo.preload([:users_groups, :users_workspaces])
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:workspace_id)
    |> Validate.change()
  end

  ########################
  ### Helper Functions ###
  ########################
  def filter_articles(query, %{filter: filter}) do
    filter
    |> Enum.reduce(query, fn
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

  def filter_articles(query, _filter), do: query

  def sort_articles(query, %{sort: %{field: field, order: "asc"}}) when field in ["created", "name", "type", "updated"] do
    case field do
      "created" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: [asc: :created_at]
        )

      "name" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "type" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: [asc: :type],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "updated" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: [asc: :updated_at]
        )
    end
  end

  def sort_articles(query, %{sort: %{field: field, order: "desc"}}) when field in ["created", "name", "type", "updated"] do
    case field do
      "created" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: [desc: :created_at]
        )

      "name" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: fragment("lower(?) DESC", q.name)
        )

      "type" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: [desc: :type],
          order_by: fragment("lower(?) ASC", q.name)
        )

      "updated" ->
        from(q in query,
          order_by: [asc: :pinned],
          order_by: [desc: :updated_at]
        )
    end
  end

  def sort_articles(query, _args) do
    from(q in query,
      order_by: [asc: :pinned],
      order_by: fragment("lower(?) ASC", q.name)
    )
  end

end
