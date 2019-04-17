defmodule Skoller.Students.Organizations do
  @moduledoc """
  A context module for student organizations
  """

  alias Skoller.Repo
  alias Skoller.Organizations.Organization
  alias Skoller.Students.Student
  alias Skoller.CustomSignups

  import Ecto.Query

  @doc """
  Attributes the `new_student_id` to the link from the `enroller_student_id`'s organization
  if it exists.

  ## Returns
  `Skoller.CustomSignups.track_signup/2` or `{:ok, nil}` if there is no organization or link.
  """
  def attribute_signup_to_organization(new_student_id, enroller_student_id) do
    organization = from(o in Organization)
    |> join(:inner, [o], s in Student, on: s.primary_organization_id == o.id)
    |> where([o, s], s.id == ^enroller_student_id)
    |> preload([o], [:custom_signup_link])
    |> Repo.one()

    case organization do
      nil -> {:ok, nil}
      %{custom_signup_link: nil} -> {:ok, nil}
      %{custom_signup_link: link} -> CustomSignups.track_signup(new_student_id, link.id)
      _ -> {:ok, nil}
    end
  end
end