defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Repo
  alias Skoller.EmailJobs
  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.ConversionEmail
  alias Skoller.EmailLogs.EmailLog
  alias Skoller.CustomSignups
  alias Skoller.Organizations.Organization

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



  @doc """
  Queues the no classes email to the list of `users`
  """
  def queue_no_classes_emails(users) do
    users
    |> Enum.map(&List.first(&1.users))
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1, @no_classes_id))
    |> Enum.map(&queue_no_classes_email(&1))
  end

  @doc """
  Queue the class needs setup email for the list of `user_classes`
  """
  def queue_needs_setup_emails(user_classes) do
    user_classes
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, @needs_setup_id))
    |> Enum.map(&queue_needs_setup_email(&1))
  end

  @doc """
  Queue the class grow community email for the list of `user_classes`
  """
  def queue_grow_community_emails(user_classes) do
    user_classes
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, @grow_community_id))
    |> Enum.map(&queue_grow_community_email(&1))
  end

  @doc """
  Queue the join second class email for the list of `users`
  """
  def queue_join_second_class_emails(users) do
    users
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1, @join_second_class_id))
    |> Enum.map(&queue_join_second_class_email(&1))
  end

  @doc """
  Queues a no classes email for a user
  """
  def queue_no_classes_email(user) do
    EmailJobs.create_email_job(user.id, @no_classes_id)
  end

  @doc """
  Queues needs setup email for a user and class
  """
  def queue_needs_setup_email(user_class) do
    EmailJobs.create_email_job(user_class.user.id, @needs_setup_id, user_class.class_name)
  end

  @doc """
  Queues grow community email for a user and class
  """
  def queue_grow_community_email(user_class) do
    EmailJobs.create_email_job(user_class.user.id, @grow_community_id, user_class.class_name)
  end

  @doc """
  Queues join second class email for a user
  """
  def queue_join_second_class_email(user) do
    EmailJobs.create_email_job(user.id, @grow_community_id)
  end

  # No classes email sender
  def send_no_classes_email(user) do
    @no_classes_id |> log_email_sent(user.id)

    get_student_associated_organization(user.student_id)
    |> send_no_classes_email("Don't waste time on that paper planner...", user)
  end

  def send_no_classes_email(%Organization{name: @aopi_name} = org, subject, user) do
    params = [
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/join_classes/aoii_needs_classes.png"
    ]

    ConversionEmail.send_email(user.email, subject, :org_need_classes, user.id, params)
  end
  end

  def send_no_classes_email(%Organization{id: @asa_id} = org, subject, user) do
    params = [
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/join_classes/asa_join_classes.png"
    ]

    ConversionEmail.send_email(user.email, subject, :org_need_classes, user.id, params)
  end

  def send_no_classes_email(_, subject, user) do
    ConversionEmail.send_email(user.email, subject, :need_classes, user.id)
  end

  # Class needs setup email sender
  def send_needs_setup_email(user, class_name) do
    @needs_setup_id |> log_email_sent(user.id)

    get_student_associated_organization(user.student_id)
    |> send_needs_setup_email("Kickstart an easier semester!", user, class_name)
  end

  def send_needs_setup_email(%Organization{name: @aopi_name} = org, subject, user, class_name) do
    params = [
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/syllabus_needed/setup_class_aopi.png",
      class_name: class_name
    ]

    ConversionEmail.send_email(user.email, subject, :org_needs_setup, user.id, params)
  end
  end

  def send_needs_setup_email(%Organization{name: @asa_name} = org, subject, user, class_name) do
    params = [
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/syllabus_needed/asa_needs_setup.png",
      class_name: class_name
    ]

    ConversionEmail.send_email(user.email, subject, :org_needs_setup, user.id, params)
  end

  def send_needs_setup_email(_, subject, user, class_name) do
    ConversionEmail.send_email(user.email, subject, :needs_setup, user.id, class_name: class_name)
  end

  # Grow class community email sender
  def send_grow_community_email(user, class_name) do
    @grow_community_id |> log_email_sent(user.id)

    get_student_associated_organization(user.student_id)
    |> send_grow_community_email("Whoa you're missing out...", user, class_name)
  end

  def send_grow_community_email(%Organization{name: @aopi_name} = org, subject, user, class_name) do
    params = [
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      org_name: @aopi_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/community_features/grow_community_aopi.png",
      class_name: class_name
    ]

    ConversionEmail.send_email(user.email, subject, :org_unlock_community, user.id, params)
  end
  end

  def send_grow_community_email(%Organization{name: @asa_name} = org, subject, user, class_name) do
    params = [
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      org_name: @asa_name,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/community_features/asa_grow_community.png",
      class_name: class_name
    ]

    ConversionEmail.send_email(user.email, subject, :org_unlock_community, user.id, params)
  end

  def send_grow_community_email(_, subject, user, class_name) do
    ConversionEmail.send_email(user.email, subject, :unlock_community, user.id,
      class_name: class_name
    )
  end

  # Join second class email sender
  def send_join_second_class_email(user) do
    @join_second_class_id |> log_email_sent(user.id)

    get_student_associated_organization(user.student_id)
    |> send_join_second_class_email("Not organized? We'll help.", user)
  end

  def send_join_second_class_email(%Organization{name: @aopi_name} = org, subject, user) do
    params = [
      org_philanthropy_name: @aopi_foundation,
      org_plus_skoller: @aopi_plus_skoller,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/second_class/second_class_aopi.png"
    ]

    ConversionEmail.send_email(user.email, subject, :org_second_class, user.id, params)
  end
  end

  def send_join_second_class_email(%Organization{name: @asa_name} = org, subject, user) do
    params = [
      org_philanthropy_name: @asa_foundation,
      org_plus_skoller: @asa_plus_skoller,
      header_img_url:
        "https://classnav-email-images.s3.amazonaws.com/second_class/asa_second_class.png"
    ]

    ConversionEmail.send_email(user.email, subject, :org_second_class, user.id, params)
  end

  def send_join_second_class_email(_, subject, user) do
    ConversionEmail.send_email(user.email, subject, :second_class, user.id)
  end

  # Email sent logger
  def log_email_sent(status_id, user_id) do
    Repo.insert(%EmailLog{user_id: user_id, email_type_id: status_id})
  end
end
