defmodule SkollerWeb.Api.V1.Organization.OrgGroupStudentController do
  alias Skoller.Organizations.OrgGroupStudents
  alias SkollerWeb.Organization.OrgGroupStudentView

  use SkollerWeb.Controller, adapter: OrgGroupStudents, view: OrgGroupStudentView
end
