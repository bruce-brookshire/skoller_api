defmodule Skoller.Analytics.Jobs do
  alias Skoller.FileUploaders.AnalyticsDocs
  alias Skoller.Analytics.Documents
  alias Skoller.Students.StudentAnalytics
  alias Skoller.Classes.ClassAnalytics
  alias Skoller.Schools.SchoolAnalytics

  require Logger

  @user_job_id 100
  @class_job_id 200
  @school_job_id 300
  @student_job_id 400

  def run_analytics(job, curtime) do
    curtime
    |> check_sending_time(job)
    |> generate_csv()
  end

  def generate_csv(nil), do: nil

  def generate_csv(job_id) do
    # Get context for job. If it's nil, theres no action implemented for the job
    case get_context(job_id) do
      {filename, dir} ->
        file_path = "./" <> filename
        scope = %{:id => filename, :dir => dir}

        Logger.info("Calculating analytics " <> filename)

        job_id
        |> get_analytics
        |> CSV.encode()
        |> Enum.to_list()
        |> add_headers(job_id)
        |> to_string
        |> upload_document(file_path, scope)
        |> store_document(scope)

      nil ->
        Logger.info("Unknown analytics job")
    end
  end

  # Return the filename and directory for the job if available
  defp get_context(@student_job_id) do
    filename = "StudentsReferrals-" <> get_file_base()
    {filename, }
  end

  defp get_context(@school_job_id) do
    filename = "Schools-" <> get_file_base()
    {filename, "school_csv"}
  end

  defp get_context(@class_job_id) do
    filename = "Classes-" <> get_file_base()
    {filename, "class_csv"}
  end

  defp get_context(@user_job_id) do
    filename = "Users-" <> get_file_base()
    {filename, "user_csv"}
  end

  defp get_context(_id), do: nil

  # All filenames need this timestamp ending
  defp get_file_base() do
    now = DateTime.utc_now()
    "#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}"
  end

  # Retrieve analytics per the job_id
  def get_analytics(@school_job_id), do: SchoolAnalytics.get_analytics()
  def get_analytics(@class_job_id), do: ClassAnalytics.get_analytics()
  def get_analytics(@user_job_id), do: StudentAnalytics.get_analytics()

  defp add_headers(list, @school_job_id) do
    [
      "School Creation Date," <>
        "School Name," <>
        "School City," <>
        "School State," <>
        "Timezone," <>
        "Email Domain," <>
        "Color," <>
        "Accounts in Active Term," <>
        "Accounts in Inactive Term," <>
        "Sign ups with Custom Links," <> "Sign ups with Enroll Links," <> "Total Accounts\r\n"
      | list
    ]
  end

  defp add_headers(list, @class_job_id) do
    [
      "Class Creation Date," <>
        "Class Name," <>
        "Class Status," <>
        "School," <>
        "Term Name," <>
        "Term Status," <>
        "Active Count," <>
        "Inactive Count," <>
        "Sign ups with enroll link," <>
        "Assignments," <>
        "Mods Created," <> "Mod Responses," <> "Grades Added (total)," <> "Class ID\r\n"
      | list
    ]
  end

  defp add_headers(list, @user_job_id) do
    [
      "Account Creation Date," <>
        "Signup Route," <>
        "Successful Invites," <>
        "First Name," <>
        "Last Name," <>
        "Email," <>
        "Phone," <>
        "Primary School," <>
        "School City," <>
        "School State," <>
        "Graduation Year," <>
        "Majors," <>
        "Student ID," <>
        "Last Session," <>
        "Enrolled Classes (active)," <>
        "Setup Classes (active)," <>
        "Assignments (active)," <>
        "Grades Entered (active)," <>
        "Mods Created (active)," <>
        "Mods Responded (active)," <>
        "Enrolled Classes (inactive)," <>
        "Setup Classes (inactive)," <>
        "Assignments (inactive)," <>
        "Grades Entered (inactive) ," <>
        "Mods Created (inactive)," <> "Mods Responded (inactive)\r\n"
      | list
    ]
  end

  defp upload_document(content, file_path, scope) do
    File.write(file_path, content)
    result = AnalyticsDocs.store({file_path, scope})
    File.rm(file_path)
    result
  end

  defp store_document({:ok, inserted}, %{:dir => "school_csv"} = scope) do
    Logger.info("Analytics completed successfully")
    path = AnalyticsDocs.url({inserted, scope})
    Documents.set_current_school_csv_path(path)
  end

  defp store_document({:ok, inserted}, %{:dir => "class_csv"} = scope) do
    Logger.info("Analytics completed successfully")
    path = AnalyticsDocs.url({inserted, scope})
    Documents.set_current_class_csv_path(path)
  end

  defp store_document({:ok, inserted}, %{:dir => "user_csv"} = scope) do
    Logger.info("Analytics completed successfully")
    path = AnalyticsDocs.url({inserted, scope})
    Documents.set_current_user_csv_path(path)
  end

  defp store_document(_status, _scope) do
    Logger.error("Failed to upload user analytics")
  end

  defp check_sending_time(curtime, job) do
    converted_datetime = curtime |> Timex.Timezone.convert("America/Chicago")
    {:ok, time} = Time.new(converted_datetime.hour, converted_datetime.minute, 0, 0)

    job_time = job.time |> Time.from_iso8601!()

    if(Time.compare(time, job_time) == :eq, do: job.id, else: nil)
  end
end
