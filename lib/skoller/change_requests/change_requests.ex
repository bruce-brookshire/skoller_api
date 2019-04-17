defmodule Skoller.ChangeRequests do
  @moduledoc """
  The context module for change requests
  """

  alias Skoller.Repo
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.ChangeRequests.Emails
  alias Skoller.Classes
  alias Skoller.ChangeRequests.Type

  @doc """
  Creates a change request and checks the class status.
  """
  def create(class_id, attrs) do
    class = Classes.get_class_by_id!(class_id) |> Repo.preload(:class_status)

    changeset = ChangeRequest.changeset(%ChangeRequest{}, attrs)
    |> can_have_change_request?(class)
    
    Ecto.Multi.new
    |> Ecto.Multi.insert(:change_request, changeset)
    |> Ecto.Multi.run(:class, fn (_, changes) -> ClassStatuses.check_status(class, changes) end)
    |> Repo.transaction()
  end

  @doc """
  Completes a change requests and informs the user that the request has been processed.

  ## Notes
   * May change class status.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` contains 
   * `{:change_request, Skoller.ChangeRequests.ChangeRequest}`
   * `{:class_status, Skoller.Classes.Class}`
  """
  def complete_change_request(id) do
    change_request_old = Repo.get!(ChangeRequest, id)
    |> Repo.preload(:class)
    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:change_request, changeset)
    |> Ecto.Multi.run(:class_status, fn (_, changes) -> ClassStatuses.check_status(change_request_old.class, changes) end)
    |> Repo.transaction()

    case multi do
      {:ok, %{change_request: change_request}} ->
        change_request = change_request |> Repo.preload([user: :student])
        change_request.user.email |> Emails.send_request_completed_email(change_request.user.student, change_request_old.class)
      _ -> nil
    end

    multi
  end

  @doc """
  Gets a list of the change request types.
  """
  def get_types(), do: Repo.all(Type)

  # Checks if a class is compatible with a change request
  defp can_have_change_request?(changeset, %{class_status: %{is_complete: true}}), do: changeset
  defp can_have_change_request?(changeset, _class), do: changeset |> Ecto.Changeset.add_error(:change_request, "Class is incomplete, use Help Request.")
end
