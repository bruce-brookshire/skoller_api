defmodule Skoller.Students.StudentAnalytics do
    
    alias Skoller.Repo
    alias Skoller.Users.User
    alias Skoller.Students.Student
    alias Skoller.Schools.School
    alias Skoller.Students.FieldOfStudy, as: StudentField
    alias Skoller.FieldsOfStudy.FieldOfStudy

    import Ecto.Query

    def get_analytics() do
        from(u in User)
            |> where([u], not is_nil(u.student_id) )
            |> select([u], u.id)
            |> Repo.all()
            |> Enum.map(&aggregate_individual_metrics(&1))
    end
# ? HERE
    defp aggregate_individual_metrics(user_id) do
        from(u in User)
            |> join(:inner, [u], s in Student, on: u.student_id == s.id)
            |> join(:left, [u, s], sc in School, on: s.primary_school_id == sc.id)
            |> where([u, s, sc], u.id == ^user_id)
            |> select([u, s, sc], [
                fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", u.inserted_at),
                s.name_first,
                s.name_last, 
                u.email,
                s.phone,
                fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", u.last_login),
                sc.name,
                sc.adr_locality,
                sc.adr_region,
                s.grad_year,
                fragment("(SELECT SUM(p.value) FROM student_points p WHERE p.student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc WHERE sc.student_id = ? AND sc.is_dropped = false)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc JOIN classes c ON sc.class_id = c.id WHERE sc.student_id = ? AND sc.is_dropped = false AND c.class_status_id = 1400)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc JOIN classes c ON sc.class_id = c.id WHERE sc.student_id = ? AND c.class_status_id = 1400)", s.id),
                fragment("(SELECT csl.name FROM custom_signups cs JOIN custom_signup_links csl ON cs.custom_signup_link_id = csl.id WHERE cs.student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_assignments sa JOIN student_classes sc ON sa.student_class_id = sc.id WHERE sc.is_dropped = false AND sc.student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_assignments sa JOIN student_classes sc ON sa.student_class_id = sc.id WHERE sc.student_id = ? AND sc.is_dropped = true)", s.id),
                fragment("(SELECT COUNT(*) FROM student_assignments sa JOIN student_classes sc ON sa.student_class_id = sc.id WHERE sc.student_id = ? AND sa.grade IS NOT NULL)", s.id),
                fragment("(SELECT COUNT(*) FROM assignment_modifications WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM assignments a LEFT JOIN assignment_modifications am ON a.id = am.assignment_id WHERE a.created_by = ? OR (am.student_id = ? AND am.assignment_mod_type_id = 400))", u.id, s.id)
                ])
            |> Repo.one!()
            |> get_majors(user_id)
    end

    defp get_majors(data, user_id) do
        data ++ [from(u in User)
            |> join(:inner, [u], sf in StudentField, on: sf.student_id == u.student_id)
            |> join(:inner, [u, sf], f in FieldOfStudy, on: sf.field_of_study_id == f.id)
            |> where([u, sf, f], u.id == ^user_id)
            |> select([u, sf, f], f.field)
            |> Repo.all()
            |> Enum.join(" | ")
        ]
    end
end