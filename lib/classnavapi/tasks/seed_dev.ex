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
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Student
  alias Classnavapi.School.FieldOfStudy

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
                  class_status_id: 700,
                  is_ghost: false
    })

    assign_weight = Repo.insert!(%Weight{
      name: "Assignments",
      weight: 15,
      class_id: class.id
    })

    test_weight = Repo.insert!(%Weight{
      name: "Tests",
      weight: 50,
      class_id: class.id
    })

    Repo.insert!(%Weight{
      name: "Labs",
      weight: 35,
      class_id: class.id
    })

    a1 = Repo.insert!(%Assignment{
      name: "Assignment 1",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    a2 = Repo.insert!(%Assignment{
      name: "Assignment 2",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    a3 = Repo.insert!(%Assignment{
      name: "Assignment 3",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    t1 = Repo.insert!(%Assignment{
      name: "Final",
      due: date2,
      weight_id: test_weight.id,
      class_id: class.id
    })

    sc = Repo.insert!(%StudentClass{
      student_id: student.student.id,
      class_id: class.id
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: a1.id,
      name: a1.name,
      due: a1.due,
      weight_id: a1.weight_id,
      grade: 80
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: a2.id,
      name: a2.name,
      due: a2.due,
      weight_id: a2.weight_id,
      grade: 80
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 80
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: 100
    })

    Repo.insert!(%FieldOfStudy{
      field: "Computer Science",
      school_id: school.id
    })
  end
end
