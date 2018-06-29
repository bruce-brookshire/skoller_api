defmodule Mix.Tasks.Seed.Dev do
  @moduledoc false

  use Mix.Task
  import Mix.Ecto

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.ClassDocs.Doc
  alias Skoller.UserRole
  alias Skoller.Schools.School
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Schools.Class
  alias Skoller.Weights.Weight
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Assignments.Assignment
  alias Skoller.Students.Student
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.Devices.Device
  alias Skoller.Professors.Professor

  def run(_) do
    ensure_started(Repo, [])
 
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
                                    adr_zip: "37201",
                                    adr_region: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_locality: "Nashville",
                                    adr_country: "us"})

    school2 = Repo.insert!(%School{name: "Skoller University",
                                    timezone: "CST",
                                    adr_zip: "37201",
                                    adr_region: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_locality: "Nashville",
                                    adr_country: "us"})
    
    school3 = Repo.insert!(%School{name: "Classo University",
                                    timezone: "CST",
                                    adr_zip: "37201",
                                    adr_region: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_locality: "Nashville",
                                    adr_country: "us"})
    {:ok, bday} = Date.new(2017, 10, 12)
    student = Repo.insert!(%User{email: "tyler@fortyau.com", 
                                password_hash: pass.password_hash,
                                student: %Student{name_first: "Tyler",
                                   name_last: "Witt",
                                   phone: "1111111111",
                                   birthday: bday,
                                   gender: "Male",
                                   is_verified: true,
                                   notification_time: time1,
                                   future_reminder_notification_time: time1,
                                   enrollment_link: "S1"}})

    student1 = Repo.insert!(%User{email: "tyler1@fortyau.com", 
                                   password_hash: pass.password_hash,
                                   student: %Student{name_first: "Tyler",
                                      name_last: "Witt",
                                      phone: "2222222222",
                                      birthday: bday,
                                      gender: "Male",
                                      is_verified: true,
                                      notification_time: time1,
                                      future_reminder_notification_time: time1,
                                      enrollment_link: "S2"}})
                                    
    student2 = Repo.insert!(%User{email: "tyler2@fortyau.com", 
                                      password_hash: pass.password_hash,
                                      student: %Student{name_first: "Tyler",
                                         name_last: "Witt",
                                         phone: "3333333333",
                                         birthday: bday,
                                         gender: "Male",
                                         is_verified: true,
                                         notification_time: time1,
                                         future_reminder_notification_time: time1,
                                         enrollment_link: "S3"}})
      
    student3 = Repo.insert!(%User{email: "tyler3@fortyau.com", 
                                         password_hash: pass.password_hash,
                                         student: %Student{name_first: "Tyler",
                                            name_last: "Witt",
                                            phone: "4444444444",
                                            birthday: bday,
                                            gender: "Male",
                                            is_verified: true,
                                            notification_time: time1,
                                            future_reminder_notification_time: time1,
                                            enrollment_link: "S3"}})

    student4 = Repo.insert!(%User{email: "tyler4@fortyau.com", 
                                password_hash: pass.password_hash,
                                student: %Student{name_first: "Tyler",
                                    name_last: "Witt",
                                    phone: "5555555555",
                                    birthday: bday,
                                    gender: "Male",
                                    is_verified: true,
                                    notification_time: time1,
                                    future_reminder_notification_time: time1,
                                    enrollment_link: "S4"}})

    student5 = Repo.insert!(%User{email: "tyler5@fortyau.com", 
                                    password_hash: pass.password_hash,
                                    student: %Student{name_first: "Tyler",
                                      name_last: "Witt",
                                      phone: "6666666666",
                                      birthday: bday,
                                      gender: "Male",
                                      is_verified: true,
                                      notification_time: time1,
                                      future_reminder_notification_time: time1,
                                      enrollment_link: "S5"}})

    Repo.insert!(%Device{type: "ios", udid: "Test", user_id: student5.id})
    Repo.insert!(%Device{type: "ios", udid: "Test1", user_id: student4.id})

    Repo.insert!(%UserRole{user_id: user.id, role_id: 200})
    Repo.insert!(%UserRole{user_id: sw1.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: sw2.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: sw3.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: sw4.id, role_id: 300})
    Repo.insert!(%UserRole{user_id: student.id, role_id: 100})
    Repo.insert!(%UserRole{user_id: student1.id, role_id: 100})
    Repo.insert!(%UserRole{user_id: student2.id, role_id: 100})
    Repo.insert!(%UserRole{user_id: student3.id, role_id: 100})
    Repo.insert!(%UserRole{user_id: student4.id, role_id: 100})
    Repo.insert!(%UserRole{user_id: student5.id, role_id: 100})
                            
    period = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school.id
    })

    period2 = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school2.id
    })

    period3 = Repo.insert!(%ClassPeriod{
      name: "Q1",
      school_id: school3.id
    })

    class = Repo.insert!(%Class{name: "Big Money",
                  subject: "BMO",
                  code: "8001",
                  section: "01",
                  meet_days: "MWF",
                  meet_start_time: "8:30:00",
                  meet_end_time: "12:00:00",
                  seat_count: 200,
                  is_editable: true,
                  is_syllabus: false,
                  grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
                  class_period_id: period.id,
                  class_status_id: 700,
                  is_ghost: false
    })

    c1 = Repo.insert!(%Class{name: "Big Money 2",
                subject: "BMO",
                code: "8001",
                section: "01",
                meet_days: "MWF",
                meet_start_time: "8:30:00",
                meet_end_time: "12:00:00",
                seat_count: 2,
                is_editable: true,
                is_syllabus: false,
                grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
                class_period_id: period.id,
                class_status_id: 300,
                is_ghost: false
    })

    c2 = Repo.insert!(%Class{name: "Skoller 101",
      subject: "BMO",
      code: "8001",
      section: "01",
      meet_days: "MWF",
      meet_start_time: "8:30:00",
      meet_end_time: "12:00:00",
      seat_count: 200,
      is_editable: true,
      is_syllabus: false,
      grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
      class_period_id: period2.id,
      class_status_id: 300,
      is_ghost: false
    })

  c3 = Repo.insert!(%Class{name: "Skoller 201",
    subject: "BMO",
    code: "8001",
    section: "01",
    meet_days: "MWF",
    meet_start_time: "8:30:00",
    meet_end_time: "12:00:00",
    seat_count: 200,
    is_editable: true,
    is_syllabus: false,
    grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
    class_period_id: period2.id,
    class_status_id: 300,
    is_ghost: false
  })

  c4 = Repo.insert!(%Class{name: "Skoller 301",
    subject: "BMO",
    code: "8001",
    section: "01",
    meet_days: "MWF",
    meet_start_time: "8:00:00",
    meet_end_time: "12:00:00",
    seat_count: 200,
    is_editable: true,
    is_syllabus: false,
    grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
    class_period_id: period2.id,
    class_status_id: 400,
    is_ghost: false
  })

  c5 = Repo.insert!(%Class{name: "Classo 101",
    subject: "BMO",
    code: "8001",
    section: "01",
    meet_days: "MWF",
    meet_start_time: "8:30:00",
    meet_end_time: "12:00:00",
    seat_count: 200,
    is_editable: true,
    is_syllabus: false,
    grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
    class_period_id: period3.id,
    class_status_id: 400,
    is_ghost: false
  })

  c6 = Repo.insert!(%Class{name: "Classo 201",
    subject: "BMO",
    code: "8001",
    section: "01",
    meet_days: "MWF",
    meet_start_time: "8:30:00",
    meet_end_time: "12:00:00",
    seat_count: 200,
    is_editable: true,
    is_syllabus: false,
    grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
    class_period_id: period3.id,
    class_status_id: 300,
    is_ghost: false
  })

  c7 = Repo.insert!(%Class{name: "Classo 301",
    subject: "BMO",
    code: "8001",
    section: "01",
    meet_days: "MWF",
    meet_start_time: "8:30:00",
    meet_end_time: "12:00:00",
    seat_count: 200,
    is_editable: true,
    is_syllabus: false,
    grade_scale: %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"},
    class_period_id: period3.id,
    class_status_id: 400,
    is_ghost: false
  })

  Repo.insert!(%Doc{
    class_id: c1.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
  })

  Repo.insert!(%Doc{
    class_id: c2.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
  })

  Repo.insert!(%Doc{
    class_id: c3.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
  })

  Repo.insert!(%Doc{
    class_id: c4.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
  })

  Repo.insert!(%Doc{
    class_id: c5.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
  })

  Repo.insert!(%Doc{
    class_id: c6.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
  })

  Repo.insert!(%Doc{
    class_id: c7.id,
    is_syllabus: true,
    name: "Test",
    path: "Name",
    user_id: user.id
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

    rp_weight = Repo.insert!(%Weight{
      name: "RP",
      weight: 35,
      class_id: class.id
    })

    r1 = Repo.insert!(%Assignment{
      name: "RP 1",
      due: date2,
      weight_id: rp_weight.id,
      class_id: class.id
    })

    r2 = Repo.insert!(%Assignment{
      name: "RP 2",
      due: date2,
      weight_id: rp_weight.id,
      class_id: class.id
    })

    r3 = Repo.insert!(%Assignment{
      name: "RP 3",
      due: date2,
      weight_id: rp_weight.id,
      class_id: class.id
    })

    a3 = Repo.insert!(%Assignment{
      name: "A3",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    a4 = Repo.insert!(%Assignment{
      name: "A4",
      due: date2,
      weight_id: assign_weight.id,
      class_id: class.id
    })

    t1 = Repo.insert!(%Assignment{
      name: "E1",
      due: date2,
      weight_id: test_weight.id,
      class_id: class.id
    })

    sc = Repo.insert!(%StudentClass{
      student_id: student.student.id,
      class_id: class.id,
      enrollment_link: "SC1111"
    })

    sc1 = Repo.insert!(%StudentClass{
      student_id: student1.student.id,
      class_id: class.id,
      enrollment_link: "SC2222"
    })

    sc2 = Repo.insert!(%StudentClass{
      student_id: student2.student.id,
      class_id: class.id,
      enrollment_link: "SC3333"
    })

    sc3 = Repo.insert!(%StudentClass{
      student_id: student3.student.id,
      class_id: class.id,
      enrollment_link: "SC4444"
    })

    sc4 = Repo.insert!(%StudentClass{
      student_id: student4.student.id,
      class_id: class.id,
      enrollment_link: "SC5555"
    })

    sc5 = Repo.insert!(%StudentClass{
      student_id: student5.student.id,
      class_id: class.id,
      enrollment_link: "SC6666"
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: r1.id,
      name: r1.name,
      due: r1.due,
      weight_id: r1.weight_id,
      grade: 99
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: r2.id,
      name: r2.name,
      due: r2.due,
      weight_id: r2.weight_id,
      grade: 75
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: r3.id,
      name: r3.name,
      due: r3.due,
      weight_id: r3.weight_id,
      grade: 97
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: nil
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 85
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc.id,
      assignment_id: a4.id,
      name: a4.name,
      due: a4.due,
      weight_id: a4.weight_id,
      grade: 74
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc1.id,
      assignment_id: r1.id,
      name: r1.name,
      due: r1.due,
      weight_id: r1.weight_id,
      grade: 99
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc1.id,
      assignment_id: r2.id,
      name: r2.name,
      due: r2.due,
      weight_id: r2.weight_id,
      grade: 75
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc1.id,
      assignment_id: r3.id,
      name: r3.name,
      due: r3.due,
      weight_id: r3.weight_id,
      grade: 97
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc1.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: nil
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc1.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 85
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc1.id,
      assignment_id: a4.id,
      name: a4.name,
      due: a4.due,
      weight_id: a4.weight_id,
      grade: 74
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc2.id,
      assignment_id: r1.id,
      name: r1.name,
      due: r1.due,
      weight_id: r1.weight_id,
      grade: 99
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc2.id,
      assignment_id: r2.id,
      name: r2.name,
      due: r2.due,
      weight_id: r2.weight_id,
      grade: 75
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc2.id,
      assignment_id: r3.id,
      name: r3.name,
      due: r3.due,
      weight_id: r3.weight_id,
      grade: 97
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc2.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: nil
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc2.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 85
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc2.id,
      assignment_id: a4.id,
      name: a4.name,
      due: a4.due,
      weight_id: a4.weight_id,
      grade: 74
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc3.id,
      assignment_id: r1.id,
      name: r1.name,
      due: r1.due,
      weight_id: r1.weight_id,
      grade: 99
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc3.id,
      assignment_id: r2.id,
      name: r2.name,
      due: r2.due,
      weight_id: r2.weight_id,
      grade: 75
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc3.id,
      assignment_id: r3.id,
      name: r3.name,
      due: r3.due,
      weight_id: r3.weight_id,
      grade: 97
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc3.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: nil
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc3.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 85
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc3.id,
      assignment_id: a4.id,
      name: a4.name,
      due: a4.due,
      weight_id: a4.weight_id,
      grade: 74
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc4.id,
      assignment_id: r1.id,
      name: r1.name,
      due: r1.due,
      weight_id: r1.weight_id,
      grade: 99
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc4.id,
      assignment_id: r2.id,
      name: r2.name,
      due: r2.due,
      weight_id: r2.weight_id,
      grade: 75
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc4.id,
      assignment_id: r3.id,
      name: r3.name,
      due: r3.due,
      weight_id: r3.weight_id,
      grade: 97
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc4.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: nil
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc4.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 85
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc4.id,
      assignment_id: a4.id,
      name: a4.name,
      due: a4.due,
      weight_id: a4.weight_id,
      grade: 74
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc5.id,
      assignment_id: r1.id,
      name: r1.name,
      due: r1.due,
      weight_id: r1.weight_id,
      grade: 99
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc5.id,
      assignment_id: r2.id,
      name: r2.name,
      due: r2.due,
      weight_id: r2.weight_id,
      grade: 75
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc5.id,
      assignment_id: r3.id,
      name: r3.name,
      due: r3.due,
      weight_id: r3.weight_id,
      grade: 97
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc5.id,
      assignment_id: t1.id,
      name: t1.name,
      due: t1.due,
      weight_id: t1.weight_id,
      grade: nil
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc5.id,
      assignment_id: a3.id,
      name: a3.name,
      due: a3.due,
      weight_id: a3.weight_id,
      grade: 85
    })

    Repo.insert!(%StudentAssignment{
      student_class_id: sc5.id,
      assignment_id: a4.id,
      name: a4.name,
      due: a4.due,
      weight_id: a4.weight_id,
      grade: 74
    })

    Repo.insert!(%FieldOfStudy{
      field: "Computer Science"
    })

    Repo.insert!(%Professor{
      name_first: "Jimothee",
      name_last: "Aaron",
      school_id: school.id
    })
  end
end
