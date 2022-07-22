defmodule Skoller.Students.StudentReferralsReport do
  import Ecto.Query

  alias Skoller.FileUploaders.AnalyticsDocs
  alias Skoller.Analytics.Documents

  require Logger

  def compile_referred_students_report() do
    subscriptions = subscriptions()
    inactive_users = inactive_users(subscriptions)
    active_users = active_users(subscriptions)

    filename = "StudentReferalsReport-" <> get_file_base()
    dir = "student_referrals_csv"

    file_path = "./" <> filename
    scope = %{:id => filename, :dir => dir}

    from(referring_student in Skoller.Students.Student,
      left_join: referring_user in Skoller.Users.User, on: referring_user.student_id == referring_student.id,
      left_join: referred_students in Skoller.Students.Student, on: referred_students.enrolled_by_student_id == referring_student.id,
      left_join: referred_user in Skoller.Users.User, on: referred_user.student_id == referred_students.id,
      left_join: payment in Skoller.Payments.Stripe, on: referred_user.id == payment.user_id,
      select: %{
        referring_first_name: referring_student.name_first,
        referring_last_name: referring_student.name_last,
        referring_phone: referring_student.phone,
        referring_email: referring_user.email,
        venmo_handle: referring_student.venmo_handle,
        trial: fragment("SUM(CASE WHEN ? AND ? = ANY(?) THEN 0 WHEN ? THEN 1 ELSE 0 END)", referred_user.trial, payment.customer_id, ^active_users, referred_user.trial),
        premium: fragment("SUM(CASE WHEN ? = ANY(?) THEN 1 ELSE 0 END)", payment.customer_id, ^active_users),
        expired: fragment("SUM(CASE WHEN ? THEN 0 WHEN ? = ANY(?) THEN 1 ELSE 0 END)", referred_user.trial, payment.customer_id, ^inactive_users)
      },
      group_by: [referring_student.id, referring_user.id]
    )
    |> Skoller.Repo.all
    |> parse_to_list()
    |> CSV.encode()
    |> Enum.to_list()
    |> add_headers()
    |> to_string()
    |> upload_document(file_path, scope)
    |> IO.inspect(label: "POST UPLOAD DOCUMENT")
    |> store_document(scope)
  end

  defp subscriptions do
    {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{status: "all"})
    subscriptions
  end

  defp inactive_users(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.status == "active"))
    |> Enum.map(&(&1.customer))
  end

  defp active_users(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.status != "active"))
    |> Enum.map(&(&1.customer))
  end

  defp parse_to_list(data) do
    Enum.reduce(data, [],  fn data, acc ->
      [
        [
          data.referring_first_name,
          data.referring_last_name,
          data.referring_email,
          data.referring_phone,
          data.trial,
          data.expired,
          data.premium,
          0, # collections
          0, # commission
          data.venmo_handle
        ]
        | acc
      ]
    end)
  end

  defp add_headers(list) do
    [
      "First Name," <>
      "Last Name," <>
      "Email," <>
      "Phone," <>
      "Referrals (trial)," <>
      "Referrals (expired)," <>
      "Referrals (premium)," <>
      "Collections," <>
      "Commission," <>
      "Venmo Handle\r\n"
      | list
    ]
  end

  # All filenames need this timestamp ending
  defp get_file_base() do
    now = DateTime.utc_now()
    "#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}"
  end

  defp upload_document(content, file_path, scope) do
    IO.inspect(file_path, label: "FILE PATH")
    File.write(file_path, content)
    result = AnalyticsDocs.store({file_path, scope})
    |> IO.inspect(label: "RESULT")
    #File.rm(file_path)
    result
  end

  defp store_document({:ok, inserted}, %{:dir => "student_referrals_csv"} = scope) do
    Logger.info("Student Referrals Report stored successfully")
    path = AnalyticsDocs.url({inserted, scope})
    Documents.set_current_student_referrals_csv_path(path)
  end

  defp store_document({:error, :invalid_file_path}, %{:dir => "student_referrals_csv"} = scope) do
    IO.inspect(scope, label: "SCOPE")
  end
end
