defmodule SkollerWeb.Api.V1.School.ClassController do
  use SkollerWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """

  alias SkollerWeb.ClassView
  alias SkollerWeb.MinClassView
  alias Skoller.Classes

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}

  def index(conn, %{"school_id" => school_id} = params) do
    classes = Classes.get_classes_by_school(school_id, params)
    render(conn, ClassView, "index.json", classes: classes)
  end

  def index_min(conn, %{"school_id" => school_id}) do
    classes = Classes.get_classes_by_school(school_id)
    render(conn, MinClassView, "index.json", classes: classes)
  end
end