defmodule Skoller.Weights.Weight do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Weights.Weight
  alias Skoller.Classes.Class
  alias Skoller.Users.User

  schema "class_weights" do
    field :name, :string
    field :weight, :decimal
    field :class_id, :id
    field :created_by, :id
    field :updated_by, :id
    field :created_on, :string
    belongs_to :created_by_user, User, define_field: false, foreign_key: :created_by
    belongs_to :updated_by_user, User, define_field: false, foreign_key: :updated_by
    belongs_to :class, Class, define_field: false

    timestamps()
  end

  @req_fields [:name, :weight]
  @all_fields @req_fields

  @adm_req @req_fields ++ [:class_id]
  @all_adm @adm_req

  @doc false
  def changeset_update(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_number(:weight, greater_than: 0)
  end

  def changeset_insert(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, @all_adm)
    |> validate_required(@adm_req)
    |> validate_number(:weight, greater_than: 0)
    |> foreign_key_constraint(:class_id)
  end
end
