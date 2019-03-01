defmodule Skoller.Students.StudentAnalytics do
    
    alias Skoller.Repo
    alias Skoller.Users.User
    alias Skoller.Students.Student

    import Ecto.Query

    def get_student_analytics() do
        from(u in User)
            |> join(:inner, [u], s in Student, u.student_id == s.id)
            |> select([u, s], [
                u.inserted_at,
                s.name_first,
                s.name_last, 
                u.email,
                s.phone,
                s.is_verified,
                fragment( "(SELECT name FROM schools WHERE id = ?)", s.primary_school_id),
                s.grad_year,
                fragment("(SELECT COUNT(*) FROM student_classes sc WHERE sc.student_id = ? AND sc.is_dropped = false)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc JOIN classes c ON sc.class_id = c.id WHERE sc.student_id = ? AND sc.is_dropped = false AND c.class_status_id = 1400)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_classes sc JOIN classes c ON sc.class_id = c.id WHERE sc.student_id = ? AND c.class_status_id = 1400)", s.id),
                fragment("(SELECT name FROM organizations where id = ?)", s.primary_organization_id),
                fragment("(SELECT COUNT(*) FROM student_assignments sa JOIN student_classes sc ON sa.student_class_id = sc.id WHERE sc.is_dropped = false AND sc.student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM student_assignments sa JOIN student_classes sc ON sa.student_class_id = sc.id WHERE sc.student_id = ? AND sc.is_dropped = true)", s.id),
                fragment("(SELECT COUNT(*) FROM student_assignments WHERE student_id = ? AND grade IS NOT NULL)", s.id),
                fragment("(SELECT COUNT(*) FROM assignment_modifications WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM assignment_posts WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM chat_posts WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM chat_comments WHERE student_id = ?)", s.id),
                fragment("(SELECT COUNT(*) FROM assignments a LEFT JOIN assignment_modifications am ON a.id = am.assignment_id WHERE a.created_by = ? OR (am.student_id = ? AND am.assignment_mod_type_id = 400))", u.id, s.id)
            ])
            |> Repo.all()
    end
end