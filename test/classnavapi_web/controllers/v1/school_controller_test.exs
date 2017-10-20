defmodule ClassnavapiWeb.Api.V1.SchoolControllerTest do
    use ClassnavapiWeb.ConnCase
  
    alias Classnavapi.Repo
    alias Classnavapi.School
  
    setup do
      {:ok, jwt, _} = Classnavapi.Auth.encode_and_sign(%{:id => 1}, %{typ: "access"})
      {:ok, %{jwt: jwt}}
    end
  
    @valid_school_hku %{adr_city: "Nashville",
                        adr_line_1: "530 Church St", 
                        adr_line_2: "Suite 405", 
                        adr_state: "TN", 
                        adr_zip: "6158675309",
                        is_active: true,
                        is_editable: true,
                        name: "HKU",
                        timezone: "-8",
                        email_domains: [
                            %{
                                email_domain: "@hku.edu",
                                is_professor_only: false
                            }
                        ]}

    @valid_school_bmu %{adr_city: "Nashville",
                        adr_line_1: "555 Church St", 
                        adr_line_2: "Suite 100", 
                        adr_state: "TN", 
                        adr_zip: "37219",
                        is_active: true,
                        is_editable: true,
                        name: "BMU",
                        timezone: "-8",
                        email_domains: [
                            %{
                                email_domain: "@bmu.edu",
                                is_professor_only: false
                            }
                        ]}
  
    test "index/2 responds with all Schools", %{jwt: jwt} do
      hku = School.changeset_insert(%School{}, @valid_school_hku)
      |> Repo.insert!
      
      bmu = School.changeset_insert(%School{}, @valid_school_bmu)
      |> Repo.insert!
  
      response = build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(v1_school_path(build_conn(), :index))
      |> json_response(200)
  
      expected = [
          %{ "id" => hku.id, 
            "adr_city" => @valid_school_hku.adr_city, 
            "adr_line_1" => @valid_school_hku.adr_line_1, 
            "adr_line_2" => @valid_school_hku.adr_line_2, 
            "adr_state" => @valid_school_hku.adr_state, 
            "adr_zip" => @valid_school_hku.adr_zip, 
            "is_active" => @valid_school_hku.is_active, 
            "is_editable" => @valid_school_hku.is_editable, 
            "name" => @valid_school_hku.name, 
            "timezone" => @valid_school_hku.timezone},
          %{ "id" => bmu.id,
            "adr_city" => @valid_school_bmu.adr_city, 
            "adr_line_1" => @valid_school_bmu.adr_line_1, 
            "adr_line_2" => @valid_school_bmu.adr_line_2, 
            "adr_state" => @valid_school_bmu.adr_state, 
            "adr_zip" => @valid_school_bmu.adr_zip, 
            "is_active" => @valid_school_bmu.is_active, 
            "is_editable" => @valid_school_bmu.is_editable, 
            "name" => @valid_school_bmu.name, 
            "timezone" => @valid_school_bmu.timezone}
      ]
  
      assert  response == expected
    end
  
    
  end