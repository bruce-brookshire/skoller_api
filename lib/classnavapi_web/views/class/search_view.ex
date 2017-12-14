defmodule ClassnavapiWeb.Class.SearchView do
    use ClassnavapiWeb, :view
  
    alias ClassnavapiWeb.Class.SearchView
    alias ClassnavapiWeb.Helpers.ClassCalcs
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ProfessorView
  
    def render("index.json", %{classes: classes}) do
        render_many(classes, SearchView, "class.json", as: :class)
    end
  
    def render("class.json", %{class: class}) do
        class = class |> Repo.preload([:school, :class_status, :professor])
        %{
                id: class.id,
                meet_days: class.meet_days,
                meet_start_time: class.meet_start_time,
                name: class.name,
                number: class.number,
                enrolled: ClassCalcs.get_enrollment(class),
                length: ClassCalcs.get_class_length(class),
                campus: class.campus,
                professor: render_one(class.professor, ProfessorView, "professor-short.json"),
                school: %{
                    id: class.school.id,
                    name: class.school.name
                },
                status: ClassCalcs.get_class_status(class)
        }
    end
  end
  