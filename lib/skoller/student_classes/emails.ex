defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.EmailJobs
  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.ConversionEmail

  @no_classes_id 100
  @needs_setup_id 200
  @grow_community_id 500
  @join_second_class_id 600

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

  def send_no_classes_email(user) do
    user_id = user.id |> to_string
    subject = "Don't waste time on that paper planner..."

    @no_classes_id |> log_email_sent(user_id)

    ConversionEmail.send_email(user.email, subject, :need_classes, user_id)
  end

  def send_needs_setup_email(user, class_name) do
    user_id = user.id |> to_string
    subject = "Kickstart an easier semester!"

    @needs_setup_id |> log_email_sent(user_id)

    ConversionEmail.send_email(user.email, subject, :needs_setup, user_id, class_name: class_name)
  end

  def send_grow_community_email(user, class_name) do
    user_id = user.id |> to_string
    subject = "Whoa you're missing out..."

    @grow_community_id |> log_email_sent(user_id)

    ConversionEmail.send_email(user.email, subject, :unlock_community, user_id,
      class_name: class_name
    )
  end

  def send_join_second_class_email(user) do
    user_id = user.id |> to_string
    subject = "Not organized? We'll help."

    @join_second_class_id |> log_email_sent(user_id)

    ConversionEmail.send_email(user.email, subject, :second_class, user_id)
  end

  def log_email_sent(status_id, user_id) do
    Repo.insert(%EmailLog{user_id: user_id |> String.to_integer(), email_type_id: status_id})
  end
end
