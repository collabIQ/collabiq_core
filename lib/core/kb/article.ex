defmodule Core.Kb.Article do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Kb.{Article}
  alias Core.Org.{Workspace}
  alias Core.{Error, Query, Repo, Validate}

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
  def list_articles(args, session) do
    from(a in Article)
    |> Query.list(args, session, :articles)
  end

  def get_article(id, session) do
    from(a in Article)
    |> Query.get(id, session, :article)
  end

  def create_article(attrs, %{tenant_id: tenant_id, permissions: %{create_article: 1}, type: "agent"} = session) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)
    article = %Article{id: Repo.binary_id()}

    with {:ok, %{params: %{"workspace_id" => workspace_id}} = change} <- changeset(article, attrs),
         {:ok, _workspace} <- Workspace.get_workspace(workspace_id, session),
         {:ok, article} <- Repo.put(change) do
      {:ok, article}
    else
      error ->
        error
    end
  end

  def create_article(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  ##################
  ### Changesets ###
  ##################

  @optional [:pinned]
  @required [:content, :name, :status, :tenant, :type, :workspace_id]

  def changeset(%Article{} = article, attrs) do
    article
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:workspace_id)
    |> Validate.change()
  end


end
