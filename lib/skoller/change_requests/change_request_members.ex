defmodule Skoller.ChangeRequests.ChangeRequestMembers do
  alias Ecto.Multi
  alias Skoller.Repo
  alias Skoller.ChangeRequests.Emails
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.ChangeRequests.ChangeRequestMember
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses

  def create({name, value}, change_request_id) do
    %ChangeRequestMember{}
    |> ChangeRequestMember.changeset(%{
      name: name,
      value: value,
      class_change_request_id: change_request_id
    })
    |> Repo.insert()
  end

  def set_completed(id) do
    %{class_change_request: change_request} =
      member_old =
      Repo.get(ChangeRequestMember, id)
      |> Repo.preload(class_change_request: [:class, user: :student])

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    change_request_changeset =
      change_request
      |> ChangeRequest.changeset(%{updated_at: now})

    member_changeset =
      member_old
      |> ChangeRequestMember.changeset(%{is_completed: true})

    multi =
      Multi.new()
      |> Multi.update(:change_request, change_request_changeset)
      |> Multi.update(:change_request_member_update, member_changeset)
      |> Multi.run(
        :change_request_members,
        fn _, _ ->
          members =
            Repo.preload(change_request, :class_change_request_members).class_change_request_members

          {:ok, members}
        end
      )
      |> Multi.run(:class, fn _, changes ->
        ClassStatuses.check_status(change_request.class, changes)
      end)
      |> Repo.transaction()

    case multi do
      {:ok, %{change_request_members: members}} ->
        check_needs_send_email(members, change_request)

      _ ->
        nil
    end

    multi
  end

  defp check_needs_send_email(members, change_request) when is_list(members) do
    any_incomplete = members |> Enum.any?(&(!&1.is_completed))

    # We are checking if there are any remaining members to check before alerting student via email
    if not any_incomplete do
      Emails.send_request_completed_email(change_request)
    end
  end

  defp check_needs_send_email(_, _), do: nil
end
