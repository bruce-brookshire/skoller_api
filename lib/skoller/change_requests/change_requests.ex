defmodule Skoller.ChangeRequests do
  @moduledoc """
  The context module for change requests
  """

  alias Skoller.Repo
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.Classes
  alias Skoller.Services.Mailer
  alias Skoller.Classes.ClassStatuses
  alias Skoller.Services.Email

  import Bamboo.Email
  
  @from_email "noreply@skoller.co"
  @change_approved " info change has been approved!"
  @we_approved_change "We have approved your request to change class information for "
  @ending "We hope you and your classmates have a great semester!"

  @doc """
  Completes a change requests and informs the user that the request has been processed.

  ## Notes
   * May change class status.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` contains 
   * `{:change_request, Skoller.ChangeRequests.ChangeRequest}`
   * `{:class_status, Skoller.Classes.Class}`
  """
  def complete(id) do
    change_request_old = Repo.get!(ChangeRequest, id)
    
    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    class = Classes.get_class_by_id!(change_request_old.class_id)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:change_request, changeset)
    |> Ecto.Multi.run(:class_status, &ClassStatuses.check_status(class, &1))
    |> Repo.transaction()

    case multi do
      {:ok, %{change_request: change_request}} ->
        change_request = change_request |> Repo.preload([:user, :class])
        change_request.user |> send_request_completed_email(change_request.class)
      _ -> nil
    end

    multi
  end

  defp send_request_completed_email(user, class) do
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