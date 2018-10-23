defmodule Skoller.HelpRequests do
  @moduledoc """
  The context module for help requests.
  """

  alias Skoller.Repo
  alias Skoller.HelpRequests.HelpRequest
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.Classes

  # @wrong_syllabus_type 100
  # @bad_file_type 300

  @doc """
  Creates a help request and moves class to the appropriate status.
  """
  def create(class_id, attrs) do
    changeset = HelpRequest.changeset(%HelpRequest{}, attrs)
    |> Ecto.Changeset.change(%{is_completed: true})

    class = Classes.get_class_by_id!(class_id) |> Repo.preload(:class_status)
    
    Ecto.Multi.new
    |> Ecto.Multi.insert(:help_request, changeset)
    |> Ecto.Multi.run(:class, &ClassStatuses.check_status(class, &1))
    |> Repo.transaction()
  end
end