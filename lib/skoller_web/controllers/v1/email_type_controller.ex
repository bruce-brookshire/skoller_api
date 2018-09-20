defmodule SkollerWeb.Api.V1.EmailTypeController do
  use SkollerWeb, :controller

  alias Skoller.EmailTypes
  alias SkollerWeb.EmailTypeView

  def index(conn, _params) do
    email_types = EmailTypes.all()
    render(conn, EmailTypeView, "index.json", email_types: email_types)
  end
end