defmodule Skoller.ChangeRequests do
  @moduledoc """
  The context module for change requests
  """

  alias Skoller.Repo
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.ChangeRequests.ChangeRequestMember
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.ChangeRequests.Emails
  alias Skoller.Classes
  alias Skoller.ChangeRequests.Type
  alias Ecto.Multi

  import Ecto.Query

  @doc """
  Creates a change request and checks the class status.
  """
  def create(class_id, %{"data" => %{} = data} = attrs) do
    class = Classes.get_class_by_id!(class_id) |> Repo.preload(:class_status)

    changeset =
      ChangeRequest.changeset(%ChangeRequest{}, attrs)
      |> can_have_change_request?(class)

    Multi.new()
    |> Multi.insert(:change_request, changeset)
    |> Multi.merge(&create_members_multi(&1, data))
    |> Multi.run(:class, fn _, changes ->
      full_request = changes.change_request |> Repo.preload(:class_change_request_members)

      ClassStatuses.check_status(class, %{
        changes
        | change_request_members: full_request.class_change_request_members
      })
    end)
    |> Repo.transaction()
  end

  defp create_members_multi(%{change_request: %{id: request_id}}, data) do
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    data_pseudo_changesets =
      data
      |> Enum.map(&create_member(&1, request_id, timestamp))
      |> Enum.filter(&(Enum.count(&1) > 0))

    Multi.new()
    |> Multi.insert_all(:change_request_members, ChangeRequestMember, data_pseudo_changesets)
  end

  defp create_member({k, v}, change_request_id, timestamp) when is_binary(v),
    do: %{
      name: k,
      value: v,
      class_change_request_id: change_request_id,
      inserted_at: timestamp,
      updated_at: timestamp
    }

  defp create_member(_, _, _), do: %{}

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
    change_request =
      Repo.get!(ChangeRequest, id)
      |> Repo.preload([:class, user: :student])

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    change_request_changeset = change_request |> ChangeRequest.changeset(%{updated_at: now})

    update_member_query = ChangeRequestMember |> where([m], m.class_change_request_id == ^id)

    updates = [set: [is_completed: true, updated_at: DateTime.utc_now()]]

    multi =
      Multi.new()
      |> Multi.update(:change_request, change_request_changeset)
      |> Multi.update_all(:change_request_members, update_member_query, updates)
      |> Multi.run(:class_status, fn _, changes ->
        ClassStatuses.check_status(change_request.class, changes)
      end)
      |> Repo.transaction()

    case multi do
      {:ok, _} ->
        Emails.send_request_completed_email(change_request)

      failure ->
        IO.inspect(failure)
    end

    multi
  end

  @doc """
  Gets a list of the change request types.
  """
  def get_types(), do: Repo.all(Type)

  # Checks if a class is compatible with a change request
  defp can_have_change_request?(changeset, %{class_status: %{is_complete: true}}), do: changeset

  defp can_have_change_request?(changeset, _class),
    do:
      changeset
      |> Ecto.Changeset.add_error(:change_request, "Class is incomplete, use Help Request.")
end
