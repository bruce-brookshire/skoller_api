defmodule SkollerWeb.Api.V1.EmailTypeController do
  use SkollerWeb, :controller

  alias Skoller.EmailTypes
  alias SkollerWeb.EmailTypeMinView

  def index(conn, _params) do
    email_types = EmailTypes.all()

    conn
    |> put_view(EmailTypeMinView)
    |> render("index.json", email_types: email_types)
  end
end
