defmodule SkollerWeb.Api.V1.EmailTypeController do
  use SkollerWeb, :controller

  alias Skoller.EmailTypes
  alias SkollerWeb.EmailTypeMinView

  def index(conn, _params) do
    email_types = EmailTypes.all()
    render(conn, EmailTypeMinView, "index.json", email_types: email_types)
  end
end