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
      preload: [enrolled_students: [user: :customer_info]],
      where: not is_nil(referred_user),
      select: %{
        referring_student: referring_student,
        referring_user: referring_user,
        venmo_handle: referring_student.venmo_handle,
        trial: fragment("SUM(CASE WHEN ? AND ? BETWEEN ? AND ? THEN 1 ELSE 0 END)", referred_user.trial, ^DateTime.utc_now, referred_user.trial_start, referred_user.trial_end),
        premium: fragment("SUM(CASE WHEN ? = ANY(?) AND ? = false THEN 1 ELSE 0 END)", payment.customer_id, ^active_users, referred_user.trial),
        expired: fragment("SUM(CASE WHEN ? = false AND ? = ANY(?) THEN 1 ELSE 0 END)", referred_user.trial, payment.customer_id, ^inactive_users)
      },
      group_by: [referring_student.id, referring_user.id]
    )
    |> Skoller.Repo.all
    |> gather_collections_and_commissions(subscriptions)
    |> parse_to_list()
    |> CSV.encode()
    |> Enum.to_list()
    |> add_headers()
    |> to_string()
    |> IO.inspect
    # |> upload_document(file_path, scope)
    # |> store_document(scope)
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

  defp active_users_plans(subscriptions) do
    subscriptions
    |> Enum.reject(& &1.status != "active")
  end

  defp gather_collections_and_commissions(query_results, subscriptions) do
    query_results =
    Enum.reduce(query_results, [], fn result, acc ->

      [
        result
        |> Map.put(:collections, get_collections(result.referring_student, subscriptions))
       # |> Map.put(:commissions, get_commissions(result.referring_student, subscriptions))

        | acc
      ]
    end)
    |> IO.inspect
  end

  defp get_collections(referring_student, subscriptions) do
    Map.get(referring_student, :enrolled_students, nil)
    |> then(fn enrolled_students ->
      if !is_nil(enrolled_students) do
        Enum.reduce(enrolled_students, [], fn enrolled_student, acc ->
          collection =
          if !is_nil(enrolled_student.user.customer_info) do
            subscription = Enum.find(subscriptions, nil, & &1.customer == enrolled_student.user.customer_info.customer_id)
            commission = calculate_commission(subscription)
            |> IO.inspect
          else
            0
          end


        end)
      end
    end)
  end

  defp calculate_commission(%{plan: %{amount: amount}}) when amount > 0, do: amount / 100
  defp calculate_commission(%{plan: %{amount: 0}}), do: 0
  defp calculate_commission(nil), do: 0

  defp parse_to_list(data) do
    Enum.reduce(data, [],  fn data, acc ->
      [
        [
          data.referring_student.name_first,
          data.referring_student.name_last,
          data.referring_user.email,
          data.referring_student.phone,
          data.trial,
          data.expired,
          data.premium,
          data.collections,
          data.commissions,
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
    File.write(file_path, content)
    result = AnalyticsDocs.store({file_path, scope})
    File.rm(file_path)
    result
  end

  defp store_document({:ok, inserted}, %{:dir => "student_referrals_csv"} = scope) do
    Logger.info("Student Referrals Report stored successfully")
    path = AnalyticsDocs.url({inserted, scope})
    Documents.set_current_student_referrals_csv_path(path, %{status: "success"})
  end

  defp store_document({:error, error}, %{:dir => "student_referrals_csv"} = scope) do
    Logger.info("Failed to store Student Referrals Report")
    Documents.set_current_student_referrals_csv_path(nil, %{status: Atom.to_string(error)})
  end
end
