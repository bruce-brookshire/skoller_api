defmodule ClassnavapiWeb.Api.V1.Admin.Class.ChangeRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.ChangeRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.ChangeRequestView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias Classnavapi.Class

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200
  @change_req_role 400

  @complete_class_status 700
  
  plug :verify_role, %{roles: [@change_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    change_request_old = Repo.get!(ChangeRequest, id)

    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    multi = Ecto.Multi.new
    |> Ecto.Multi.update(:change_request, changeset)
    |> Ecto.Multi.run(:status, &check_change_requests(&1))

    case Repo.transaction(multi) do
      {:ok, %{change_request: change_request}} ->
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp check_change_requests(%{change_request: request}) do
    requests = from(cr in ChangeRequest)
    |> where([cr], cr.class_id == ^request.class_id and cr.id != ^request.id)
    |> where([cr], cr.is_completed == false)
    |> Repo.all()

    case requests do
      [] -> complete_class(request.class_id)
      requests -> {:ok, nil} 
    end
  end

  defp complete_class(class_id) do
    Repo.get!(Class, class_id)
    |> Ecto.Changeset.change(%{class_status_id: @complete_class_status})
    |> Repo.update()
  end
end