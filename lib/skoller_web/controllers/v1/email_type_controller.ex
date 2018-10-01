defmodule SkollerWeb.Api.V1.EmailTypeController do
  use SkollerWeb, :controller

  alias Skoller.EmailTypes
  alias SkollerWeb.EmailTypeView
  
  import SkollerWeb.Plugs.Auth
  
  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    email_types = EmailTypes.all()
    render(conn, EmailTypeView, "index.json", email_types: email_types)
  end
end