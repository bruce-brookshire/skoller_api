defmodule Skoller.ClassStatuses.Emails do
  @moduledoc """
  A context module for class status emails.
  """

  alias Skoller.StudentClasses.Users
  alias Skoller.Services.TriggeredEmail

  @syllabus_subj "Wrong Syllabus?"

  @doc """
  Sends an email to students when a class status is changed needs syllabus.
  """
  def send_need_syllabus_email(class) do
    Users.get_users_in_class(class.id)
    |> Enum.each(&build_need_syllabus_email(&1, class))
  end

  defp build_need_syllabus_email(user, class) do
    TriggeredEmail.send_email(user.email, @syllabus_subj, :needs_syllabus, [class_name: class.name])
    # web_home_path
  end
end