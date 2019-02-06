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

    render(conn, ClassView, "show.json", class: class)
  end

  @doc """
    Returns all classes that have at least one student enrolled or previously enrolled

    ## Returns:
    * 200
  """
  def communities(conn, _params) do
    classes = Skoller.Analytics.Classes.get_community_classes()

    conn
      |> put_status(:ok)
      |> json(classes)
  end

end