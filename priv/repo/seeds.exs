# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Skoller.Repo.insert!(%Skoller.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Skoller.Repo.insert!(%Skoller.Role{id: 100, name: "Student"})
Skoller.Repo.insert!(%Skoller.Role{id: 200, name: "Admin"})
Skoller.Repo.insert!(%Skoller.Role{id: 300, name: "Syllabus Worker"})
Skoller.Repo.insert!(%Skoller.Role{id: 400, name: "Change Requests"})

Skoller.Repo.insert!(%Skoller.Classes.Status{id: 200, name: "Needs Syllabus", is_complete: false})
Skoller.Repo.insert!(%Skoller.Classes.Status{id: 300, name: "Weights", is_complete: false})
Skoller.Repo.insert!(%Skoller.Classes.Status{id: 400, name: "Assignments", is_complete: false})
Skoller.Repo.insert!(%Skoller.Classes.Status{id: 500, name: "Review", is_complete: false})
Skoller.Repo.insert!(%Skoller.Classes.Status{id: 600, name: "Help", is_complete: false})
Skoller.Repo.insert!(%Skoller.Classes.Status{id: 700, name: "Complete", is_complete: true})
Skoller.Repo.insert!(%Skoller.Classes.Status{id: 800, name: "Change", is_complete: true})

Skoller.Repo.insert!(%Skoller.Class.Help.Type{id: 100, name: "This is the wrong syllabus"})
Skoller.Repo.insert!(%Skoller.Class.Help.Type{id: 200, name: "This syllabus is confusing"})
Skoller.Repo.insert!(%Skoller.Class.Help.Type{id: 300, name: "Issues viewing the file"})
Skoller.Repo.insert!(%Skoller.Class.Help.Type{id: 400, name: "Other"})

Skoller.Repo.insert!(%Skoller.Class.Change.Type{id: 100, name: "Grade Scale"})
Skoller.Repo.insert!(%Skoller.Class.Change.Type{id: 200, name: "Weights"})
Skoller.Repo.insert!(%Skoller.Class.Change.Type{id: 300, name: "Professor Info"})

Skoller.Repo.insert!(%Skoller.Assignment.Mod.Type{id: 100, name: "Name"})
Skoller.Repo.insert!(%Skoller.Assignment.Mod.Type{id: 200, name: "Weight Category"})
Skoller.Repo.insert!(%Skoller.Assignment.Mod.Type{id: 300, name: "Due Date"})
Skoller.Repo.insert!(%Skoller.Assignment.Mod.Type{id: 400, name: "New Assignment"})
Skoller.Repo.insert!(%Skoller.Assignment.Mod.Type{id: 500, name: "Delete Assignment"})

Skoller.Repo.insert!(%Skoller.Class.Lock.Section{id: 100, name: "Weights", is_diy: true})
Skoller.Repo.insert!(%Skoller.Class.Lock.Section{id: 200, name: "Assignments", is_diy: true})
Skoller.Repo.insert!(%Skoller.Class.Lock.Section{id: 300, name: "Review", is_diy: false})

pass = Comeonin.Bcrypt.add_hash("IGxs1Px9BY1x")
user = Skoller.Repo.insert!(%Skoller.Users.User{email: "dev_admin@skoller.co", 
                              password_hash: pass.password_hash})
Skoller.Repo.insert!(%Skoller.UserRole{user_id: user.id, role_id: 200})
Skoller.Repo.insert!(%Skoller.UserRole{user_id: user.id, role_id: 300})
