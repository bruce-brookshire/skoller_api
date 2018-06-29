defmodule SkollerWeb.Api.V1.Student.VerificationController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Verification
  alias SkollerWeb.Sms

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def resend(conn, %{"student_id" => student_id}) do
    student = Student |> Repo.get!(student_id)

    code = Verification.generate_verify_code()

    student = student |> Ecto.Changeset.change(%{verification_code: code})

    case Repo.update(student) do
      {:ok, student} -> 
        student.phone |> Sms.verify_phone(student.verification_code)
        conn
        |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def verify(conn, %{"student_id" => student_id, "verification_code" => code}) do
    student = Student |> Repo.get!(student_id)

    case student.verification_code == code do
      true -> student 
              |> verified(conn)
      false -> conn |> send_resp(401, "")
    end
  end

  defp verified(student, conn) do
    student 
    |> Ecto.Changeset.change(%{is_verified: true})
    |> Repo.update!

    conn |> send_resp(204, "")
  end
end