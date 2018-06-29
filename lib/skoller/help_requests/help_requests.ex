defmodule Skoller.HelpRequests do
  @moduledoc """
  The context module for help requests.
  """

  alias Skoller.Repo
  alias Skoller.HelpRequests.HelpRequest

  @doc """
  Completes a help request.

  ## Returns
  `{:ok, Skoller.HelpRequests.HelpRequest}` or `{:error, Ecto.Changeset}`
  """
  def complete(request_id) do
    HelpRequest
    |> Repo.get!(request_id)
    |> HelpRequest.changeset(%{is_completed: true})
    |> Repo.update()
  end
end