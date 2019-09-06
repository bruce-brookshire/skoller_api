defmodule Skoller.EmailJobs do
  @moduledoc """
  A context module for the email logs
  """

  alias Skoller.Repo
  alias Skoller.EmailJobs.EmailJob

  import Ecto.Query

  @doc """
  Create email job
  """
  def create_email_job(user_id, email_type_id, options \\ nil) do
    changeset = EmailJob.changeset(%EmailJob{}, %{
      user_id: user_id,
      email_type_id: email_type_id,
      options: options
    })

    Repo.insert!(changeset)
  end

  @doc """
  Gets the next jobs to run

  ## Params
  [Int] limit. The number of jobs to get from the queue.
  ## Returns
  [Int] count.
  """
  def get_next_jobs(email_type_id, limit) do
    query = from e in EmailJob,
            where: e.is_running == false and e.email_type_id == ^email_type_id,
            order_by: [asc: e.updated_at],
            limit: ^limit,
            preload: [:user]

    query |> Repo.all()
  end

  @doc """
  Sets an array of ids to running.

  ## Params
  [Array] ids. Array of ids to query for.
  """
  def set_jobs_to_running(ids) do
    query = from e in EmailJob,
            where: e.id in ^ ids

    query |> Repo.update_all(set: [is_running: true])
  end


  @doc """
  Delete the job from the database

  ## Params
  [Int] id. The id of the job to delete.
  """
  def delete_job(id) do
    email_job = Repo.get!(EmailJob, id)
    Repo.delete!(email_job)
  end
end
