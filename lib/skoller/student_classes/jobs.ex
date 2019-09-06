defmodule Skoller.StudentClasses.Jobs do
  @moduledoc """

  Defines email sending criteria for scheduled jobs.

  """

  import Ecto.Query

  use Timex

  alias Skoller.Repo
  alias Skoller.EmailTypes
  alias Skoller.StudentClasses.Emails
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentClasses.Notifications
  alias Skoller.StudentClasses.ConversionQueries

  require Logger

  @no_classes_id 100
  @needs_setup_id 200
  @grow_community_id 500
  @join_second_class_id 600

  @past_status 100

  def send_no_classes_messages(datetime) do
    email_type = EmailTypes.get!(@no_classes_id)

    case check_sending_time(datetime, email_type) do
      :eq ->
        Logger.info("Sending no classes emails and notifications.")
        students = ConversionQueries.get_unenrolled_users()
        # Send emails after notifications because emails are blocking
        if email_type.is_active_notification do
          students |> Notifications.send_no_classes_notification(email_type)
        end

        if email_type.is_active_email do
          students |> Emails.queue_no_classes_emails()
        end

      _ ->
        nil
    end
  end

  def send_needs_setup_messages() do
    email_type = EmailTypes.get!(@needs_setup_id)
    Logger.info("Sending needs setup emails and notifications.")

    user_class_info = ConversionQueries.get_users_needs_setup_classes()

    # Send emails after notifications because emails are blocking
    if email_type.is_active_notification do
      user_class_info |> Notifications.send_needs_setup_notification(email_type)
    end

    if email_type.is_active_email do
      user_class_info |> Emails.queue_needs_setup_emails()
    end
  end

  def send_grow_community_messages() do
    email_type = EmailTypes.get!(@grow_community_id)
    Logger.info("Sending grow community emails and notifications.")

    user_class_info = ConversionQueries.get_users_grow_community_classes()

    # Send emails after notifications because emails are blocking
    if email_type.is_active_notification do
      user_class_info |> Notifications.send_grow_community_notification(email_type)
    end

    if email_type.is_active_email do
      user_class_info |> Emails.queue_grow_community_emails()
    end
  end

  def send_second_class_messages() do
    email_type = EmailTypes.get!(@join_second_class_id)
    Logger.info("Sending second class emails and notifications.")

    user_class_info = ConversionQueries.get_users_join_second_class()

    # Send emails after notifications because emails are blocking
    if email_type.is_active_notification do
      user_class_info |> Notifications.send_join_second_class_notification(email_type)
    end

    if email_type.is_active_email do
      user_class_info |> Emails.queue_join_second_class_emails()
    end
  end

  defp check_sending_time(datetime, email_type) do
    converted_datetime = datetime |> Timex.Timezone.convert("America/Chicago")
    {:ok, time} = Time.new(converted_datetime.hour, converted_datetime.minute, 0, 0)

    email_time = email_type.send_time |> Time.from_iso8601!()

    Time.compare(time, email_time)
  end

  def drop_past_classes() do
    from(sc in StudentClass,
      join: c in assoc(sc, :class),
      join: p in assoc(c, :class_period),
      where: sc.is_dropped == false and p.class_period_status_id == @past_status,
      update: [set: [is_dropped: true]]
    )
    |> Repo.update_all([])
  end
end
