defmodule Skoller.ChangeRequests.Emails do
  @moduledoc """
  A context module for change request emails
  """

  alias Skoller.Repo
  alias Skoller.Services.TriggeredEmail

  @change_approved " info change has been approved!"

  def send_request_completed_email(user, class) do
    user = user |> Repo.preload(:student)
    TriggeredEmail.send_email(user.email, class.name <> @change_approved, :request_completed, [student_name_first: user.student.name_first, class_name: class.name])
  end
end