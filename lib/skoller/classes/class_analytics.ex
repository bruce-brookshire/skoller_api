defmodule Skoller.Classes.ClassAnalytics do
    @moduledoc false

    alias Skoller.Analytics.Classes
  
    def get_analytics() do
        Classes.get_community_classes()
            |> Enum.map(&get_row_data(&1))
    end
  
    defp get_row_data(community) do
        [
          community.created_on |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string(), 
          community.is_student_created, 
          community.term_name, 
          community.term_status, 
          community.class_name, 
          community.class_status, 
          community.active, 
          community.inactive, 
          community.school_name
        ]
    end
  
  end