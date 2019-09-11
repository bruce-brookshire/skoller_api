defmodule Skoller.ClassStatuses.Emails do
  @moduledoc """
  A context module for class status emails.
  """

  alias Skoller.StudentClasses.Users
  alias Skoller.Services.SesMailer

  @doc """
  Sends an email to students when a class status is changed needs syllabus.
  """
  def send_need_syllabus_email(class) do
    Users.get_users_in_class(class.id)
    |> Enum.each(&build_need_syllabus_email(&1, class))
  end

  defp build_need_syllabus_email(user, class) do
    SesMailer.send_individual_email(
      %{
        email: user.email,
        form: %{
          class_name: class.name,
          web_home_path: System.get_env("WEB_URL") <> "/unsubscribe/" <> user.id
        }
      },
      "wrong_syllabus"
    )
  end
end
