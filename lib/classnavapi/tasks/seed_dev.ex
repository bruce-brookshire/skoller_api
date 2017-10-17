defmodule Mix.Tasks.Seed.Dev do
  use Mix.Task
  import Mix.Ecto

  alias Classnavapi.Repo

  def run(_) do
    ensure_started(Repo, [])
    Repo.insert!(%Classnavapi.User{email: "tyler@fortyau.com", password: "test"})
    Repo.insert!(%Classnavapi.School{name: "Hard Knocks University",
                                    timezone: "CST",
                                    email_domains: [
                                      %Classnavapi.School.EmailDomain{
                                        email_domain: "@hku.edu",
                                        is_professor_only: false
                                      }
                                    ],
                                    adr_zip: "37201",
                                    adr_state: "TN",
                                    adr_line_1: "530 Church St",
                                    adr_city: "Nashville",
                                    is_active: true,
                                    is_editable: true})
  end
end