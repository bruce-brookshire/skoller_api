defmodule Mix.Tasks.Seed.Dev do

  @moduledoc """

  Utility for developers to seed the db with data for manipulating and testing.

  """

  use Mix.Task
  import Mix.Ecto

  alias Classnavapi.Repo
  alias Classnavapi.User
  alias Classnavapi.School
  alias Classnavapi.School.EmailDomain
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Class
  alias Classnavapi.Class.Weight
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Student

  def run(_) do
    ensure_started(Repo, [])

    {:ok, date1} = Date.new(2017, 10, 12)
    {:ok, date2} = Date.new(2018, 10, 12)
    pass = Comeonin.Bcrypt.add_hash("test")

    Repo.insert!(%User{email: "tyler@fortyau.com", password_hash: pass.password_hash})
    school = Repo.insert!(%School{name: "Hard Knocks University",
                                    timezone: "CST",
                                    email_domains: [
                                      %EmailDomain{
                                        email_domain: "@hku.edu",
                                        is_professor_only: false
                                      }
                                    ],
                                    adr_zip: "37201",
                                    adr_state: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_city: "Nashville"})

    student = Repo.insert!(%User{email: "tyler@hku.edu", 
                                password_hash: pass.password_hash,
                                student: %Student{name_first: "Tyler",
                                   name_last: "Witt",
                                   school_id: school.id,
                                   major: "Computer Science",
                                   phone: "6158675309",
                                   birthday: date1,
                                   gender: "Male"}})
                            
    period = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school.id,
      start_date: date1,
      end_date: date2
    })

    class = Repo.insert!(%Class{name: "Big Money",
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
                  grade_scale: "A,90|B,80|C,70|D,60",
                  class_period_id: period.id,
                  class_status_id: 100
    })

    assign_weight = Repo.insert!(%Weight{
      name: "Assignments",
      weight: 50,
      class_id: class.id
    })

    test_weight = Repo.insert!(%Weight{
      name: "Tests",
      weight: 50,
      class_id: class.id
    })

    Repo.insert!(%Assignment{
      name: "Assignment 1",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    Repo.insert!(%Assignment{
      name: "Assignment 2",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    Repo.insert!(%Assignment{
      name: "Assignment 3",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    Repo.insert!(%Assignment{
      name: "Final",
      due: date2,
      weight_id: test_weight.id,
      class_id: class.id
    })

    Repo.insert!(%StudentClass{
      student_id: student.student.id,
      class_id: class.id
    })
  end
end
