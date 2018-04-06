defmodule ClassnavapiWeb.Api.V2.Class.ChangeRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Universities.Class
  alias Classnavapi.Class.ChangeRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Helpers.StatusHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

  import ClassnavapiWeb.Helpers.AuthPlug

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