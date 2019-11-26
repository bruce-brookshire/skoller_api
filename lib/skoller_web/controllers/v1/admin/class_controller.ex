defmodule SkollerWeb.Api.V1.Admin.ClassController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.ClassView
  alias Skoller.Classes

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role]}

  @doc """
   Shows a single class.

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 404
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def show(conn, %{"id" => id}) do
    class = Classes.get_full_class_by_id!(id)

    conn
    |> put_view(ClassView)
    |> render("show.json", class: class)
  end

end