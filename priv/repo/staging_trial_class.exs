# ---------------------------
## This script generates a school with random data and X number of classes, uploading a syllabii randomly from path Y.
## Args: [number_of_classes, path_to_syllabii]
# ---------------------------

import Ecto.Query

days_selection = ["M","T","W","Th","F"]

classes_num = String.to_integer(Enum.at(System.argv, 0))
folder_path = Enum.at(System.argv, 1)

country = "Fantasy World"
region = Faker.StarWars.En.planet()
locality = Faker.Pokemon.En.location()

today = Date.utc_today
{:ok, period_start, _} = (Date.add(today, -30) |> Date.to_iso8601) <> "T00:00:00Z" |> DateTime.from_iso8601
{:ok, period_end, _} = (Date.add(today, 60) |> Date.to_iso8601) <> "T00:00:00Z" |> DateTime.from_iso8601
status = 200 # active period

user = from(u in Skoller.Users.User, where: u.email == "dev@skoller.co") |> Skoller.Repo.one()

files = Path.wildcard(folder_path <> "/*")

school = Skoller.Repo.insert!(%Skoller.Schools.School{
  name: region <> " University",
  adr_locality: locality,
  adr_region: region,
  adr_country: country,
  is_chat_enabled: false,
  is_assignment_posts_enabled: false,
  is_university: true
})

period = Skoller.Repo.insert!(%Skoller.Periods.ClassPeriod{
  name: "Test Period",
  school_id: school.id,
  start_date: period_start,
  end_date: period_end,
  class_period_status_id: status
})

(1 .. classes_num) |> Enum.each(fn _ ->

  name = Faker.Superhero.descriptor <> Faker.Pokemon.name
  section = Faker.random_between(1000, 9999) |> Integer.to_string
  code = Faker.random_between(10, 99) |> Integer.to_string
  subject = Faker.Util.upper_letter() <> Faker.Util.upper_letter <> Faker.Util.upper_letter
  meet_start_time = (Faker.random_between(6, 18) |> Integer.to_string) <> ":00:00"
  meet_days = Enum.random(days_selection) <> Enum.random(days_selection) <> Enum.random(days_selection)
  status = 1200 # Syllabus submitted

  class = Skoller.Repo.insert!(%Skoller.Classes.Class{
    name: name,
    is_editable: true,
    is_ghost: false, 
    class_period_id: period.id,
    is_chat_enabled: false,
    is_assignment_posts_enabled: false, 
    is_syllabus: true,
    is_points: false,
    section: section,
    code: code,
    subject: subject,
    meet_start_time: meet_start_time,
    meet_days: meet_days,
    class_status_id: status
  })

  file_path = Enum.random(files)
  file = %Plug.Upload{content_type: "application/pdf", filename: "syllabi.pdf", path: file_path}
  Skoller.ClassDocs.upload_doc(file, user.id, class.id, true)
end)
