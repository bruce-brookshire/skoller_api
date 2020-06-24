defmodule SkollerWeb.Api.V1.Organization.OrgStudentController do
  alias Skoller.{Organizations.OrgStudents, FileUploaders.ProfilePics, Users}
  alias SkollerWeb.Organization.OrgStudentView
  alias SkollerWeb.Responses.MultiError
  alias Ecto.UUID

  use ExMvc.Controller,
    adapter: OrgStudents,
    view: OrgStudentView,
    only: [:show, :index, :update, :delete]

  def upload_avatar(conn, %{"file" => file, "org_student_id" => org_student_id}) do
    scope = %{"id" => UUID.generate()}

    with %{users: users} <- OrgStudents.get_by_id(org_student_id),
         %Users.User{} = user_old <- List.first(users),
         {:ok, inserted} <- ProfilePics.store({file, scope}),
         location <- ProfilePics.url({inserted, scope}, :thumb),
         {:ok, %{user: _user}} <-
           Users.update_user(user_old, %{"pic_path" => location}, admin_update: true) do
      org_student = OrgStudents.get_by_id(org_student_id)

      conn
      |> put_view(OrgStudentView)
      |> render("show.json", model: org_student)
    else
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)

      _ ->
        conn |> send_resp(422, "Unprocessable Entity")
    end
  end
end
