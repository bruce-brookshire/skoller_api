defmodule SkollerWeb.Api.V1.Organization.OrgGroupStudentController do
  alias Skoller.{Organizations.OrgGroupStudents, FileUploaders.ProfilePics, Users, Repo}
  alias SkollerWeb.Organization.OrgGroupStudentView
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.UserView
  alias Ecto.UUID

  use ExMvc.Controller, adapter: OrgGroupStudents, view: OrgGroupStudentView

  def upload_avatar(conn, %{"file" => file, "org_student_id" => org_student_id}) do
    scope = %{"id" => UUID.generate()}

    with %{users: users} <- OrgGroupStudents.get_by_id(org_student_id),
         %Users.User{} = user_old <- List.first(users),
         {:ok, inserted} <- ProfilePics.store({file, scope}),
         location <- ProfilePics.url({inserted, scope}, :thumb),
         {:ok, %{user: user}} <-
           Users.update_user(user_old, %{"pic_path" => location}, admin_update: true) do
      user = user |> Repo.preload([:student, :roles], force: true)

      conn
      |> put_view(UserView)
      |> render("show.json", user: user)
    else
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)

      _ ->
        conn |> send_resp(422, "Unprocessable Entity")
    end
  end
end
