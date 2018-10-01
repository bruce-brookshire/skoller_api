defmodule Skoller.StudentsTest do
  use ExUnit.Case, async: true
  use Skoller.DataCase
  doctest Skoller.Students, 
    except: [get_field_of_study_count_by_school_id: 1
    ]
end
