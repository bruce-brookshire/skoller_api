defmodule SkollerWeb.Api.V1.StudentController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Students
  alias Skoller.Students.Student
  alias SkollerWeb.StudentView

  def show(conn, %{"token" => token}) do
    student = Students.get_student_by_enrollment_link!(token)

    conn
    |> put_view(StudentView)
    |> render("show.json", link: student)
  end

  def store_venmo_handle(conn, %{"student_id" => student_id, "venmo_handle" => venmo_handle}) do
    case Skoller.Repo.get(Student, student_id)
    |> Student.changeset(%{venmo_handle: venmo_handle})
    |> Skoller.Repo.update() do
      {:ok, student} ->
        conn
        |> put_view(StudentView)
        |> render("venmo_handle.json", student: student)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_view(StudentView)
        |> render("venmo_handle.json", changeset: changeset)
    end
  end
end
