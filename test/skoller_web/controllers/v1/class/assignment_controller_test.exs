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
    class = insert(:class)
    assignment = insert(:assignment, class: class)
    weight = insert(:weight, class: class)
    role = insert(:role)
    user = insert(:user)

    insert(:user_role, role: role, user: user)

    %{conn: conn |> authenticate(user), assignment: assignment, class: class, weight: weight}
  end

  describe "index" do
    test "GET /classes/:class_id/assignments returns the list of assignments", %{conn: conn, assignment: assignment, class: class} do
      conn = get(conn, Routes.v1_class_assignment_path(conn, :create, class))
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      [resp | _] = json_response(conn, 200)
      assert resp["name"] == assignment.name
    end
  end

  describe "create" do
    test "POST /classes/:class_id/assignments creates an assignment with given params", %{conn: conn, class: class} do
      conn = post(conn, Routes.v1_class_assignment_path(conn, :create, class), @create_attrs)
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      resp = json_response(conn, 200)
      assert resp["name"] == @create_attrs["name"]
    end

    test "POST /classes/:class_id/assignments returns an error when params is invalid", %{conn: conn, class: class} do
      conn = post(conn, Routes.v1_class_assignment_path(conn, :create, class), @invalid_attrs)
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors == %{"name" => ["can't be blank"]} 
    end
  end

  describe "update" do
    test "PUT /classes/:class_id/assignments/:id updates an assignment with given params", %{conn: conn, assignment: assignment, class: class, weight: weight} do
      attrs = %{@update_attrs | "weight_id" => weight.id}

      conn = put(conn, Routes.v1_class_assignment_path(conn, :update, class, assignment), attrs)
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      resp = json_response(conn, 200)
      assert resp["name"] == @update_attrs["name"]
      assert resp["weight_id"] == weight.id
    end

    test "PUT /classes/:class_id/assignments/:id returns an error when params is invalid", %{conn: conn, assignment: assignment, class: class} do
      conn = put(conn, Routes.v1_class_assignment_path(conn, :update, class, assignment), @invalid_attrs)
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors == %{"name" => ["can't be blank"]} 
    end
  end
end
