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

Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 100, name: "Submitted", is_editable: true, is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 200, name: "Working", is_editable: false, is_complete: false})
Classnavapi.Repo.insert!(%Classnavapi.Class.Status{id: 300, name: "Complete", is_editable: false, is_complete: true})