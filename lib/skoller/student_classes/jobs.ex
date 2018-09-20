defmodule Skoller.StudentClasses.Jobs do
  @moduledoc """
  
  Defines email sending criteria for scheduled jobs.
  
  """

  use Timex

  alias Skoller.UnenrolledStudents
  alias Skoller.StudentClasses.Notifications
  alias Skoller.StudentClasses.Emails

  require Logger

  def send_no_classes_messages(datetime) do
    converted_datetime = datetime |> Timex.Timezone.convert("America/Chicago")
    {:ok, time} = Time.new(converted_datetime.hour, converted_datetime.minute, 0, 0)

    email_time = System.get_env("NO_CLASSES_EMAIL_TIME") |> Time.from_iso8601!()

    case Time.compare(time, email_time) do
      :eq ->
        Logger.info("Sending no classes emails and notifications.")
        students = UnenrolledStudents.get_unenrolled_students()
        students |> Emails.send_no_classes_emails()
        students |> Notifications.send_no_classes_notification()
      _ -> nil
    end
  end
end