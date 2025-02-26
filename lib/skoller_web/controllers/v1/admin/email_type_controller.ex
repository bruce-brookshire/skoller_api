defmodule SkollerWeb.Api.V1.Admin.EmailTypeController do
  use SkollerWeb, :controller

  alias Skoller.EmailTypes
  alias SkollerWeb.EmailTypeView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    email_types = EmailTypes.all()

    conn
    |> put_view(EmailTypeView)
    |> render("index.json", email_types: email_types)
  end

  def update(conn, %{"id" => id} = params) do
    email_type_old = EmailTypes.get!(id)

    case EmailTypes.update(email_type_old, params) do
      {:ok, email_type} ->
        conn
        |> put_view(EmailTypeView)
        |> render("show.json", email_type: email_type)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
