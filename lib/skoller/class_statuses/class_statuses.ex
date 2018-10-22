defmodule Skoller.ClassStatuses do
  @moduledoc """
    Context module for class statuses.
  """

  alias Skoller.Repo
  alias Skoller.ClassStatuses.Status
  alias Skoller.Classes
  alias Skoller.ClassStatuses.Emails
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses

  @syllabus_status 200

  @doc """
  Gets a class status by status id

  ## Returns
  `Skoller.ClassStatuses.Status` or raises
  """
  def get_status_by_id!(id) do
    Repo.get!(Status, id)
  end

  @doc """
  Gets all class statuses

  ## Returns
  `[Skoller.ClassStatuses.Status]` or `[]`
  """
  def get_statuses() do
    Repo.all(Status)
  end

  @doc """
  Updates a class status as an administrator.

  This bypasses a lot of protections of other methods of changing a class.
  Because of this, there are some after effects of the change.

  ## Behavior
   * A class cannot be moved from a status considered complete, to an incomplete status.
   * If a class is moved to a lower status, any locks will be destroyed (down to the new status).
   * If a class is moved back to needs syllabus, it will email students in an attempt to re-upload.
   * If a class is completed, `Skoller.ClassStatuses.Classes.evaluate_class_completion/2` is called.

  ## Returns
  `{:ok, class}` or `{:error, changeset}`
  """
  def update_status(class_id, status_id) do
    old_class = Classes.get_class_by_id!(class_id)
    |> Repo.preload(:class_status)

    status = get_status_by_id!(status_id)

    update_result = old_class
    |> Ecto.Changeset.change(%{class_status_id: status_id})
    |> compare_class_status_completion(old_class.class_status.is_complete, status.is_complete)
    |> Repo.update()

    case update_result do
      {:ok, %{class_status_id: @syllabus_status} = class} ->
        Emails.send_need_syllabus_email(class)
      {:ok, class} ->
        ClassStatuses.evaluate_class_completion(old_class, class)
      _ -> nil
    end

    update_result
  end

  defp compare_class_status_completion(changeset, true, false) do
    changeset
    |> Ecto.Changeset.add_error(:class_status_id, "Class status moving from complete to incomplete")
  end
  defp compare_class_status_completion(changeset, _, _), do: changeset
end