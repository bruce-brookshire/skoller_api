defmodule Skoller.ChangeRequests.Emails do
  @moduledoc """
  A context module for change request emails
  """

  alias Skoller.Repo
  alias Skoller.Services.Email
  alias Skoller.Services.Mailer

  import Bamboo.Email

  @from_email "noreply@skoller.co"
  @change_approved " info change has been approved!"
  @we_approved_change "We have approved your request to change class information for "
  @ending "We hope you and your classmates have a great semester!"

  def send_request_completed_email(user, class) do
    user = user |> Repo.preload(:student)
    new_email()
    |> to(user.email)
    |> from(@from_email)
    |> subject(class.name <> @change_approved)
    |> html_body("<p>" <> user.student.name_first <> ",<br /><br >" <> @we_approved_change <> class.name <> "<br /><br />" <> @ending <> "</p>" <> Email.signature())
    |> text_body(user.student.name_first <> ",\n \n" <> @we_approved_change <> class.name <> "\n \n" <> @ending <> "\n \n" <> Email.text_signature())
    |> Mailer.deliver_later
  end
end