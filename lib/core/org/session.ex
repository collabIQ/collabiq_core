defmodule Core.Org.Session do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.{Error, Repo, Validate}
  alias Core.Org.{Session, User}

  @type t :: map()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field(:device_type, :string, default: nil)
    field(:ip_address, :string, default: nil)
    field(:tenant_id, :binary_id)
    belongs_to(:user, User)

    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
  end

  #####################
  ### API Functions ###
  #####################

  def get_session(id) do
    from(s in Session,
      where: s.id == ^id
    )
    |> Repo.one()
    |> Repo.validate_read(:session)
  end

  def get_me(id) do
    with {:ok, session} <- get_session(id),
         {:ok, session} <- preload_me(session),
         {:ok, session} <- format_me(session) do
      {:ok, session}
    else
      _ ->
        {:error, Error.message({:session, :not_found})}
    end
  end

  def create_session(user) do
    attrs = %{user_id: user.id, tenant_id: user.tenant_id}

    with {:ok, change} <- changeset(%Session{}, attrs),
         {:ok, session} <- Repo.put(change),
         {:ok, session} <- preload_session_user_info(session),
         {:ok, session_map} <- format_session(session) do
      {:ok, session_map}
    else
      error ->
        error
    end
  end


  def preload_session_user_info(session) do
    session =
      session
      |> Repo.preload([:user, user: :groups, user: :role, user: :workspaces])

    {:ok, session}
  end

  def preload_me(session) do
    session =
      session
      |> Repo.preload([:user, user: :role])

    {:ok, session}
  end

  def format_me(session) do
    {:ok, %{
      name: session.user.name,
      permissions: Map.from_struct(session.user.role.permissions),
      type: session.user.type,
      id: session.user_id
    }}
  end
  def format_session(%Session{} = session) do
    {:ok, %{
        id: session.id,
        t_id: session.tenant_id,
        group: Enum.map(session.user.groups, &(&1.id)),
        name: session.user.name,
        perms: Map.from_struct(session.user.role.permissions),
        type: session.user.type,
        u_id: session.user_id,
        ws: Enum.map(session.user.workspaces, &(&1.id))
      }
    }
  end

  ##################
  ### Changesets ###
  ##################
  @optional [:device_type, :ip_address]
  @required [:tenant_id, :user_id]

  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:user_id)
    |> Validate.change()
  end
end
