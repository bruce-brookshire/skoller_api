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

Skoller.Repo.insert!(%Skoller.Roles.Role{id: 100, name: "Student"})
Skoller.Repo.insert!(%Skoller.Roles.Role{id: 200, name: "Admin"})
Skoller.Repo.insert!(%Skoller.Roles.Role{id: 300, name: "Syllabus Worker"})
Skoller.Repo.insert!(%Skoller.Roles.Role{id: 400, name: "Change Requests"})
Skoller.Repo.insert!(%Skoller.Roles.Role{id: 500, name: "Help Requests"})

Skoller.Repo.insert!(%Skoller.HelpRequests.Type{id: 100, name: "This is the wrong syllabus"})
Skoller.Repo.insert!(%Skoller.HelpRequests.Type{id: 300, name: "Issues viewing the file"})

Skoller.Repo.insert!(%Skoller.ChangeRequests.Type{id: 100, name: "Grade Scale"})
Skoller.Repo.insert!(%Skoller.ChangeRequests.Type{id: 200, name: "Weights"})
Skoller.Repo.insert!(%Skoller.ChangeRequests.Type{id: 300, name: "Professor Info"})
Skoller.Repo.insert!(%Skoller.ChangeRequests.Type{id: 400, name: "Class Info"})

Skoller.Repo.insert!(%Skoller.Mods.Type{id: 100, name: "Name"})
Skoller.Repo.insert!(%Skoller.Mods.Type{id: 200, name: "Weight Category"})
Skoller.Repo.insert!(%Skoller.Mods.Type{id: 300, name: "Due Date"})
Skoller.Repo.insert!(%Skoller.Mods.Type{id: 400, name: "New Assignment"})
Skoller.Repo.insert!(%Skoller.Mods.Type{id: 500, name: "Delete Assignment"})

Skoller.Repo.insert!(%Skoller.Locks.Section{id: 100, name: "Weights", is_diy: true})
Skoller.Repo.insert!(%Skoller.Locks.Section{id: 200, name: "Assignments", is_diy: true})

pass = Skoller.Services.Authentication.hash_password("IGxs1Px9BY1x")
user = Skoller.Repo.insert!(%Skoller.Users.User{email: "dev_admin@skoller.co", 
                              password_hash: pass.password_hash})
Skoller.Repo.insert!(%Skoller.UserRoles.UserRole{user_id: user.id, role_id: 200})
Skoller.Repo.insert!(%Skoller.UserRoles.UserRole{user_id: user.id, role_id: 300})

Skoller.Repo.insert!(%Skoller.StudentRequests.Type{id: 100, name: "The wrong syllabus has been uploaded for this class"})
Skoller.Repo.insert!(%Skoller.StudentRequests.Type{id: 200, name: "Need to submit an additional/revised assignment schedule"})
Skoller.Repo.insert!(%Skoller.StudentRequests.Type{id: 300, name: "Other"})

Skoller.Repo.insert!(%Skoller.Chats.Algorithm{id: 100, name: "Hot"})
Skoller.Repo.insert!(%Skoller.Chats.Algorithm{id: 200, name: "Most Recent"})
Skoller.Repo.insert!(%Skoller.Chats.Algorithm{id: 300, name: "Top from the past 24 hours"})
Skoller.Repo.insert!(%Skoller.Chats.Algorithm{id: 400, name: "Top from the past week"})
Skoller.Repo.insert!(%Skoller.Chats.Algorithm{id: 500, name: "Top from the semester"})

Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "auto_upd_enroll_thresh", topic: "AutoUpdate", value: "5"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "auto_upd_response_thresh", topic: "AutoUpdate", value: "0.35"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "auto_upd_approval_thresh", topic: "AutoUpdate", value: "0.75"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "min_ios_version", value: "0.0.0", topic: "MinVersions"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "min_android_version", value: "0.0.0", topic: "MinVersions"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "is_diy_enabled", value: "true", topic: "FourDoor"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "is_diy_preferred", value: "false", topic: "FourDoor"})
Skoller.Repo.insert!(%Skoller.Settings.Setting{name: "is_auto_syllabus", value: "true", topic: "FourDoor"})

Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "AK", name: "Alaska"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "AL", name: "Alabama"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "AR", name: "Arkansas"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "AZ", name: "Arizona"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "CA", name: "California"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "CO", name: "Colorado"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "CT", name: "Connecticut"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "DC", name: "Washington, D.C."})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "DE", name: "Delaware"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "FL", name: "Florida"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "GA", name: "Georgia"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "HI", name: "Hawaii"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "IA", name: "Iowa"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "ID", name: "Idaho"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "IL", name: "Illinois"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "IN", name: "Indiana"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "KS", name: "Kansas"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "KY", name: "Kentucky"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "LA", name: "Louisiana"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MA", name: "Massachusetts"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MD", name: "Maryland"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "ME", name: "Maine"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MI", name: "Michigan"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MN", name: "Minnesota"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MO", name: "Missouri"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MS", name: "Mississippi"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "MT", name: "Montana"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NC", name: "North Carolina"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "ND", name: "North Dakota"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NE", name: "Nebraska"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NH", name: "New Hampshire"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NJ", name: "New Jersey"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NM", name: "New Mexico"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NV", name: "Nevada"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "NY", name: "New York"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "OH", name: "Ohio"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "OK", name: "Oklahoma"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "OR", name: "Oregon"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "PA", name: "Pennsylvania"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "RI", name: "Rhode Island"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "SC", name: "South Carolina"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "SD", name: "South Dakota"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "TN", name: "Tennessee"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "TX", name: "Texas"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "UT", name: "Utah"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "VA", name: "Virginia"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "VT", name: "Vermont"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "WA", name: "Washington"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "WI", name: "Wisconsin"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "WV", name: "West Virginia"})
Skoller.Repo.insert!(%Skoller.Locations.State{state_code: "WY", name: "Wyoming"})

Skoller.Repo.insert!(%Skoller.Assignments.ReminderNotification.Topic{id: 100, topic: "Assignment.Reminder.Today", name: "Today"})
Skoller.Repo.insert!(%Skoller.Assignments.ReminderNotification.Topic{id: 200, topic: "Assignment.Reminder.Tomorrow", name: "Tomorrow"})
Skoller.Repo.insert!(%Skoller.Assignments.ReminderNotification.Topic{id: 300, topic: "Assignment.Reminder.Future", name: "Future"})

Skoller.Repo.insert!(%Skoller.StudentPoints.PointType{name: "Class Referral", value: 100})
Skoller.Repo.insert!(%Skoller.StudentPoints.PointType{name: "Student Referral", value: 100})

Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
  id: 100,
  name: "No Classes Email",
  send_time: "09:00:00",
  category: "Class.None"
})
Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
  id: 200,
  name: "Class Setup Email",
  send_time: "09:00:00",
  category: "Class.Setup"
})
Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
  id: 300,
  name: "1000 Points Email",
  category: "Points.1Thousand"
})