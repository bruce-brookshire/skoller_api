defmodule SkollerWeb.Api.V2.Class.ChangeRequestController do
  use SkollerWeb, :controller
  
  alias Skoller.Schools.Class
  alias Skoller.Class.ChangeRequest
  alias Skoller.Repo
  alias SkollerWeb.ClassView
  alias SkollerWeb.Helpers.StatusHelper
  alias SkollerWeb.Helpers.RepoHelper

  import SkollerWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do

    class = Repo.get!(Class, class_id)

    params = params |> Map.put("user_id", conn.assigns[:user].id)

    changeset = ChangeRequest.v2changeset(%ChangeRequest{}, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:change_request, changeset)
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