defmodule Skoller.StudentClasses.Jobs do
  @moduledoc """
  
  Defines email sending criteria for scheduled jobs.
  
  """

  use Timex

  alias Skoller.UnenrolledStudents
  alias Skoller.StudentClasses.Notifications
  alias Skoller.StudentClasses.Emails
  alias Skoller.EmailTypes

  require Logger

  @no_classes_id 100

  def send_no_classes_messages(datetime) do
    converted_datetime = datetime |> Timex.Timezone.convert("America/Chicago")
    {:ok, time} = Time.new(converted_datetime.hour, converted_datetime.minute, 0, 0)

    email_type = EmailTypes.get!(@no_classes_id)

    email_time = email_type.send_time |> Time.from_iso8601!()

    case Time.compare(time, email_time) do
      :eq ->
        Logger.info("Sending no classes emails and notifications.")
        students = UnenrolledStudents.get_unenrolled_students()
        if email_type.is_active_email do
          students |> Emails.send_no_classes_emails()
        end
        if email_type.is_active_notification do
          students |> Notifications.send_no_classes_notification()
        end
      _ -> nil
    end
  end
end