defmodule Mix.Tasks.Seed.Dev do

  @moduledoc """

  Utility for developers to seed the db with data for manipulating and testing.

  """

  use Mix.Task
  import Mix.Ecto

  alias Classnavapi.Repo
  alias Classnavapi.User
  alias Classnavapi.Class.Doc
  alias Classnavapi.UserRole
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
 
    {:ok, date1, _offset1} = DateTime.from_iso8601("2017-10-12T00:00:00Z")
    {:ok, date2, _offset2} = DateTime.from_iso8601("2018-10-12T00:00:00Z")
    pass = Comeonin.Bcrypt.add_hash("password")
    {:ok, time1} = Time.new(13, 0, 0, 0)

    user = Repo.insert!(%User{email: "dev@skoller.co", 
                              password_hash: pass.password_hash})
    sw1 = Repo.insert!(%User{email: "sw1@skoller.co", 
                              password_hash: pass.password_hash})
    sw2 = Repo.insert!(%User{email: "sw2@skoller.co", 
                              password_hash: pass.password_hash})
    sw3 = Repo.insert!(%User{email: "sw3@skoller.co", 
                              password_hash: pass.password_hash})
    sw4 = Repo.insert!(%User{email: "sw4@skoller.co", 
                              password_hash: pass.password_hash})
    school = Repo.insert!(%School{name: "Hard Knocks University",
                                    timezone: "CST",
                                    email_domains: [
                                      %EmailDomain{
                                        email_domain: "@fortyau.com",
                                        is_professor_only: false
                                      }
                                    ],
                                    adr_zip: "37201",
                                    adr_state: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_city: "Nashville"})

    school2 = Repo.insert!(%School{name: "Skoller University",
                                    timezone: "CST",
                                    email_domains: [
                                      %EmailDomain{
                                        email_domain: "@skoller.co",
                                        is_professor_only: false
                                      }
                                    ],
                                    adr_zip: "37201",
                                    adr_state: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_city: "Nashville"})
    
    school3 = Repo.insert!(%School{name: "Classo University",
                                    timezone: "CST",
                                    email_domains: [
                                      %EmailDomain{
                                        email_domain: "@test.com",
                                        is_professor_only: false
                                      }
                                    ],
                                    adr_zip: "37201",
                                    adr_state: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_city: "Nashville"})
    {:ok, bday} = Date.new(2017, 10, 12)
    student = Repo.insert!(%User{email: "tyler@fortyau.com", 
                                password_hash: pass.password_hash,
                                student: %Student{name_first: "Tyler",
                                   name_last: "Witt",
                                   school_id: school.id,
                                   phone: "2067189446",
                                   birthday: bday,
                                   gender: "Male",
                                   is_verified: true,
                                   notification_time: time1}})

    Repo.insert!(%UserRole{user_id: user.id, role_id: 200})
    Repo.insert!(%UserRole{user_id: sw1.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: sw2.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: sw3.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: sw4.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: student.id, role_id: 100})
                            
    period = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school.id,
      start_date: date1,
      end_date: date2
    })

    period2 = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school2.id,
      start_date: date1,
      end_date: date2
    })

    period3 = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school3.id,
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

    c1 = Repo.insert!(%Class{name: "Big Money 2",
        number: "8001-01",
        meet_days: "MWF",
        meet_start_time: "8:30",
        meet_end_time: "12",
        seat_count: 2,
        class_start: date1,
        class_end: date2,
        is_enrollable: true,
        is_editable: true,
        is_syllabus: false,
        grade_scale: "A,90|B,80|C,70|D,60",
        class_period_id: period.id,
        class_status_id: 300,
        is_ghost: false
    })

    c2 = Repo.insert!(%Class{name: "Skoller 101",
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
      class_period_id: period2.id,
      class_status_id: 300,
      is_ghost: false
    })

  c3 = Repo.insert!(%Class{name: "Skoller 201",
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
    class_period_id: period2.id,
    class_status_id: 300,
    is_ghost: false
  })

  c4 = Repo.insert!(%Class{name: "Skoller 301",
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
    class_period_id: period2.id,
    class_status_id: 400,
    is_ghost: false
  })

  c5 = Repo.insert!(%Class{name: "Classo 101",
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
    class_period_id: period3.id,
    class_status_id: 400,
    is_ghost: false
  })

  c6 = Repo.insert!(%Class{name: "Classo 201",
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
    class_period_id: period3.id,
    class_status_id: 300,
    is_ghost: false
  })

  c7 = Repo.insert!(%Class{name: "Classo 301",
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
    class_period_id: period3.id,
    class_status_id: 400,
    is_ghost: false
  })

  Repo.insert!(%Doc{
    class_id: c1.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
  })

  Repo.insert!(%Doc{
    class_id: c2.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
  })

  Repo.insert!(%Doc{
    class_id: c3.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
  })

  Repo.insert!(%Doc{
    class_id: c4.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
  })

  Repo.insert!(%Doc{
    class_id: c5.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
  })

  Repo.insert!(%Doc{
    class_id: c6.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
  })

  Repo.insert!(%Doc{
    class_id: c7.id,
    is_syllabus: true,
    name: "Test",
    path: "Name"
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
