defmodule SkollerWeb.Api.V1.EmailDomainController do
  use SkollerWeb, :controller

  alias Skoller.Schools
  alias Skoller.Schools.EmailDomain
  alias SkollerWeb.EmailDomainView

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    school_email_domains = Schools.list_school_email_domains()
    render(conn, SkollerWeb.EmailDomainView, "index.json", school_email_domains: school_email_domains)
  end

  def create(conn, params) do
    case Schools.create_email_domain(params) do
      {:ok, %EmailDomain{} = email_domain} ->
        conn |> render("show.json", email_domain: email_domain)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    email_domain = Schools.get_email_domain!(id)
    render(conn, SkollerWeb.EmailDomainView, "show.json", email_domain: email_domain)
  end

  def update(conn, %{"id" => id} = params) do
    email_domain = Schools.get_email_domain!(id)

    case Schools.update_email_domain(email_domain, params) do
      {:ok, %EmailDomain{} = email_domain} ->
        conn |> render(SkollerWeb.EmailDomainView, "show.json", email_domain: email_domain)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    email_domain = Schools.get_email_domain!(id)
    case Schools.delete_email_domain(email_domain) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end
end
