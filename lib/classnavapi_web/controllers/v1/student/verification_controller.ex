defmodule ClassnavapiWeb.Api.V1.Student.VerificationController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Student
  alias ClassnavapiWeb.Helpers.VerificationHelper
  alias ClassnavapiWeb.Sms

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def resend(conn, %{"student_id" => student_id}) do
    student = Student |> Repo.get!(student_id)

    code = VerificationHelper.generate_verify_code()

    student = student |> Ecto.Changeset.change(%{verification_code: code})

    case Repo.update(student) do
      {:ok, student} -> 
        student.phone |> Sms.verify_phone(student.verification_code)
        conn
        |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end