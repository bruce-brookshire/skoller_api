defmodule Skoller.CustomSignups.Signup do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.CustomSignups.Signup
  alias Skoller.Students.Student
  alias Skoller.CustomSignups.Link

  schema "custom_signups" do
    field :custom_signup_link_id, :id
    field :student_id, :id
    belongs_to :student, Student, define_field: false
    belongs_to :custom_signup_link, Link, define_field: false

    timestamps()
  end

  @req_fields [:custom_signup_link_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Signup{} = enroll, attrs) do
    enroll
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:custom_signup_link_id)
  end
end
