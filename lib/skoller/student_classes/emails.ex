defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Repo
  alias Skoller.EmailJobs
  alias Skoller.EmailJobs.EmailJob
  alias Skoller.EmailLogs.EmailLog
  alias Skoller.Users.EmailPreferences
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
  @asa_name "Alpha Sigma Alpha"

  @env_url System.get_env("WEB_URL")

  @doc """
  Queues emails for the type and options specified
  """
  def queue_email_jobs(user_info, email_job_id) do
    user_info
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, email_job_id))
    |> Enum.each(&EmailJobs.create_email_job(&1.user.id, email_job_id, &1.opts))
  end

  ################
  # Email sender #
  ################

  def send_emails(email_job_id, emails) do
    template_info =
      emails
      |> Enum.map(&load_template_data(email_job_id, &1))

    # Separate org emails from non_org emails

    template_id = template_name(email_job_id)

    # First, org emails
    org_template_data =
      template_info |> Enum.filter(& &1[:is_org]) |> Enum.map(& &1[:template_data])

    # Now, non-org emails
    non_org_template_data =
      template_info
      |> Enum.filter(&(!&1[:is_org]))
      |> Enum.map(& &1[:template_data])

    # Send both
    SesMailer.send_batch_email(
      org_template_data,
      "org_" <> template_id
    )

    SesMailer.send_batch_email(
      non_org_template_data,
      template_id
    )
  end

  ###################
  # Template loader #
  ###################

  defp load_template_data(email_job_id, %EmailJob{user: user, options: opts}) do
    email_job_id |> log_email_sent(user.id)

    template_data =
      opts
      |> template(email_job_id)
      |> Map.put(:unsub_path, unsub_url(user.id))

    %{
      is_org: Map.get(opts, "org_name") != nil,
      template_data: %{to: user.email, form: template_data}
    }
  end

  ####################
  # Template builder #
  ####################

  # No classes
  ############

  defp template(%{"org_name" => @asa_name}, @no_classes_id),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/join_classes/asa_join_classes.png"
    }

  defp template(%{"org_name" => @aopi_name}, @no_classes_id),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/join_classes/aoii_needs_classes.png"
    }

  # Needs setup
  #############

  defp template(%{"org_name" => @asa_name, "class_name" => class_name}, @needs_setup_id),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/syllabus_needed/asa_needs_setup.png",
      class_name: class_name
    }

  defp template(%{"org_name" => @aopi_name, "class_name" => class_name}, @needs_setup_id),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/syllabus_needed/setup_class_aopi.png",
      class_name: class_name
    }

  defp template(opts, @needs_setup_id), do: opts |> Map.take(["class_name"])

  # Grow community
  ################

  defp template(
         %{"org_name" => @asa_name, "student_class_link" => link} = opts,
         @grow_community_id
       ),
       do:
         opts
         |> Map.take(["org_name", "class_name"])
         |> Map.put(:student_class_link, share_url(link))
         |> Map.merge(%{
           org_philanthropy_name: @asa_foundation,
           org_plus_skoller: @asa_plus_skoller,
           header_img_url:
             "https://classnav-email-images.s3.amazonaws.com/community_features/asa_grow_community.png"
         })

  defp template(
         %{"org_name" => @aopi_name, "student_class_link" => link} = opts,
         @grow_community_id
       ),
       do:
         opts
         |> Map.take(["org_name", "class_name"])
         |> Map.put("student_class_link", share_url(link))
         |> Map.merge(%{
           org_philanthropy_name: @aopi_foundation,
           org_plus_skoller: @aopi_plus_skoller,
           header_img_url:
             "https://classnav-email-images.s3.amazonaws.com/community_features/grow_community_aopi.png"
         })

  defp template(%{"org_name" => name, "student_class_link" => link} = opts, @grow_community_id)
       when not is_nil(name) do
    IO.puts("LOOK AT ME")

    opts
    |> IO.inspect()
    |> Map.take(["class_name"])
    |> Map.put("student_class_link", share_url(link))
  end

  defp template(%{"student_class_link" => link} = opts, @grow_community_id),
    do: opts |> Map.take(["class_name"]) |> Map.put("student_class_link", share_url(link))

  # Join second class
  ###################

  defp template(%{"org_name" => @asa_name}, @join_second_class_id),
    do: %{
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/second_class/asa_second_class.png"
    }

  defp template(%{"org_name" => @aopi_name}, @join_second_class_id),
    do: %{
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/second_class/second_class_aopi.png"
    }

  defp template(_, _), do: %{}

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
  defp unsub_url(user_id), do: @env_url <> "/unsubscribe/" <> (user_id |> to_string)

  defp share_url(link), do: @env_url <> "/e/" <> link
end
