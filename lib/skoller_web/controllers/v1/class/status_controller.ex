defmodule SkollerWeb.Api.V1.Class.StatusController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.StatusView
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.ClassStatuses, as: Statuses

  import SkollerWeb.Plugs.Auth

  @admin_role 200
  @syllabus_worker_role 300

  plug :verify_role, %{roles: [@admin_role, @syllabus_worker_role]}

  def index(conn, %{}) do
    statuses = Statuses.get_statuses()

    conn
    |> put_view(StatusView)
    |> render("index.json", statuses: statuses)
  end

  def hub(conn, _params) do
    statuses = ClassStatuses.get_class_status_counts()

    conn
    |> put_view(StatusView)
    |> render("index.json", statuses: statuses)
  end
end
