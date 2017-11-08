defmodule ClassnavapiWeb.ClassView do
    use ClassnavapiWeb, :view

    alias ClassnavapiWeb.ClassView
    alias ClassnavapiWeb.Class.StatusView
    alias ClassnavapiWeb.Helpers.ViewCalcs
    alias ClassnavapiWeb.Class.IssueView

    def render("index.json", %{classes: classes}) do
        render_many(classes, ClassView, "class.json")
    end

    def render("show.json", %{class: class}) do
        render_one(class, ClassView, "class_detail.json")
    end

    def render("class.json", %{class: class}) do
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
            type: class.class_type,
            length: ViewCalcs.get_class_length(class, class.class_period)
        }
    end

    def render("class_detail.json", %{class: class}) do
        class
        |> render_one(ClassView, "class.json")
        |> Map.merge(
            %{
                status: render_one(class.class_status, StatusView, "status.json"),
                issues: render_many(class.issues, IssueView, "issue.json")
            }
        )
    end
end
