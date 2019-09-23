defmodule Skoller.ChangeRequests.Emails do
  @moduledoc """
  A context module for change request emails
  """

  alias Skoller.Services.SesMailer
  alias Skoller.ChangeRequests.ChangeRequest

  def send_request_completed_email(%ChangeRequest{
        user: %{email: email, student: student},
        class: class
      }),
      do: send_request_completed_email(email, student, class)

  def send_request_completed_email(email, student, class) do
    SesMailer.send_individual_email(
      %{
        to: email,
        form: %{
          student_name_first: if(student, do: student.name_first, else: "Student"),
          class_name: class.name
        }
      },
      "change_request_completed"
    )
  end
end
