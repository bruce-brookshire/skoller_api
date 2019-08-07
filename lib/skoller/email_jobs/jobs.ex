defmodule Skoller.EmailJobs.Jobs do
  @moduledoc false

  alias Skoller.EmailJobs
  alias Skoller.StudentClasses.Emails

  @max_number_of_processes 10

  @no_classes_id 100
  @needs_setup_id 200
  @grow_community_id 500
  @join_second_class_id 600

  def run_manager do
    # get the number of jobs
    number_of_running_jobs = EmailJobs.get_number_of_running_jobs()

    # grab the next jobs
    next_jobs = EmailJobs.get_next_jobs(@max_number_of_processes - number_of_running_jobs)

    # set the jobs to running, so next time the manager runs, it does not grab the emails
    next_jobs |> Enum.map(& &1.id) |> EmailJobs.set_jobs_to_running()

    # send an email for each entry in the db
    next_jobs |> Enum.each(&send_email(&1))
  end

  defp send_email(email_job) do
    case email_job.email_type_id do
      @no_classes_id ->
        spawn(Emails, :send_no_classes_email, [email_job.user])

      @needs_setup_id ->
        spawn(Emails, :send_needs_setup_email, [email_job.user, email_job.options])

      @grow_community_id ->
        spawn(Emails, :send_grow_community_email, [email_job.user, email_job.options])

      @join_second_class_id ->
        spawn(Emails, :send_join_second_class_email, [email_job.user])
    end

    # delete the entry from the database after it is sent
    EmailJobs.delete_job(email_job.id)
  end
end
