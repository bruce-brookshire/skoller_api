defmodule Skoller.ClassDocs.Doc do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.ClassDocs.Doc
  alias Skoller.Classes.Class
  alias Skoller.Users.User

  schema "docs" do
    field :is_syllabus, :boolean, default: false
    field :path, :string
    field :class_id, :id
    field :name, :string
    field :user_id, :id
    belongs_to :user, User, define_field: false
    belongs_to :class, Class, define_field: false

    timestamps()
  end

  @req_fields [:path, :is_syllabus, :class_id, :name, :user_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Doc{} = doc, attrs) do
    doc
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_id)
    |> foreign_key_constraint(:user_id)
  end
end
