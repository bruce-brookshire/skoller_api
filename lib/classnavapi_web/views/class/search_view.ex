defmodule ClassnavapiWeb.Class.SearchView do
    use ClassnavapiWeb, :view
  
    alias ClassnavapiWeb.Class.SearchView
  
    def render("index.json", %{classes: classes}) do
        render_many(classes, SearchView, "class.json")
    end
  
    def render("class.json", %{} = class) do
        require IEx
        IEx.pry
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

    # def render("class_detail.json", %{class: class}) do
    #     status = Repo.get!(Status, class.class_status_id)
    #     class
    #     |> render_one(SearchView, "class.json")
    #     |> Map.merge(
    #         %{
    #             status: render_one(status, StatusView, "status.json")
    #         }
    #     )
    # end
  end
  