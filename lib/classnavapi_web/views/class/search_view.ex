defmodule ClassnavapiWeb.Class.SearchView do
    use ClassnavapiWeb, :view
  
    alias ClassnavapiWeb.Class.SearchView
    alias ClassnavapiWeb.Helpers.ClassCalcs
    alias ClassnavapiWeb.ProfessorView
  
    def render("index.json", %{classes: classes}) do
        render_many(classes, SearchView, "class.json", as: :class)
    end
  
    def render("class.json", %{class: %{class: class, class_period: class_period, professor: professor, school: school, class_status: class_status, enroll: enroll}}) do
        %{
                id: class.id,
                meet_days: class.meet_days,
                meet_start_time: class.meet_start_time,
                name: class.name,
                number: class.number,
                enrolled: get_enrolled(enroll.count),
                campus: class.campus,
                professor: render_one(professor, ProfessorView, "professor-short.json"),
                school: %{
                    id: school.id,
                    name: school.name
                },
                is_new_class: class.is_new_class,
                status: ClassCalcs.get_class_status(class_status),
                period_name: class_period.name
        }
    end

    defp get_enrolled(nil), do: 0
    defp get_enrolled(val), do: val
  end
  