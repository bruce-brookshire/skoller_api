defmodule Skoller.Students.StudentAnalytics do
    
    alias Skoller.Repo
    alias Skoller.Users.User
    alias Skoller.Students.Student
    alias Skoller.Schools.School
    alias Skoller.Organizations.Organization
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

    defp aggregate_individual_metrics(user_id) do
        from(u in User)
            |> join(:inner, [u], s in Student, u.student_id == s.id)
            |> join(:left, [u, s], o in Organization, s.primary_organization_id == o.id)
            |> join(:left, [u, s, o], sc in School, s.primary_school_id == sc.id)
            |> where([u, s, o, sc], u.id == ^user_id)
            |> select([u, s, o, sc], [
                fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", u.inserted_at),
                s.name_first,
                s.name_last, 
                u.email,
                s.phone,
                fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", u.last_login),
                s.is_verified,
                sc.name,
                s.grad_year,
                fragment("(SELECT COUNT(*) FROM student_classes sc WHERE sc.student_id = ? AND sc.is_dropped = false)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc JOIN classes c ON sc.class_id = c.id WHERE sc.student_id = ? AND sc.is_dropped = false AND c.class_status_id = 1400)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc JOIN classes c ON sc.class_id = c.id WHERE sc.student_id = ? AND c.class_status_id = 1400)", s.id),
                o.name,
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
            |> join(:inner, [u], sf in StudentField, sf.student_id == u.student_id)
            |> join(:inner, [u, sf], f in FieldOfStudy, sf.field_of_study_id == f.id)
            |> where([u, sf, f], u.id == ^user_id)
            |> select([u, sf, f], f.field)
            |> Repo.all()
            |> Enum.join(" | ")
        ]
    end
end