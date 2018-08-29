defmodule Skoller.Emails do
  @moduledoc """
  
  Defines email sending criteria for scheduled jobs.
  
  """
  alias Skoller.UnenrolledStudents

  def send_no_classes_email(datetime) do
    {:ok, time} = Time.new(datetime.hour, 0, 0, 0)

    UnenrolledStudents.get_unenrolled_students()
    |> 
  end
end