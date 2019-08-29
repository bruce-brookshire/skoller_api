defmodule Skoller.EmailJobs.Jobs do
  @moduledoc false

  alias Skoller.EmailJobs
  alias Skoller.StudentClasses.Emails

  @aws_batch_max_recipients 50

  @no_classes_id 100
  @needs_setup_id 200
  @grow_community_id 500
  @join_second_class_id 600

  def run_manager do
    next_jobs =
      [
        %{id: @no_classes_id, function: :send_no_classes_email},
        %{id: @needs_setup_id, function: :send_needs_setup_email},
        %{id: @grow_community_id, function: :send_grow_community_email},
        %{id: @join_second_class_id, function: :send_join_second_class_email}
      ]
      |> Enum.each(fn %{id: id} = job ->
        emails = EmailJobs.get_next_jobs(id, @aws_batch_max_recipients)

        job = Map.put(job, :emails, emails)

        spawn(Skoller.EmailJobs.Jobs, :start_email_job, job)
      end)
  end

  def start_email_job(job) do
    job
    |> mark_running()
    |> send_email()
    |> remove_on_complete()
  end

  defp mark_running(%{emails: emails} = job) do
    emails |> Enum.map(& &1.id) |> EmailJobs.set_jobs_to_running()

    job
  end

  defp send_email(%{function: function, emails: emails} = job) do
    apply(Emails, function, emails)

    job
  end

  def remove_on_complete(%{emails: emails}) do
    emails |> Enum.each(&EmailJobs.delete_job(&1.id))
  end
end
