defmodule Skoller.Students.StudentAnalytics do
    
    alias Skoller.Repo
    alias Skoller.StudentClasses.StudentClass
    alias Skoller.Assignments.Assignment
    alias Skoller.StudentAssignments.StudentAssignment
    alias Skoller.Mods.Mod
    alias Skoller.AssignmentPosts.Post, as: AssignmentPost
    alias Skoller.ChatPosts.Post, as: ChatPost
    alias Skoller.ChatComments.Comment, as: ChatComment

    import Ecto.Query

    @new_assignment_mod_type 400

    def get_student_analytics(user) do

        #Lets do these all together to minimize queries executed (I/O)
        student_assignments = get_assignments(user.student_id)

        active = student_assignments
            |> Enum.filter(& &1.is_dropped == false)
            |> length()
        
        inactive = student_assignments
            |> Enum.filter(& &1.is_dropped == true)
            |> length()

        grades_entered = student_assignments
            |> Enum.filter(& &1.grade != nil)
            |> length()

        #Individual queries
        mods = get_number_mods(user.student_id)
        assignment_posts = get_number_assignment_posts(user.student_id)
        chat_posts = get_number_chat_posts(user.student_id)
        chat_comments = get_number_chat_comments(user.student_id)
        created_assignments = get_number_created_assignments(user)

        #Return map of result analytics
        %{
            active: active, 
            inactive: inactive, 
            grades_entered: grades_entered, 
            mods: mods, 
            assignment_posts: assignment_posts, 
            chat_posts: chat_posts, 
            chat_comments: chat_comments, 
            created_assignments: created_assignments
        }
    end


    defp get_number_mods(student_id) do
        from(m in Mod)
            |> where([m], m.student_id == ^student_id)
            |> Repo.aggregate(:count, :id)
    end


    defp get_number_assignment_posts(student_id) do
        from(p in AssignmentPost)
            |> where([p], p.student_id == ^student_id)
            |> Repo.aggregate(:count, :id)
    end


    defp get_assignments(student_id) do
        from(sc in StudentClass)
            |> join(:inner, [sc], a in StudentAssignment, a.student_class_id == sc.id)
            |> where([sc, a], sc.student_id == ^student_id)
            |> select([sc, a], %{is_dropped: sc.is_dropped, grade: a.grade})
            |> Repo.all()
    end


    defp get_number_chat_posts(student_id) do
        from(p in ChatPost)
            |> where([p], p.student_id == ^student_id)
            |> Repo.aggregate(:count, :id)
    end


    defp get_number_chat_comments(student_id) do
        from(p in ChatComment)
            |> where([p], p.student_id == ^student_id)
            |> Repo.aggregate(:count, :id)
    end
    

    defp get_number_created_assignments(user) do

        syllabus_tool_created_assignments = from(a in Assignment)
            |> where([a], a.created_by == ^user.id)
            |> Repo.aggregate(:count, :id)

        mod_created_assignments = from(m in Mod)
            |> where([m], m.student_id == ^user.student_id and m.assignment_mod_type_id == @new_assignment_mod_type)
            |> Repo.aggregate(:count, :id)

        syllabus_tool_created_assignments + mod_created_assignments
    end

end