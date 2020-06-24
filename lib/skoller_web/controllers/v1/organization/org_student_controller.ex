defmodule SkollerWeb.Api.V1.Organization.OrgStudentController do
  alias Skoller.Organizations.OrgStudents
  alias Skoller.Users
  alias SkollerWeb.Organization.OrgStudentView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.FileUploaders.ProfilePics
  alias Ecto.UUID
  alias Skoller.Repo

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
