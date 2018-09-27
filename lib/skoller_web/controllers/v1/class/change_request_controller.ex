defmodule SkollerWeb.Api.V1.Class.ChangeRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.Repo
  alias SkollerWeb.ClassView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Classes
  alias Skoller.Classes.ClassStatuses

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do

    class = Classes.get_class_by_id!(class_id)

    params = params |> Map.put("user_id", conn.assigns[:user].id)

    changeset = ChangeRequest.changeset(%ChangeRequest{}, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:change_request, changeset)
    |> Ecto.Multi.run(:class, &ClassStatuses.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end