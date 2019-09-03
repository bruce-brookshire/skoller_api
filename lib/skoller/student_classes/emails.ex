defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Repo
  alias Skoller.EmailJobs
  alias Skoller.Organizations
  alias Skoller.EmailLogs.EmailLog
  alias Skoller.Users.EmailPreferences
  alias Skoller.Organizations.Organization
  alias Skoller.Services.SesMailer

  @no_classes_id 100
  @needs_setup_id 200
  @grow_community_id 500
  @join_second_class_id 600

  @aopi_plus_skoller "https://classnav-email-images.s3.amazonaws.com/general_philanthropy_assets/aoii_plus_skoller.png"
  @asa_plus_skoller "https://classnav-email-images.s3.amazonaws.com/general_philanthropy_assets/asa_plus_skoller.png"

  @aopi_foundation "Arthritis Foundation"
  @asa_foundation "Alpha Sigma Alpha Foundation"

  @aopi_name "AOII"
  @asa_name "ASA"

  @env_url System.get_env("WEB_URL")

  @doc """
  Queues the no classes email to the list of `users`
  """
  def queue_no_classes_emails(user_info) do
    user_info
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, @no_classes_id))
    |> Enum.map(&queue_no_classes_email(&1))
  end

  @doc """
  Queue the class needs setup email for the list of `user_info`
  """
  def queue_needs_setup_emails(user_info) do
    user_info
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, @needs_setup_id))
    |> Enum.map(&queue_needs_setup_email(&1))
  end

  @doc """
  Queue the class grow community email for the list of `user_info`
  """
  def queue_grow_community_emails(user_info) do
    user_info
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, @grow_community_id))
    |> Enum.map(&queue_grow_community_email(&1))
  end

  @doc """
  Queue the join second class email for the list of `users`
  """
  def queue_join_second_class_emails(user_info) do
    user_info
    |> Enum.filter(
      &EmailPreferences.check_email_subscription_status(&1.user, @join_second_class_id)
    )
    |> Enum.map(&queue_join_second_class_email(&1))
  end

  @doc """
  Queues a no classes email for a user
  """
  def queue_no_classes_email(user_info) do
    EmailJobs.create_email_job(user_info.user.id, @no_classes_id)
  end

  @doc """
  Queues needs setup email for a user
  """
  def queue_needs_setup_email(user_info) do
    EmailJobs.create_email_job(user_info.user.id, @needs_setup_id)
  end

  @doc """
  Queues grow community email for a user 
  """
  def queue_grow_community_email(user_info) do
    EmailJobs.create_email_job(user_info.user.id, @grow_community_id)
  end

  @doc """
  Queues join second class email for a user
  """
  def queue_join_second_class_email(user_info) do
    EmailJobs.create_email_job(user_info.user.id, @grow_community_id)
  end

  ################
  # Email sender #
  ################

  def send_emails(email_job_id, emails) do
    template_info =
      emails
      |> Enum.map(&load_template_data(email_job_id, &1.user, &1.options))

    # Separate org emails from non_org emails

    template_id = template_name(email_job_id)

    # First, org emails
    org_template_data = template_info |> Enum.filter(& &1[:is_org]) |> Enum.map(& &1[:template_data])

    # Now, non-org emails
    non_org_template_data = template_info |> Enum.filter(&(!&1[:is_org]))
    |> Enum.map(& &1[:template_data])

    # Send both
    SesMailer.send_batch_email(
      org_template_data
      "org_" <> template_id,
    )

    SesMailer.send_batch_email(
      non_org_template_data,
      template_id
    )
  end

  ###################
  # Template loader #
  ###################

  defp load_template_data(email_job_id, user, opts) do
    email_job_id |> log_email_sent(user.id)

    org = Organizations.get_student_associated_organization(user.student_id)

    template_data =
      org
      |> template(email_job_id, opts)
      |> Map.put(:unsub_path, unsub_url(user.id))

    %{
      is_org: org != nil,
      template_data: %{to: user.email, form: template_data}
    }
  end

  ####################
  # Template builder #
  ####################

  # No classes
  ############

  defp template(%Organization{name: @asa_name}, @no_classes_id, _opts),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/join_classes/asa_join_classes.png"
    }

  defp template(%Organization{name: @aopi_name}, @no_classes_id, _opts),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/join_classes/aoii_needs_classes.png"
    }

  # Needs setup
  #############

  defp template(%Organization{name: @asa_name}, @needs_setup_id, opts),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/syllabus_needed/asa_needs_setup.png",
      class_name: opts
    }

  defp template(%Organization{name: @aopi_name}, @needs_setup_id, opts),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/syllabus_needed/setup_class_aopi.png",
      class_name: opts
    }

  defp template(_, @needs_setup_id, opts), do: %{class_name: opts}

  # Grow community
  ################

  defp template(%Organization{name: @asa_name}, @grow_community_id, opts),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/community_features/asa_grow_community.png",
      class_name: opts
    }

  defp template(%Organization{name: @aopi_name}, @grow_community_id, opts),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/community_features/grow_community_aopi.png",
      class_name: opts
    }

  defp template(_, @grow_community_id, opts), do: %{class_name: opts}

  # Join second class
  ###################

  defp template(%Organization{name: @asa_name}, @join_second_class_id, _opts),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/second_class/asa_second_class.png"
    }

  defp template(%Organization{name: @aopi_name}, @join_second_class_id, _opts),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/second_class/second_class_aopi.png"
    }

  defp template(_, _, _), do: %{}

  ##################
  # Template names #
  ##################

  defp template_name(@no_classes_id), do: "needs_classes"
  defp template_name(@needs_setup_id), do: "needs_setup"
  defp template_name(@grow_community_id), do: "unlock_community"
  defp template_name(@join_second_class_id), do: "second_class"

  # Email sent logger
  defp log_email_sent(status_id, user_id) do
    Repo.insert(%EmailLog{user_id: user_id, email_type_id: status_id})
  end

  # Create unsub path
  defp unsub_url(user_id) do
    @env_url <> "/unsubscribe/" <> (user_id |> to_string)
  end
end
