defmodule Mix.Tasks.Seed.Dev do
  use Mix.Task
  import Mix.Ecto

  alias Classnavapi.Repo

  def run(_) do
    ensure_started(Repo, [])

    {:ok, date1} = Date.new(2017, 10, 12)
    {:ok, date2} = Date.new(2018, 10, 12)

    Repo.insert!(%Classnavapi.User{email: "tyler@fortyau.com", password: "test"})
    school = Repo.insert!(%Classnavapi.School{name: "Hard Knocks University",
                                    timezone: "CST",
                                    email_domains: [
                                      %Classnavapi.School.EmailDomain{
                                        email_domain: "@hku.edu",
                                        is_professor_only: false
                                      }
                                    ],
                                    adr_zip: "37201",
                                    adr_state: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_city: "Nashville",
                                    is_active: true,
                                    is_editable: true})

    period = Repo.insert!(%Classnavapi.ClassPeriod{
      name: "Q1",
      school_id: school.id,
      start_date: date1,
      end_date: date2
    })
    
    class = Repo.insert!(%Classnavapi.Class{name: "Big Money",
                  number: "8001-01",
                  meet_days: "MWF",
                  meet_start_time: "8:30",
                  meet_end_time: "12",
                  seat_count: 200,
                  class_start: date1,
                  class_end: date2,
                  is_enrollable: true,
                  is_editable: true,
                  is_syllabus: false,
                  class_period_id: period.id,
                  class_status_id: 100
    })

    Repo.insert!(%Classnavapi.Class.Weight{
      name: "Assignments",
      weight: 50,
      class_id: class.id
    })

    Repo.insert!(%Classnavapi.Class.Weight{
      name: "Tests",
      weight: 50,
      class_id: class.id
    })

  end
end