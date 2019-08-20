defmodule Skoller.Analytics.Jobs do
    alias Skoller.AnalyticUpload
    alias Skoller.Analytics.Documents
    alias Skoller.Students.StudentAnalytics
    alias Skoller.Classes.ClassAnalytics
    alias Skoller.Schools.SchoolAnalytics
    
    require Logger

    @user_job_id 100
    @class_job_id 200
    @school_job_id 300
    
    def run_analytics(job, curtime) do
        curtime 
            |> check_sending_time(job)
            |> generate_csv()
    end

    defp generate_csv(nil), do: nil
    defp generate_csv(job_id) do
        #Get context for job. If it's nil, theres no action implemented for the job
        case get_context(job_id) do
            {filename, dir} -> 
                file_path = "./" <> filename
                scope = %{:id => filename, :dir => dir}

                Logger.info("Calculating analytics " <> filename)

                job_id 
                    |> get_analytics
                    |> CSV.encode
                    |> Enum.to_list
                    |> add_headers(job_id)
                    |> to_string
                    |> upload_document(file_path, scope)
                    |> store_document(scope)
            nil -> 
                Logger.info("Unknown analytics job")
        end
    end

    #Return the filename and directory for the job if available
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

    #All filenames need this timestamp ending
    defp get_file_base() do
        now = DateTime.utc_now
        "#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}"
    end

    #Retrieve analytics per the job_id
    defp get_analytics(@school_job_id) do
        SchoolAnalytics.get_analytics()
    end

    defp get_analytics(@class_job_id) do
        ClassAnalytics.get_analytics()
    end

    defp get_analytics(@user_job_id) do
        StudentAnalytics.get_analytics()
    end

    defp add_headers(list, @school_job_id) do
        [
            "School Creation Date," <>
            "School Name," <>
            "City," <>
            "State," <>
            "Timezone," <>
            "Email Domains," <>
            "Color," <>
            "# of Accounts\r\n"
            | list
        ]
    end
    
    defp add_headers(list, @class_job_id) do
        [
            "Created on," <> 
            "Student Created," <> 
            "Term Name," <> 
            "Term Status," <> 
            "Class Name," <> 
            "Class Status," <> 
            "Active Count," <> 
            "Inactive Count," <> 
            "School Name\r\n"
            | list
        ]
    end
    
    defp add_headers(list, @user_job_id) do
        [
            "Account Creation Date," <>
            "First Name," <>
            "Last Name," <> 
            "Email," <> 
            "Phone #," <>
            "Last Logged In," <>
            "Main School," <>
            "School City," <>
            "School State," <>
            "Graduation Year," <> 
            "Student Points," <>
            "Current Classes," <>
            "Current Classes Set Up," <>
            "Total Classes," <>
            "Total Classes Set Up," <>
            "Sign Up Referral," <>
            "Active Assignments," <>
            "Inactive Assignments," <>
            "Grades Entered," <>
            "Created Mods," <>
            "Created Assignments," <>
            "Majors\r\n"
            | list
        ]
    end

    defp upload_document(content, file_path, scope) do
        File.write(file_path, content)
        result = AnalyticUpload.store({file_path, scope})
        File.rm(file_path)
        result
    end

    defp store_document({:ok, inserted}, %{:dir => "school_csv"} = scope) do
        Logger.info("Analytics completed successfully")
        path = AnalyticUpload.url({inserted, scope})
        Documents.set_current_school_csv_path(path)
    end

    defp store_document({:ok, inserted}, %{:dir => "class_csv"} = scope) do
        Logger.info("Analytics completed successfully")
        path = AnalyticUpload.url({inserted, scope})
        Documents.set_current_class_csv_path(path)
    end

    defp store_document({:ok, inserted}, %{:dir => "user_csv"} = scope) do
        Logger.info("Analytics completed successfully")
        path = AnalyticUpload.url({inserted, scope})
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