defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.EmailJobs
  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.MarketingEmail
  alias Skoller.Services.ConversionEmail

  @no_classes_id 100
  @needs_setup_id 200

  @doc """
  Queues the no classes email to the list of `user_classes`
  """
  def queue_no_classes_emails(user_classes) do
    user_classes
    |> Enum.filter(
      &EmailPreferences.check_email_subscription_status(List.first(&1.users), @no_classes_id)
    )
    |> Enum.map(&queue_no_classes_email(List.first(&1.users)))
  end

  @doc """
  Queue the class needs setup email to the list of `user_classes`
  """
  def queue_needs_setup_emails(user_classes) do
    user_classes
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(&1.user, @needs_setup_id))
    |> Enum.map(&queue_needs_setup_email(&1))
  end

  @doc """
  Queues a no classes email for a user
  """
  def queue_no_classes_email(user) do
    EmailJobs.create_email_job(user.id, @no_classes_id)
  end

  @doc """
  Queues needs setup email for a user
  """
  def queue_needs_setup_email(user_class) do
    EmailJobs.create_email_job(user_class.user.id, @needs_setup_id, user_class.class_name)
  end

  def send_no_classes_email(user) do
    user_id = user.id |> to_string
    subject = "Sign up for your classes so you can party harder!  🍻"
    MarketingEmail.send_email(user_id, user.email, subject, :no_classes, @no_classes_id)
  end

  def send_needs_setup_email(user, class_name) do
    user_id = user.id |> to_string
    subject = "Set up your classes and get life on track"
    ConversionEmail.send_email(user.email, subject, :needs_setup, user_id, class_name: class_name)
  end
end
