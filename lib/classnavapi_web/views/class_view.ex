defmodule ClassnavapiWeb.ClassView do
    use ClassnavapiWeb, :view

    alias ClassnavapiWeb.ClassView

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
            location: class.location,
            meet_days: class.meet_days,
            meet_end_time: class.meet_end_time,
            meet_start_time: class.meet_start_time,
            name: class.name,
            number: class.number,
            seat_count: class.seat_count,
            is_enrollable: class.is_enrollable,
            is_editable: class.is_editable,
            is_syllabus: class.is_syllabus
        }
    end

    def render("class_detail.json", %{class: %{class_status_id: 400} = class}) do
        status = Classnavapi.Repo.get!(Classnavapi.Class.Status, 400)
        issue = Classnavapi.Repo.get_by!(Classnavapi.Class.Issue, class_id: class.id)
        class
        |> render_one(ClassView, "class.json")
        |> Map.merge(
            %{
                status: render_one(status, ClassnavapiWeb.Class.StatusView, "status.json")
                issue: render_one(issue, ClassnavapiWeb.Class.IssueView, "issue.json")
            }
        )
    end

    def render("class_detail.json", %{class: class}) do
        status = Classnavapi.Repo.get!(Classnavapi.Class.Status, class.class_status_id)
        class
        |> render_one(ClassView, "class.json")
        |> Map.merge(
            %{
                status: render_one(status, ClassnavapiWeb.Class.StatusView, "status.json")
            }
        )
    end
end
  