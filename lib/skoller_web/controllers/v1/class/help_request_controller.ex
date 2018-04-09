defmodule SkollerWeb.Api.V1.Class.HelpRequestController do
  use SkollerWeb, :controller
  
  alias Skoller.Class.HelpRequest
  alias Skoller.Repo
  alias SkollerWeb.ClassView
  alias SkollerWeb.Helpers.StatusHelper
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Classes

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do

    class = Classes.get_class_by_id!(class_id)
    class = class |> Repo.preload(:class_status)

    params = params |> Map.put("user_id", conn.assigns[:user].id)

    changeset = HelpRequest.changeset(%HelpRequest{}, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:help_request, changeset)
    |> Ecto.Multi.run(:class, &StatusHelper.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end