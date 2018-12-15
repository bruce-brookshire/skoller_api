defmodule SkollerWeb.Api.V1.Student.VerificationController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Students

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def resend(conn, %{"student_id" => student_id}) do
    student = Students.get_student_by_id!(student_id)

    case Students.reset_verify_code(student) do
      {:ok, _student} -> 
        conn
        |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def verify(conn, %{"student_id" => student_id, "verification_code" => code}) do
    student = Students.get_student_by_id!(student_id)

    case Students.check_verification_code(student, code) do
      true -> conn |> send_resp(204, "")
      false -> conn |> send_resp(401, "")
    end
  end
end