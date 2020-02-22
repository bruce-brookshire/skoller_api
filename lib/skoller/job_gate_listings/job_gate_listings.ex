defmodule Skoller.JobGateListings do
  import Ecto.Query

  alias Skoller.JobGateListings.JobGateListing
  alias Skoller.Repo

  @post_action "Post"
  @amend_action "Amend"
  @delete_action "Delete"

  def perform_job_action(
        %{action: @post_action, description_html: desc, sender_reference: sender_reference} =
          listing
      ) do
    try do
      listing
      |> JobGateListing.insert_changeset()
      |> Repo.insert()

      # |> generate_result(sender_reference)
    catch
      :error, error2 ->
        if(String.length(desc) > 10000,
          do: {:error, "Description longer than 10,000 characters"},
          else: {:error, "Error inserting"}
        )

      _, _ ->
        {:error, "Unknown error"}
    end
    |> generate_result(sender_reference)
  end

  def perform_job_action(%{action: @amend_action, sender_reference: sender_reference} = listing) do
    JobGateListing
    |> Repo.get(sender_reference)
    |> JobGateListing.update_changeset(listing)
    |> Repo.update()
    |> generate_result(sender_reference)
  end

  def perform_job_action(%{action: @delete_action, sender_reference: sender_reference} = listing) do
    try do
      JobGateListing
      |> Repo.get(sender_reference)
      |> Repo.delete()
    catch 
      :error, _ ->  {:error, "Job does not exist"}
      _, _ -> {:error, "Unknown error"}
    end
    |> generate_result(sender_reference)
  end

  def perform_job_action(_), do: nil

  defp generate_result({:error, %Ecto.Changeset{errors: errors} = changeset}, sender_reference) do
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
end
