defmodule SkollerWeb.Api.V1.School.EmailDomainController do
  use SkollerWeb, :controller

  alias Skoller.Schools
  alias SkollerWeb.SchoolView

  import SkollerWeb.Plugs.Auth
  
  @student_role 100

  plug :verify_role, %{role: @student_role}

  def show(conn, %{"email_domain" => email_domain}) do
    schools = Schools.get_school_from_email_domain!(email_domain)
    render(conn, SchoolView, "index.json", schools: [])
    # todo
    # render(conn, SchoolView, "index.json", schools: schools)
  end
end