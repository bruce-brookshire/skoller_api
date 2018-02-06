defmodule ClassnavapiWeb.Api.V1.Student.ChatController do

  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student
  plug :verify_member, %{of: :school, using: :class_id}
  plug :verify_member, %{of: :class, using: :id}

  def chat(conn, params) do
    
  end

  def inbox(conn, params) do
    
  end
end