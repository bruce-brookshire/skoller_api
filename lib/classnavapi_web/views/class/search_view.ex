defmodule ClassnavapiWeb.Class.SearchView do
    use ClassnavapiWeb, :view
  
    alias ClassnavapiWeb.Class.SearchView
  
    def render("index.json", %{classes: classes}) do
        render_many(classes, SearchView, "class.json", as: :class)
    end
  
    def render("class.json", %{class: class}) do
        %{
            class: %{
                id: class.id,
                meet_days: class.meet_days,
                meet_start_time: class.meet_start_time,
                name: class.name,
                number: class.number,
                seat_count: class.seat_count
            },
            professor: %{
                name: class.professor.name_last
            },
            school: %{
                name: class.school.name
            },
            status: %{
                name: class.class_status.name
            }
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
  