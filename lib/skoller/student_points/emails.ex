defmodule Skoller.StudentPoints.Emails do
  @moduledoc """
  Defines emails based on student points
  """

  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.Mailer.SesMailer
  alias Skoller.EmailLogs
  alias Skoller.Users.Students
  alias Skoller.EmailTypes
  alias Skoller.StudentPoints.Notifications

  @one_thousand_points_id 300

  @doc """
  Sends an email to a user that hits 1000 points. Only sends if there are no previous emails of that type to that user.
  """
  def send_one_thousand_points_email(student_id) do
    EmailTypes.get!(@one_thousand_points_id)
    |> check_email_type()
    |> check_email_count(student_id)
    |> send_email()
    |> send_notification()
  end

  defp send_notification(
         {:ok, %{user: user, email_type: %{is_active_notification: true} = email_type}}
       ) do
    Notifications.send_one_thousand_points_notification(user, email_type)
  end

  defp send_notification(params), do: params

  defp check_email_count({:ok, map}, student_id) do
    user = Students.get_user_by_student_id(student_id)

    email_count =
      EmailLogs.get_sent_emails_by_user_and_type(user.id, @one_thousand_points_id) |> Enum.count()

    case email_count == 0 do
      true ->
        map = map |> Map.put(:user, user)
        {:ok, map}

      false ->
        {:error, :email_count}
    end
  end

  defp check_email_count(params, _student_id), do: params

  defp check_email_type(%{is_active_email: true} = email_type),
    do: {:ok, %{email_type: email_type}}

  defp check_email_type(_email_type), do: {:error, :email_type_disabled}

  defp send_email({:ok, %{user: user} = map}) do
    if EmailPreferences.check_email_subscription_status(user, @one_thousand_points_id) do
      send_no_classes_email(user)
    end

    {:ok, map}
  end

  defp send_email(params), do: params

  defp send_no_classes_email(user) do
    user_id = user.id |> to_string
    subject = "Sign up for your classes so you can party harder!  🍻"

    SesMailer.send_individual_email(%{to: user.email, form: %{}}, "one_thousand_points")
  end
end
