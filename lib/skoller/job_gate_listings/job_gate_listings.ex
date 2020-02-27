defmodule Skoller.JobGateListings do
  import Ecto.Query

  alias Skoller.JobGateListings.JobGateListing
  alias Skoller.Repo

  @post_action "Post"
  @amend_action "Amend"
  @delete_action "Delete"

  def perform_job_action(
        %{
          action: @post_action,
          sender_reference: sender_reference,
          classifications: classifications
        } = listing
      ) do
    try do
      listing
      |> JobGateListing.insert_changeset()
      |> Repo.insert()
    catch
      :error, _error ->
        {:error, "Error inserting"}

      _, _ ->
        {:error, "Unknown error"}
    end
    |> generate_result(sender_reference)
    |> handle_classification_inserts(classifications)
  end

  def perform_job_action(
        %{
          action: @amend_action,
          sender_reference: sender_reference,
          classifications: classifications
        } = listing
      ) do
    try do
      JobGateListing
      |> Repo.get(sender_reference)
      |> JobGateListing.update_changeset(listing)
      |> Repo.update()
    catch
      :error, _error ->
        {:error, "Job not found"}
    end
    |> generate_result(sender_reference)
    |> handle_classification_inserts(classifications)
  end

  def perform_job_action(%{action: @delete_action, sender_reference: sender_reference}) do
    try do
      JobGateListing
      |> Repo.get(sender_reference)
      |> Repo.delete()
    catch
      :error, _ -> {:error, "Job does not exist"}
      _, _ -> {:error, "Unknown error"}
    end
    |> generate_result(sender_reference)
  end

  def perform_job_action(_), do: nil

  def get_listings(with_offset: offset) do
    JobGateListing
    |> order_by(asc: :sender_reference)
    |> offset(^offset)
    |> limit(20)
    |> preload([:classifications])
    |> Repo.all()
  end

  defp generate_result({:error, %Ecto.Changeset{errors: errors}}, sender_reference) do
    error_msg =
      errors
      |> Enum.map(fn {field_name, {error_msg, _}} -> "#{field_name}: #{error_msg}" end)
      |> Enum.join(", ")

    %{sender_reference: sender_reference, message: error_msg, success: false}
  end

  defp generate_result({:error, message}, sender_reference),
    do: %{sender_reference: sender_reference, message: message, success: false}

  defp generate_result({:ok, _result}, sender_reference),
    do: %{sender_reference: sender_reference, message: "", success: true}

  defp handle_classification_inserts(
         %{success: true, sender_reference: sender_reference} = resp,
         classifications
       ) do
    classifications
    |> Enum.each(fn elem ->
      elem
      |> Map.put(:job_gate_sender_reference, sender_reference)
      |> Repo.insert()
    end)

    resp
  end

  defp handle_classification_inserts(resp, _), do: resp
end
