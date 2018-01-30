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

    def render("index.json", %{classes: classes}) do
        render_many(classes, ClassView, "class.json")
    end

    def render("show.json", %{class: class}) do
        render_one(class, ClassView, "class_detail.json")
    end

    def render("class.json", %{class: %{class: class, professor: professor, class_period: class_period}}) do
        %{
            id: class.id,
            class_end: class.class_end,
            class_start: class.class_start,
            credits: class.credits,
            crn: class.crn,
            grade_scale: class.grade_scale,
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
            type: class.class_type,
            campus: class.campus,
            class_period_id: class.class_period_id,
            length: ClassCalcs.get_class_length(class, class_period),
            professor: render_one(professor, ProfessorView, "professor.json")
        }
    end

    def render("class.json", %{class: %{class: class, professor: professor}}) do
        %{
            id: class.id,
            class_end: class.class_end,
            class_start: class.class_start,
            credits: class.credits,
            crn: class.crn,
            grade_scale: class.grade_scale,
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
            type: class.class_type,
            campus: class.campus,
            class_period_id: class.class_period_id,
            length: ClassCalcs.get_class_length(class),
            professor: render_one(professor, ProfessorView, "professor.json")
        }
    end

    def render("class.json", %{class: class}) do
        class = class |> Repo.preload([:professor, :class_status])
        %{
            id: class.id,
            class_end: class.class_end,
            class_start: class.class_start,
            credits: class.credits,
            crn: class.crn,
            grade_scale: class.grade_scale,
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
            type: class.class_type,
            campus: class.campus,
            class_period_id: class.class_period_id,
            length: ClassCalcs.get_class_length(class),
            professor: render_one(class.professor, ProfessorView, "professor.json"),
            status: render_one(class.class_status, StatusView, "status.json")
        }
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
                student_requests: render_many(class.student_requests, StudentRequestView, "student_request.json")
            }
        )
    end
end
