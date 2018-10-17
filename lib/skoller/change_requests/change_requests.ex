defmodule Skoller.ChangeRequests do
  @moduledoc """
  The context module for change requests
  """

  alias Skoller.Repo
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.Classes.ClassStatuses
  alias Skoller.ChangeRequests.Emails

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
    |> Repo.preload(:class)
    
    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:change_request, changeset)
    |> Ecto.Multi.run(:class_status, &ClassStatuses.check_status(change_request_old.class, &1))
    |> Repo.transaction()

    case multi do
      {:ok, %{change_request: change_request}} ->
        change_request = change_request |> Repo.preload([:user])
        change_request.user |> Emails.send_request_completed_email(change_request_old.class)
      _ -> nil
    end

    multi
  end
end
