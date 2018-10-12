defmodule Skoller.StudentClasses.Jobs do
  @moduledoc """
  
  Defines email sending criteria for scheduled jobs.
  
  """

  use Timex

  alias Skoller.UnenrolledStudents
  alias Skoller.StudentClasses.Notifications
  alias Skoller.StudentClasses.Emails
  alias Skoller.EmailTypes
  alias Skoller.EnrolledStudents.ClassStatuses

  require Logger

  @no_classes_id 100
  @needs_setup_id 200

  def send_no_classes_messages(datetime) do
    email_type = EmailTypes.get!(@no_classes_id)
    case check_sending_time(datetime, email_type) do
      :eq ->
        Logger.info("Sending no classes emails and notifications.")
        students = UnenrolledStudents.get_unenrolled_students()
        if email_type.is_active_email do
          students |> Emails.send_no_classes_emails()
        end
        if email_type.is_active_notification do
          students |> Notifications.send_no_classes_notification(email_type)
        end
      _ -> nil
    end
  end

  def send_needs_setup_messages(datetime) do
    email_type = EmailTypes.get!(@needs_setup_id)
    case check_sending_time(datetime, email_type) do
      :eq ->
        Logger.info("Sending needs setup emails and notifications.")
        students = ClassStatuses.get_students_needs_setup_classes()
        if email_type.is_active_email do
          students |> Emails.send_needs_setup_emails()
        end
        if email_type.is_active_notification do
          students |> Notifications.send_needs_setup_notification(email_type)
        end
      _ -> nil
    end
  end

  defp check_sending_time(datetime, email_type) do
    converted_datetime = datetime |> Timex.Timezone.convert("America/Chicago")
    {:ok, time} = Time.new(converted_datetime.hour, converted_datetime.minute, 0, 0)

    email_time = email_type.send_time |> Time.from_iso8601!()

    Time.compare(time, email_time)
  end
end