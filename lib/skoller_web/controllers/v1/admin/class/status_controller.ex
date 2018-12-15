defmodule SkollerWeb.Api.V1.Admin.Class.StatusController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.ClassView
  alias Skoller.ClassStatuses

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @help_role 500
    
  plug :verify_role, %{roles: [@admin_role, @help_role]}

  def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
    case ClassStatuses.update_status(class_id, id) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end
end