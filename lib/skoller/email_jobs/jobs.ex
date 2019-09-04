defmodule Skoller.EmailJobs.Jobs do
  @moduledoc false

  alias Skoller.EmailJobs
  alias Skoller.StudentClasses.Emails

  @aws_batch_max_recipients 50

  @no_classes_id 100
  @needs_setup_id 200
  @grow_community_id 500
  @join_second_class_id 600

  def run_jobs do
    [
      %{id: @no_classes_id},
      %{id: @needs_setup_id},
      %{id: @grow_community_id},
      %{id: @join_second_class_id}
    ]
    |> Enum.map(fn %{id: id} = job ->
      emails = EmailJobs.get_next_jobs(id, @aws_batch_max_recipients)

      Map.put(job, :emails, emails)
    end)
    |> Enum.filter(fn job ->
      job[:emails] |> Enum.count() > 0
    end)
    |> Enum.each(&spawn(Skoller.EmailJobs.Jobs, :start_email_job, [&1]))
  end

  def start_email_job(job) do
    require Logger

    id = job[:id]
    Logger.info("Starting: email job #{id}")

    job
    |> mark_running()
    |> send_email()
    |> remove_on_complete()

    Logger.info("Finished: email job #{id}")
  end

  defp mark_running(%{emails: emails} = job) do
    emails |> Enum.map(& &1.id) |> EmailJobs.set_jobs_to_running()

    job
  end

  defp send_email(%{id: id, emails: emails} = job) do
    apply(Emails, :send_emails, [id, emails])

    job
  end

  def remove_on_complete(%{emails: emails}) do
    emails |> Enum.each(&EmailJobs.delete_job(&1.id))
  end
end
