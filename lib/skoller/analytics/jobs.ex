defmodule Skoller.Analytics.Jobs do
    alias Skoller.AnalyticUpload
    alias Skoller.Analytics.Documents
    alias Skoller.Analytics.Documents.DocumentType
    alias Skoller.Students.StudentAnalytics
    alias Skoller.Repo

    @user_job_id 100
    @class_job_id 200
    @school_job_id 300
    
    def run_user_analytics(curtime) do
        job = Repo.get(DocumentType, @user_job_id)

        case check_sending_time(curtime, job) do
            :eq -> generate_user_csv()
            _ -> nil
        end
    end

    def generate_user_csv() do
        require Logger

        filename = get_filename()
        file_path = "./" <> filename

        Logger.info("Calculating user analytics " <> filename)

        content = csv_users()

        Logger.info("Writing user analytics to S3")

        File.write(file_path, content)

        scope = %{:id => filename, :dir => "user_csv"}
        {success, inserted} = AnalyticUpload.store({file_path, scope})

        File.rm(file_path)

        case success do
            :ok ->
                Logger.info("Analytics completed successfully")
                path = AnalyticUpload.url({inserted, scope})
                Documents.set_current_user_csv_path(path)
            :error ->
                Logger.error("Failed to upload user analytics")
        end
    end

    defp get_filename() do
        now = DateTime.utc_now
        "Users-#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}"
    end


    defp csv_users() do
        StudentAnalytics.get_student_analytics()
            |> CSV.encode
            |> Enum.to_list
            |> add_headers
            |> to_string
    end

    defp add_headers(list) do
        [
            "Account Creation Date," <>
            "First Name," <>
            "Last Name," <> 
            "Email," <> 
            "Phone #," <>
            "Phone # Verified?," <>
            "Main School," <>
            "Graduation Year," <> 
            "Current Classes," <>
            "Current Classes Set Up," <>
            "Total Classes," <>
            "Total Classes Set Up," <>
            "Referral Organization," <>
            "Active Assignments," <>
            "Inactive Assignments," <>
            "Grades Entered," <>
            "Created Mods," <>
            "Created Assignments\r\n"
            | list
        ]
    end


    defp check_sending_time(curtime, job) do
        converted_datetime = curtime |> Timex.Timezone.convert("America/Chicago")
        {:ok, time} = Time.new(converted_datetime.hour, converted_datetime.minute, 0, 0)

        job_time = job.time |> Time.from_iso8601!()
    
        Time.compare(time, job_time)
    end
end