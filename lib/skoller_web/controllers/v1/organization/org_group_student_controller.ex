defmodule SkollerWeb.Api.V1.Organization.OrgGroupStudentController do
  alias Skoller.Organizations.OrgGroupStudents
  alias SkollerWeb.Organization.OrgGroupStudentView

  use ExMvc.Controller, adapter: OrgGroupStudents, view: OrgGroupStudentView
end
