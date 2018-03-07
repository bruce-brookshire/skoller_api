defmodule Classnavapi.Assignment.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignment.Post


  schema "assignment_posts" do
    field :post, :string
    field :assignment_id, :id
    field :student_id, :id

    timestamps()
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, [:post])
    |> validate_required([:post])
  end
end
