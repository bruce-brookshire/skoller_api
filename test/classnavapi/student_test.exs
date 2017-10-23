defmodule Classnavapi.StudentTest do
  use Classnavapi.DataCase

  alias Classnavapi.Student

  @valid_attrs %{birthday: "2017-10-12T18:51:53Z", 
                gender: "male", 
                name_first: "Test", 
                name_last: "Student", 
                phone: "6158675309",
                major: "Testing",
                school_id: 1}

  test "student with valid attributes" do
    changeset = Student.changeset(%Student{}, @valid_attrs)
    assert changeset.valid?
  end

  test "student with no birthday" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :birthday))
    refute changeset.valid?
  end

  test "student with no gender" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :gender))
    refute changeset.valid?
  end

  test "student with no first name" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :name_first))
    refute changeset.valid?
  end

  test "student with no last name" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :name_last))
    refute changeset.valid?
  end

  test "student with no phone" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :phone))
    refute changeset.valid?
  end

  test "student with no major" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :major))
    refute changeset.valid?
  end

  test "student with no school" do
    changeset = Student.changeset(%Student{}, Map.delete(@valid_attrs, :school_id))
    refute changeset.valid?
  end

end