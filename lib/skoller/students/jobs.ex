defmodule Skoller.Students.Jobs do

  import Ecto.Query

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.StudentClasses.StudentClass

  def set_missing_main_schools()  do
    students = from(s in Student, where: is_nil(s.primary_school_id)) |> Repo.all()
    Enum.each(students, fn student ->
      student_class = from(c in StudentClass, where: c.student_id == ^student.id, order_by: [:updated_at], limit: 1) |> Repo.one()
      if(student_class) do
        student_class = student_class |> Repo.preload(class: [class_period: [:school]])
        from(s in Student, where: s.id == ^student.id, update: [set: [primary_school_id: ^student_class.class.class_period.school.id]]) |> Repo.update_all([])
      end
    end)
  end

end