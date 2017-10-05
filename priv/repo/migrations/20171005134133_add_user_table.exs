defmodule Classnavapi.Repo.Migrations.AddUserTable do
  use Ecto.Migration

  def change do
    create table("users") do
        add :email,       :string
        add :name_first,  :string
        add :name_last,   :string
        add :phone,       :string
        add :major,       :string
        add :grad_year,   :integer
        add :birthday,    :date
        add :gender,      :string
        add :password,    :string
        
        timestamps()
    end
  end
end
