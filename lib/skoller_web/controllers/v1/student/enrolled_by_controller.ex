defmodule SkollerWeb.Api.V1.Student.EnrolledByController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.CustomSignups
  alias Skoller.CustomSignups.Link
  alias SkollerWeb.LinkView

  def signup_organization(conn, %{"student_id" => student_id}) do
    # TODO make sure we are checking that a student can only get their own org
    case student_id |> CustomSignups.link_for_student_id() do
      %Link{} = link ->
        conn
        |> put_view(LinkView)
        |> render("link_base.json", link: link)

      _ ->
        conn |> send_resp(404, "signup organization not found")
    end
  end
end
