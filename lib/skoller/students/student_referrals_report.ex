defmodule Skoller.Students.StudentReferralsReport do
  import Ecto.Query

  alias Skoller.FileUploaders.AnalyticsDocs
  alias Skoller.Analytics.Documents

  require Logger

  def compile_referred_students_report() do
    subscriptions = Skoller.Repo.all(Skoller.Schema.Subscription)
    active_users = active_users(subscriptions)
    inactive_users = inactive_users(subscriptions)

    filename = "StudentReferalsReport-" <> get_file_base()
    dir = "student_referrals_csv"

    file_path = "./" <> filename
    scope = %{:id => filename, :dir => dir}

    from(referring_student in Skoller.Students.Student,
      left_join: referring_user in Skoller.Users.User, on: referring_user.student_id == referring_student.id,
      left_join: referred_students in Skoller.Students.Student, on: referred_students.enrolled_by_student_id == referring_student.id,
      left_join: referred_user in Skoller.Users.User, on: referred_user.student_id == referred_students.id,
      left_join: subscription in Skoller.Schema.Subscription, on: referred_user.id == subscription.user_id,
      preload: [enrolled_students: [user: :subscription]],
      where: not is_nil(referred_user),
      select: %{
        referring_student: referring_student,
        referring_user: referring_user,
        venmo_handle: referring_student.venmo_handle,
        trial: fragment("SUM(CASE WHEN ? AND ? BETWEEN ? AND ? THEN 1 ELSE 0 END)", referred_user.trial, ^DateTime.utc_now, referred_user.trial_start, referred_user.trial_end),
        premium: fragment("SUM(CASE WHEN ? = ANY(?) AND ? = false THEN 1 ELSE 0 END)", subscription.user_id, ^active_users, referred_user.trial),
        expired: fragment("SUM(CASE WHEN ? = false AND ? = ANY(?) THEN 1 ELSE 0 END)", referred_user.trial, subscription.user_id, ^inactive_users)
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
    |> upload_document(file_path, scope)
    |> store_document(scope)
  end

  defp inactive_users(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.current_status == :active))
    |> Enum.map(&(&1.user_id))
  end

  defp active_users(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.current_status != :active))
    |> Enum.map(&(&1.user_id))
  end

  defp gather_collections_and_commissions(query_results, subscriptions) do
    Enum.reduce(query_results, [], fn result, acc ->
      [
        result
        |> Map.put(:collections, get_collections(result.referring_student, subscriptions))

        | acc
      ]
    end)
  end

  defp get_collections(referring_student, subscriptions) do
    Map.get(referring_student, :enrolled_students, nil)
    |> then(fn enrolled_students ->
      if !is_nil(enrolled_students) do
        collection =
        Enum.reduce(enrolled_students, 0, fn enrolled_student, acc ->
          if !is_nil(enrolled_student.user.subscription) do
            subscription = Enum.find(subscriptions, nil, & &1.user_id == enrolled_student.user.subscription.user_id)
            calculate_collection(subscription)
          else
            0.0
          end + acc
        end)

        commission =
          Enum.reduce(enrolled_students, 0, fn enrolled_student, acc ->
            if !is_nil(enrolled_student.user.subscription) do

              subscription = Enum.find(subscriptions, nil, & &1.user_id == enrolled_student.user.subscription.user_id)
              calculate_commission(subscription)
            else
              0.0
            end + acc
          end)

          %{
            collection: collection |> :erlang.float_to_binary([decimals: 2]),
            commission: commission |> :erlang.float_to_binary([decimals: 2])
          }
      end
    end)
  end

  defp calculate_collection(%{renewal_interval: :year, platform: :ios}), do: 54.99
  defp calculate_collection(%{renewal_interval: :month, platform: :ios}), do: 5.49
  defp calculate_collection(%{renewal_interval: :year, platform: :stripe}), do: 40.00
  defp calculate_collection(%{renewal_interval: :month, platform: :stripe}), do: 4.00
  defp calculate_collection(_), do: 0

  defp calculate_commission(%{renewal_interval: :year}), do: 10.00
  defp calculate_commission(%{renewal_interval: :month}), do: 1.00
  defp calculate_commission(_), do: 0

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
          data.collections.collection,
          data.collections.commission,
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

  defp store_document({:error, error}, %{:dir => "student_referrals_csv"}) do
    Logger.info("Failed to store Student Referrals Report")
    Documents.set_current_student_referrals_csv_path(nil, %{status: Atom.to_string(error)})
  end
end
