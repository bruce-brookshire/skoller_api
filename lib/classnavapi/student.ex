defmodule Classnavapi.Student do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Student


  schema "students" do
    field :birthday, :date
    field :gender, :string
    field :name_first, :string
    field :name_last, :string
    field :phone, :string
    field :major, :string
    field :school_id, :id
    has_many :users, Classnavapi.User
    belongs_to :school, Classnavapi.School, define_field: false
 
    timestamps()
  end

  @req_fields [:name_first, :name_last, :phone, :birthday, :gender, :major, :school_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Student{} = student, attrs) do

    student
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
  end
end
