defmodule ClassnavapiWeb.Api.V1.UserControllerTest do
  use ClassnavapiWeb.ConnCase

  alias Classnavapi.Repo
  alias Classnavapi.User

  setup do
    {:ok, jwt, _} = Classnavapi.Auth.encode_and_sign(%{:id => 1}, %{typ: "access"})
    {:ok, %{jwt: jwt}}
  end

  @valid_school_attrs %{adr_city: "Nashville",
                      adr_line_1: "530 Church St", 
                      adr_line_2: "Suite 405", 
                      adr_state: "TN", 
                      adr_zip: "6158675309",
                      is_active: true,
                      is_editable: true,
                      name: "HKU",
                      timezone: "-8"}

  @valid_student_attrs %{birthday: "2017-10-12T18:51:53Z", 
                          gender: "male", 
                          name_first: "Sean", 
                          name_last: "Paul", 
                          phone: "2813348004", 
                          major: "CS", 
                          school_id: 1}

  @valid_user_john %{email: "john@example.com", password: "test"}
  @valid_user_jane %{email: "jane@example.com", password: "test"}
  @invalid_user %{email: "", password: ""}

  test "index/2 responds with all Users", %{jwt: jwt} do
    john = User.changeset_insert(%User{}, @valid_user_john)
    |> Repo.insert!
    
    jane = User.changeset_insert(%User{}, @valid_user_jane)
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :index))
    |> json_response(200)

    expected = [
        %{ "email" => @valid_user_john.email, "id" => john.id},
        %{ "email" => @valid_user_jane.email, "id" => jane.id}
    ]

    assert  response == expected
  end

  test "show/2 responds with a users id if the user is found", %{jwt: jwt} do
    user = User.changeset_insert(%User{}, @valid_user_john)
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :show, user.id))
    |> json_response(200)

    expected = %{ "email" => @valid_user_john.email, "id" => user.id, "student" => nil}

    assert  response == expected
  end

  test "show/2 responds with an error when no user is found", %{jwt: jwt} do
    assert_raise Ecto.NoResultsError, fn ->
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> get(v1_user_path(build_conn(), :show, 1))
        |> json_response(404)
    end
  end

  test "Create/2 creates and responds with a newly created user if attributes are valid", %{jwt: jwt} do

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, @valid_user_john))
    |> json_response(200)

    assert response["id"] |> is_integer
    assert response["id"] > 0
    assert response["email"] == @valid_user_john.email
    assert response["student"] == nil
  end

  test "Create/2 creates and responds with a new user with student if attributes are valid", %{jwt: jwt} do

    school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    |> Repo.insert!
    
    student = %{@valid_student_attrs | school_id: school.id}

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, Map.put(@valid_user_john, :student, student)))
    |> json_response(200)

    assert response["id"] |> is_integer
    assert response["id"] > 0
    assert response["student"]["id"] |> is_integer
    assert response["student"]["id"] > 0
  end

  test "Create/2 responds in error if email is invalid for school", %{jwt: jwt} do
    
    school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    |> Repo.insert!
    
    student = %{@valid_student_attrs | school_id: school.id}

    invalid_user = %{@valid_user_john | email: "test@nottheemaildomain.com"}

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, Map.put(invalid_user, :student, student)))
    |> json_response(422)

    expected = %{"errors" => %{"student" => ["Invalid email for school."]}}
    
    assert response == expected
  end

  test "Create/2 responds in error if school does not exist", %{jwt: jwt} do

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, Map.put(@valid_user_john, :student, @valid_student_attrs)))
    |> json_response(422)

    expected = %{"errors" => %{"student" => ["Invalid school"]}}

    assert response == expected
  end

  test "Create/2 does not create user and returns in error if email is invalid", %{jwt: jwt} do
    
    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, %{@valid_user_john | email: "john.com"}))
    |> json_response(422)

    expected = %{"errors" => %{"email" => ["has invalid format"]}}

    assert response == expected
  end

  test "Create/2 does not create user and returns in error if required fields are missing", %{jwt: jwt} do
    
    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, @invalid_user))
    |> json_response(422)

    expected = %{"errors" => %{"email" => ["can't be blank"], "password" => ["can't be blank"]}}

    assert response == expected
  end

  test "Update/2 does not update email and updates other fields when valid", %{jwt: jwt} do
    user = User.changeset_insert(%User{}, @valid_user_john)
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(v1_user_path(build_conn(), :update, user.id, email: "update@example.com", password: "update"))
    |> json_response(200)

    user_updated = Repo.get(User, response["id"])

    assert response["id"] |> is_integer
    assert response["id"] == user.id
    assert response["email"] == @valid_user_john.email
    assert response["student"] == nil
    assert Comeonin.Bcrypt.checkpw("update", user_updated.password_hash)
  end

  test "Update/2 updates students when id is provided", %{jwt: jwt} do
    school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    |> Repo.insert!
    
    student = %{@valid_student_attrs | school_id: school.id}

    user = User.changeset_insert(%User{}, Map.put(@valid_user_john, :student, student))
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(v1_user_path(build_conn(), :update, user.id, student: Map.put(%{student | name_first: "Smashville"}, :id, user.student.id)))
    |> json_response(200)

    assert response["id"] |> is_integer
    assert response["id"] == user.id
    assert response["student"]["id"] |> is_integer
    assert response["student"]["id"] == user.student.id
    assert response["student"]["name_first"] == "Smashville"
  end

  test "update/2 responds with an error when no user is found", %{jwt: jwt} do
    assert_raise Ecto.NoResultsError, fn ->
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> put(v1_user_path(build_conn(), :show, 1))
        |> json_response(404)
    end
  end
end