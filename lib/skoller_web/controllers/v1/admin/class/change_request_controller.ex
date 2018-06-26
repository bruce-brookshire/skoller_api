defmodule SkollerWeb.Api.V1.Admin.Class.ChangeRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias SkollerWeb.Class.ChangeRequestView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Class.ChangeRequest
  alias Skoller.Classes
  alias Skoller.Mailer

  import SkollerWeb.Plugs.Auth
  import Bamboo.Email

  @from_email "noreply@skoller.co"
  @change_approved " info change has been approved!"
  @we_approved_change "We have approved your request to change class information for "
  @ending "We hope you and your classmates have a great semester!"
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@change_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    change_request_old = Repo.get!(ChangeRequest, id)

    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    class = Classes.get_class_by_id!(change_request_old.class_id)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:change_request, changeset)
    |> Ecto.Multi.run(:class_status, &Classes.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{change_request: %{user_id: nil} = change_request}} ->
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:ok, %{change_request: %{user_id: _user_id} = change_request}} ->
        change_request = change_request |> Repo.preload([:user, :class])
        change_request.user |> send_request_completed_email(change_request.class)
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:ok, %{change_request: change_request}} ->
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp send_request_completed_email(user, class) do
    user = user |> Repo.preload(:student)
    new_email()
    |> to(user.email)
    |> from(@from_email)
    |> subject(class.name <> @change_approved)
    |> html_body("<p>" <> user.student.name_first <> ",<br /><br >" <> @we_approved_change <> class.name <> "<br /><br />" <> @ending <> "</p>" <> Mailer.signature())
    |> text_body(user.student.name_first <> ",\n \n" <> @we_approved_change <> class.name <> "\n \n" <> @ending <> "\n \n" <> Mailer.text_signature())
    |> Mailer.deliver_later
  end
end