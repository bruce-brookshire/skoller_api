defmodule SkollerWeb.Api.V1.Organization.OrgStudentController do
  alias Skoller.Organizations.OrgStudents
  alias SkollerWeb.Organization.OrgStudentView

  use SkollerWeb.Controller, adapter: OrgStudents, view: OrgStudentView
end
