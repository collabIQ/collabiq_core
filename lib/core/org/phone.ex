defmodule Core.Org.Phone do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Org.Phone

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  embedded_schema do
    field(:number, :string)
    field(:type, :string)
  end

  @required [:number, :type]
  @attr_types ["home", "mobile", "work"]

  @spec changeset(%Phone{}, map()) :: Ecto.Changeset.t() | no_return
  def changeset(%Phone{} = phone, attrs) do
    phone
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_inclusion(:type, @attr_types)
  end
end
