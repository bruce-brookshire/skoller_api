defmodule SkollerWeb.Api.V1.SyllabusWorkerController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.ClassView
  alias Skoller.Syllabi

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @syllabus_worker_role 300

  plug :verify_role, %{roles: [@syllabus_worker_role, @admin_role]}

  def class(%{assigns: %{user: user}} = conn, _params) do
    class = user |> Syllabi.serve_class()
    case class do
      nil ->  conn |> send_resp(204, "")
      class -> conn |> render(ClassView, "show.json", class: class)
    end
  end
end