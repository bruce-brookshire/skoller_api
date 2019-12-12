defmodule Skoller.AirtableSyncJob do
  use GenServer

  alias Skoller.Repo
  alias Skoller.SkollerJobs.AirtableJobs
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.SkollerJobs.AirtableJobs.AirtableJob

  import SkollerWeb.HttpRequest

  # Number of times a second to check
  @max_rate_per_sec 1

  # Airtable single request object limit
  @max_body_objects 10

  # Operation types
  @create_type_id 100
  @update_type_id 200
  @delete_type_id 300

  # Airtable reference information
  @airtable_base_id System.get_env("AIRTABLE_BASE_ID")
  @airtable_api_token System.get_env("AIRTABLE_API_TOKEN")

  # This puts :jobs on the state for future calls.
  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  # This is the first call after start_link/1
  def init(state) do
    # Schedule work to be performed at some point
    schedule_work(0)
    {:ok, state}
  end

  # This is triggered whenever an event with :work is created.
  # It immediately reschedules itself, and then runs module.run.
  def handle_info({:work, job_type_id}, state) do
    # Do the work you desire here
    # Reschedule once more
    schedule_work(job_type_id)
    require Logger

    Logger.info("Running Airtable Syncing Job: #{job_type_id} @ " <> to_string(Time.utc_now()))

    jobs = AirtableJobs.get_outstanding_jobs(job_type_id, @max_body_objects)

    Enum.each(jobs, &AirtableJobs.start_job!/1)

    perform_operation(jobs, job_type_id)

    Enum.each(jobs, &AirtableJobs.complete_job!/1)

    {:noreply, state}
  end

  # This creates a :work event to be processed after get_time_diff_minute/1 milliseconds.
  defp schedule_work(curr_job_type_id) do
    next_job_type_id = rem(curr_job_type_id, 300) + 100

    Process.send_after(
      self(),
      {:work, next_job_type_id},
      20000
    )
  end

  # Performs a job based on the job id passed
  defp perform_operation([], _), do: []

  defp perform_operation(jobs, @create_type_id) do
    body = Enum.map(jobs, &convert_to_airtable_schema/1)

    post()
    |> build_base()
    |> add_body(%{"records" => body, "typecast" => true})
    |> send_request()
    |> handle_new_profile_ids(jobs)
  end

  defp perform_operation(jobs, @update_type_id) do
    body = Enum.map(jobs, &convert_to_airtable_schema/1)

    put()
    |> build_base()
    |> add_body(%{"records" => body, "typecast" => true})
    |> send_request()
    |> IO.inspect()
  end

  defp perform_operation(jobs, @delete_type_id) do
    params = Enum.map(jobs, &{"records[]", &1.airtable_object_id})

    delete()
    |> build_base()
    |> add_params(params)
    |> send_request()
  end

  defp convert_to_airtable_schema(%AirtableJob{
         airtable_job_type_id: @create_type_id,
         job_profile: %JobProfile{} = profile
       }),
       do: %{
         "fields" => generate_fields(profile)
       }

  defp convert_to_airtable_schema(%AirtableJob{
         airtable_job_type_id: @update_type_id,
         job_profile: %JobProfile{airtable_object_id: airtable_id} = profile
       }),
       do: %{
         "id" => airtable_id,
         "fields" => generate_fields(profile)
       }

  defp generate_fields(
         %JobProfile{
           user:
             %{
               student:
                 %{
                   primary_school: school,
                   fields_of_study: fields_of_study,
                   name_first: name_first,
                   name_last: name_last,
                   degree_type: %{name: degree}
                 } = student
             } = user
         } = profile
       ) do
    career_interests = (profile.career_interests || "") |> String.split("|", trim: true)
    regions = (profile.regions || "") |> String.split("|", trim: true)
    majors = fields_of_study |> Enum.map(& &1.field)

    %{
      "Names" => "#{name_first} #{name_last}",
      "Graduation Year" => student.grad_year,
      "Major" => majors,
      "Home State?" => translate_state_code(profile.state_code),
      "Career interests (up to 5):" => career_interests,
      "What region of the country do you want to work in?" => regions,
      "Profile Photo" => url_body(user.pic_path),
      "Upload your Resume or CV" => url_body(profile.resume_url),
      "Gender" => profile.gender,
      "Phone Number" => student.phone,
      "Email" => profile.alt_email || user.email,
      "School" => school.name,
      "Pursuing Degree?" => degree,
      "GPA" => profile.gpa,
      "SAT Score" => profile.sat_score,
      "ACT Score" => profile.act_score,
      "Skoller Account?" => "Yes",
      "job_profile_id" => profile.id
    }
  end

  defp build_base(request),
    do:
      request
      |> add_url("https://api.airtable.com/v0/" <> @airtable_base_id <> "/Candidates")
      |> add_headers([
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer " <> @airtable_api_token}
      ])

  @state_code_translator %{
    "AL" => "Alabama",
    "AK" => "Alaska",
    "AZ" => "Arizona",
    "AR" => "Arkansas",
    "CA" => "California",
    "CO" => "Colorado",
    "CT" => "Connecticut",
    "DE" => "Delaware",
    "DC" => "District Of Columbia",
    "FL" => "Florida",
    "GA" => "Georgia",
    "HI" => "Hawaii",
    "ID" => "Idaho",
    "IL" => "Illinois",
    "IN" => "Indiana",
    "IA" => "Iowa",
    "KS" => "Kansas",
    "KY" => "Kentucky",
    "LA" => "Louisiana",
    "ME" => "Maine",
    "MD" => "Maryland",
    "MA" => "Massachusetts",
    "MI" => "Michigan",
    "MN" => "Minnesota",
    "MS" => "Mississippi",
    "MO" => "Missouri",
    "MT" => "Montana",
    "NE" => "Nebraska",
    "NV" => "Nevada",
    "NH" => "New Hampshire",
    "NJ" => "New Jersey",
    "NM" => "New Mexico",
    "NY" => "New York",
    "NC" => "North Carolina",
    "ND" => "North Dakota",
    "OH" => "Ohio",
    "OK" => "Oklahoma",
    "OR" => "Oregon",
    "PA" => "Pennsylvania",
    "RI" => "Rhode Island",
    "SC" => "South Carolina",
    "SD" => "South Dakota",
    "TN" => "Tennessee",
    "TX" => "Texas",
    "UT" => "Utah",
    "VT" => "Vermont",
    "VA" => "Virginia",
    "WA" => "Washington",
    "WV" => "West Virginia",
    "WI" => "Wisconsin",
    "WY" => "Wyoming"
  }
  defp translate_state_code(code),
    do: @state_code_translator[code]

  defp handle_new_profile_ids(response, jobs) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        mapped_jobs =
          jobs
          |> Enum.reduce(%{}, fn val, acc -> Map.put(acc, val.job_profile.id, val) end)

        body
        |> Poison.decode!()
        |> Map.get("records")
        |> Enum.map(fn profile ->
          airtable_body = profile["fields"]

          mapped_jobs[airtable_body["job_profile_id"]]
          |> Map.get(:job_profile)
          |> JobProfile.airtable_changeset(%{airtable_object_id: profile["id"]})
        end)
        |> Enum.each(&Repo.update/1)

      failed_value ->
        failed_value
    end
  end

  def url_body(nil), do: nil
  def url_body(url), do: [%{"url" => url}]
end
