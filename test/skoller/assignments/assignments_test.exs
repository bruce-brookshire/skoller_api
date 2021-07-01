defmodule Skoller.AssignmentsTest do
  use Skoller.DataCase, async: true

  alias Skoller.Assignments

  @valid_attrs %{
    class_id: nil,
    name: "Assigment 01"
  }

  @update_attrs %{
    name: "Assigment 02"
  }

  @invalid_attrs %{
    class_id: nil,
    name: nil
  }

  setup do
    class = insert(:class)
    user = insert(:user)
    assignment = insert(:assignment, class_id: class.id)

    %{assignment: assignment, class: class, user: user}
  end

  test "get_assignment_by_id!/1 returns the assignment struct with given id", %{assignment: assignment} do
    assert Assignments.get_assignment_by_id!(assignment.id) == assignment
  end

  test "get_assignment_by_id/1 returns the assignment struct with given id", %{assignment: assignment} do
    assert Assignments.get_assignment_by_id(assignment.id) == assignment
  end

  test "create_assignment/3 with valid data creates an assignment", %{class: class, user: user} do
    attrs = %{@valid_attrs | class_id: class.id}
    assert {:ok, %{assignment: assignment}} = Assignments.create_assignment(class.id, user.id, attrs)
    assert assignment.name == @valid_attrs.name
  end

  test "create_assignment/3 with invalid data returns an error changeset", %{class: class, user: user} do
    assert {:error, :assignment, %Ecto.Changeset{}, %{}} = Assignments.create_assignment(class.id, user.id, @invalid_attrs)
  end

  test "update_assignment/3 with valid data updates an assignment", %{assignment: assignment, user: user} do
    assert {:ok, %{assignment: assignment}} = Assignments.update_assignment(assignment.id, user.id, @update_attrs)
    assert assignment.name == @update_attrs.name
  end

  test "update_assignment/3 with invalid data returns an error changeset", %{assignment: assignment, user: user} do
    assert {:error, :assignment, %Ecto.Changeset{}, %{}} = Assignments.update_assignment(assignment.id, user.id, @invalid_attrs)
  end
end
