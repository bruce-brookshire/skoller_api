defmodule Skoller.StudentClasses.Jobs do
  @moduledoc """
  
  Defines email sending criteria for scheduled jobs.
  
  """

  alias Skoller.UnenrolledStudents
  alias Skoller.StudentClasses.Notifications
  alias Skoller.StudentClasses.Emails

  def send_no_classes_messages(datetime) do
    {:ok, time} = Time.new(datetime.hour, 0, 0, 0)

    students = UnenrolledStudents.get_unenrolled_students()
    
    students |> Emails.send_no_classes_emails()
    students |> Notifications.send_no_classes_notification()
  end
end