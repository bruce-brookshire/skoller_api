defmodule ClassnavapiWeb.ClassView do
    use ClassnavapiWeb, :view

    alias ClassnavapiWeb.ClassView
    alias ClassnavapiWeb.Class.StatusView
    alias ClassnavapiWeb.ProfessorView
    alias ClassnavapiWeb.Helpers.ClassCalcs
    alias ClassnavapiWeb.Class.HelpRequestView
    alias ClassnavapiWeb.Class.ChangeRequestView
    alias Classnavapi.Repo
    alias ClassnavapiWeb.SchoolView
    alias ClassnavapiWeb.Class.StudentRequestView
    alias Classnavapi.Class.StudentClass

    import Ecto.Query

    def render("index.json", %{classes: classes}) do
        render_many(classes, ClassView, "class.json")
    end

    def render("show.json", %{class: class}) do
        render_one(class, ClassView, "class_detail.json")
    end

    def render("class.json", %{class: %{class: class, professor: professor, class_period: class_period}}) do
        base_class_view(class)
        |> Map.merge(
            %{
                class_period_name: class.class_period.name,
                length: ClassCalcs.get_class_length(class, class_period),
                professor: render_one(professor, ProfessorView, "professor.json"),
            }
        )
    end

    def render("class.json", %{class: %{class: class, professor: professor}}) do
        class = class |> Repo.preload(:class_period)
        base_class_view(class)
        |> Map.merge(
            %{
                class_period_name: class.class_period.name,
                length: ClassCalcs.get_class_length(class),
                professor: render_one(professor, ProfessorView, "professor.json")
            }
        )
    end

    def render("class.json", %{class: class}) do
        class = class |> Repo.preload([:professor, :class_status, :class_period])
        base_class_view(class)
        |> Map.merge(
            %{
                class_period_name: class.class_period.name,
                length: ClassCalcs.get_class_length(class),
                professor: render_one(class.professor, ProfessorView, "professor.json"),
                status: render_one(class.class_status, StatusView, "status.json")
            }
        )
    end

    def render("class_detail.json", %{class: class}) do
        class = class |> Repo.preload([:class_status, :help_requests, :change_requests, :student_requests, :school], force: true)
        class
        |> render_one(ClassView, "class.json")
        |> Map.merge(
            %{
                school: render_one(class.school, SchoolView, "school.json"),
                status: render_one(class.class_status, StatusView, "status.json"),
                help_requests: render_many(class.help_requests, HelpRequestView, "help_request.json"),
                change_requests: render_many(class.change_requests, ChangeRequestView, "change_request.json"),
                student_requests: render_many(class.student_requests, StudentRequestView, "student_request.json"),
                enrollment: class |> get_class_enrollment()
            }
        )
    end

    def render("class_short.json", %{class: class}) do
        %{
            id: class.id,
            name: class.name,
            number: class.number,
            is_editable: class.is_editable,
            campus: class.campus,
            class_period_id: class.class_period_id,
        }
    end

    defp base_class_view(class) do
        %{
            id: class.id,
            class_end: class.class_end,
            class_start: class.class_start,
            credits: class.credits,
            crn: class.crn,
            grade_scale: convert_gs_to_string(class.grade_scale_map),
            grade_scale_map: class.grade_scale_map,
            location: class.location,
            meet_days: class.meet_days,
            meet_end_time: class.meet_end_time,
            meet_start_time: class.meet_start_time,
            name: class.name,
            number: class.number,
            seat_count: class.seat_count,
            is_enrollable: class.is_enrollable,
            is_editable: class.is_editable,
            is_syllabus: class.is_syllabus,
            is_points: class.is_points,
            is_new_class: class.is_new_class,
            is_chat_enabled: class.is_chat_enabled,
            is_assignment_posts_enabled: class.is_assignment_posts_enabled,
            type: class.class_type,
            campus: class.campus,
            class_period_id: class.class_period_id
        }
    end

    defp convert_gs_to_string(gs) do
        gs 
        |> Enum.reduce("", & &2 <> Kernel.elem(&1, 0) <> "," <> get_grade_string(Kernel.elem(&1, 1)) <> "|")
        |> String.trim_trailing("|")
    end

    defp get_grade_string(grade) when is_binary(grade), do: grade
    defp get_grade_string(grade) when is_integer(grade), do: to_string(grade)
    defp get_grade_string(grade) do
        grade |> Decimal.to_string()
    end

    defp get_class_enrollment(class) do
        from(sc in StudentClass)
        |> where([sc], sc.class_id == ^class.id and sc.is_dropped == false)
        |> Repo.aggregate(:count, :id)
    end
end
