defmodule Core.Security.LoginLocal do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.{Error, Validate}
  alias Core.Org.{Session, User}
  alias Core.Security.LoginLocal

  @primary_key false
  embedded_schema do
    field :email, :string
    field :password, :string
  end

  @required [:email, :password]

  def changeset(%LoginLocal{} = login_local, attrs) do
    login_local
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_format(:email, ~r/@/)
    |> Validate.change()
  end

  #####################
  ### API Functions ###
  #####################
  def login(%{email: email, password: password} = attrs) do
    with {:ok, _changeset} <- changeset(%LoginLocal{}, attrs),
         {:ok, user} <- User.get_login_by_email(email),
         :ok <- check_password(password, user.password_hash),
         {:ok, session} <- Session.create_session(user)
    do
      {:ok, session}
    else
      error ->
        Comeonin.Bcrypt.dummy_checkpw()
        error
    end
  end

  def check_password(password, hash) do
    case Comeonin.Bcrypt.checkpw(password, hash) do
      true ->
        :ok
      _ ->
        {:error, Error.message({:login, :invalid})}
    end
  end

end
