defmodule SkollerWeb.Api.V1.Class.AssignmentControllerTest do
  @moduledoc "Student Class Assignment Controller Test"
  use SkollerWeb.ConnCase, async: true

  @create_attrs %{
    "weight_id" => nil,
    "name" => "Assignment 01",
    "due" => Timex.now()
  }

  @update_attrs %{
    "weight_id" => nil,
    "name" => "Assignment 02",
    "due" => Timex.now()
  }

  @invalid_attrs %{
    "weight_id" => nil,
    "name" => nil,
    "due" => nil
  }

  setup %{conn: conn} do
    assignment = insert(:assignment)
    class = insert(:class)
    role = insert(:role)
    user = insert(:user)
    weight = insert(:weight, class: class)

    insert(:user_role, role: role, user: user)

    %{conn: conn |> authenticate(user), assignment: assignment, class: class, weight: weight}
  end

  test "/classes/:class_id/assignments creates an assignment with given valid params", %{conn: conn, class: class} do
    conn = post(conn, Routes.v1_class_assignment_path(conn, :create, class), @create_attrs)
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    
    resp = json_response(conn, 200)
    assert resp["name"] == @create_attrs["name"]
  end

  test "/classes/:class_id/assignments creates an assignment with given invalid params", %{conn: conn, class: class} do
    conn = post(conn, Routes.v1_class_assignment_path(conn, :create, class), @invalid_attrs)
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert %{"errors" => errors} = json_response(conn, 422)

    expected_results = %{"name" => ["can't be blank"]}
    
    assert errors == expected_results 
  end

  test "/classes/:class_id/assignments/:id updates an assignment with given valid params", %{conn: conn, assignment: assignment, class: class, weight: weight} do
    attrs = %{@update_attrs | "weight_id" => weight.id}

    conn = put(conn, Routes.v1_class_assignment_path(conn, :update, class, assignment), attrs)
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    
    resp = json_response(conn, 200)
    assert resp["name"] == @update_attrs["name"]
    assert resp["weight_id"] == weight.id
  end
end
