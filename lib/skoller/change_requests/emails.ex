defmodule Skoller.ChangeRequests.Emails do
  @moduledoc """
  A context module for change request emails
  """

  alias Skoller.Services.TriggeredEmail

  @change_approved " info change has been approved!"

  def send_request_completed_email(email, student, class) do
    TriggeredEmail.send_email(email, class.name <> @change_approved, :request_completed, [student_name_first: (if student, do: student.name_first else: "Student"), class_name: class.name])
  end
end