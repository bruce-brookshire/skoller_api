# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Classnavapi.Repo.insert!(%Classnavapi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Classnavapi.Repo.insert!(%Classnavapi.Role{id: 100, name: "Student"})
Classnavapi.Repo.insert!(%Classnavapi.Role{id: 200, name: "Admin"})
Classnavapi.Repo.insert!(%Classnavapi.Role{id: 300, name: "Syllabus Editor"})

Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 100, name: "Needs Syllabus", is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 200, name: "Weights", is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 300, name: "Assignments", is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 400, name: "Review", is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 500, name: "Help", is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 600, name: "Complete", is_complete: true})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 700, name: "Change", is_complete: true})

Classnavapi.Repo.insert!(%Classnavapi.Class.Issue.Status{id: 100, status: "Incorrect"})
Classnavapi.Repo.insert!(%Classnavapi.Class.Issue.Status{id: 200, status: "Confusing"})
Classnavapi.Repo.insert!(%Classnavapi.Class.Issue.Status{id: 300, status: "File"})
Classnavapi.Repo.insert!(%Classnavapi.Class.Issue.Status{id: 400, status: "Other"})