defmodule SkollerWeb.Api.V1.Class.HelpRequestController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.HelpRequests
  alias SkollerWeb.ClassView
  alias SkollerWeb.Responses.MultiError

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300

  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do
    params = params |> Map.put("user_id", conn.assigns[:user].id)

    case HelpRequests.create(class_id, params) do
      {:ok, %{class: class}} ->
        conn
        |> put_view(ClassView)
        |> render("show.json", class: class)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end
