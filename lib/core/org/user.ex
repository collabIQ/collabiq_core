defmodule Core.Org.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Agent, Contact, Phone, Role, User, UserGroup, UserWorkspace}
  alias Core.{Error, Repo, Validate}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "users" do
    field(:tenant_id, :binary_id)
    field(:address, :string)
    field(:basic_username, :string)
    field(:basic_password, :string, virtual: true)
    field(:basic_password_hash, :string)
    field(:email, :string)
    field(:email_valid, :boolean, default: false)
    field(:language, :string, default: "en")
    field(:name, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:provider, :string, default: "local")
    field(:status, :string, default: "active")
    field(:timezone, :string, default: "America/Chicago")
    field(:title, :string)
    field(:type, :string, default: "active")

    belongs_to(:role, Role)
    embeds_many(:phones, Phone, on_replace: :delete)
    has_many(:users_groups, UserGroup, on_replace: :delete)
    has_many(:groups, through: [:users_groups, :group])
    has_many(:users_workspaces, UserWorkspace, on_replace: :delete)
    has_many(:workspaces, through: [:users_workspaces, :workspace])
    timestamps(inserted_at: :created_at, type: :utc_datetime, usec: false)
  end

  #####################
  ### API Functions ###
  #####################

  def list_users(args, %{tenant_id: tenant_id, permissions: permissions, workspaces: workspaces}) do
    case permissions do
      %{update_workspace: 1} ->
        from(u in User,
          where: u.tenant_id == ^tenant_id
        )

      _ ->
        from(u in User,
          where: u.tenant_id == ^tenant_id,
          join: w in assoc(u, :workspaces),
          where: w.id in ^workspaces
        )
    end
    |> filter_users(args)
    |> sort_users(args)
    |> Repo.all()
    |> Validate.ecto_read(:users)
  end

  def list_users(_args, _session), do: {:error, Error.message({:user, :authorization})}

  def get_user(id, %{tenant_id: tenant_id, permissions: permissions, workspaces: workspaces}) do
    query =
      case permissions do
        %{update_workspace: 1} ->
          from(u in User,
            where: u.tenant_id == ^tenant_id,
            where: u.id == ^id
          )

        _ ->
          from(u in User,
            where: u.tenant_id == ^tenant_id,
            where: u.id == ^id,
            join: w in assoc(u, :workspaces),
            where: w.id in ^workspaces,
            preload: [workspaces: w]
          )
      end

    query
    |> Repo.one()
    |> Validate.ecto_read(:user)
  end

  def get_user(_id, _session), do: {:error, Error.message({:user, :authorization})}

  def get_user_by_email(email) when is_binary(email) do
    User
    |> Repo.get_by(email: email)
    |> Validate.ecto_read(:user)
  end

  def get_login_by_email(email) when is_binary(email) do
    email = String.downcase(email)

    query =
      from(u in User,
        where: u.email == ^email,
        where: u.status == ^"active"
      )

    query
    |> Repo.one()
    |> Validate.ecto_read(:login)
  end

  def get_user_by_workspace(id, workspace_id, %{tenant_id: tenant_id}) do
    query =
      from(u in User,
        where: u.tenant_id == ^tenant_id,
        where: u.id == ^id,
        join: w in assoc(u, :workspaces),
        where: w.id == ^workspace_id
      )

    query
    |> Repo.one()
    |> Validate.ecto_read(:user)
  end

  ##################
  ### Changesets ###
  ##################

  @optional [
    :address,
    :basic_username,
    :basic_password,
    :email_valid,
    :language,
    :password,
    :provider,
    :status,
    :timezone,
    :title,
    :type
  ]
  @required [:tenant_id, :email, :name, :role_id]

  def changeset(%User{} = user, attrs, session) do
    user
    |> Repo.preload([:users_groups, :users_workspaces])
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> validate_format(:email, ~r/@.*?\./)
    |> validate_length(:password, min: 8)
    |> change_password()
    |> change_phones()
    |> change_users_workspaces(session)
    |> change_users_groups(session)
    |> validate_workspace_min()
    |> unique_constraint(:email)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:role_id)
    |> Validate.change()
  end

  def change_password(%{params: %{"password" => password}} = changeset) do
    put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))
  end

  def change_password(changeset), do: changeset

  def change_phones(%{params: %{"phones" => phones}} = changeset) do
    phones =
      Enum.map(phones, fn attrs ->
        case Phone.changeset(%Phone{}, attrs) do
          %{valid?: true} = phone_changeset ->
            apply_changes(phone_changeset)
          _ ->
            []
        end
      end)
      |> List.flatten()

    case phones do
      [] ->
        changeset

      _ ->
        changeset
        |> put_embed(:phones, phones)
    end
  end

  def change_phones(changeset), do: changeset

  def change_users_workspaces(%{data: %{type: type}} = changeset, session) do
    case type do
      "agent" ->
        Agent.change_users_workspaces(changeset, session)

      "contact" ->
        Contact.change_users_workspaces(changeset, session)
    end
  end

  def change_users_groups(%{data: %{type: type}} = changeset, session) do
    case type do
      "agent" ->
        Agent.change_users_groups(changeset, session)
      "contact" ->
        Contact.change_users_groups(changeset, session)
    end
  end

  defp validate_workspace_min(changeset) do
    applied = apply_changes(changeset)

    case applied.users_workspaces do
      [] ->
        changeset
        |> add_error(:user, Error.error_message(:workspace_min))
      _ ->
        changeset
    end
  end

  ########################
  ### Helper Functions ###
  ########################
  def filter_users(query, %{filter: filter}) do
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

  def filter_users(query, _filter), do: query

  def sort_users(query, %{sort: %{field: field, order: "asc"}}) when field in ["created", "email", "name", "status", "type", "updated"] do
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

  def sort_users(query, %{sort: %{field: field, order: "desc"}}) when field in ["created", "email", "name", "status", "type", "updated"] do
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

  def sort_users(query, _args) do
    from(q in query,
        order_by: fragment("lower(?) ASC", q.name)
      )
  end
end
