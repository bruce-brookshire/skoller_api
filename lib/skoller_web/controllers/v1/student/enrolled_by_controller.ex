defmodule SkollerWeb.Api.V1.Student.EnrolledByController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.CustomSignups
  alias Skoller.Organizations.Organization
  alias SkollerWeb.OrganizationView

  def signup_organization(conn, %{"student_id" => student_id} = params) do
    #TODO make sure we are checking that a student can only get their own org
    case student_id |> CustomSignups.organization_for_student_id() do
      %Organization{} = org -> conn |> render(OrganizationView, "organization-base.json", organization: org)
      _ -> conn |> send_resp(404, "signup organization not found")
    end
  end
end
