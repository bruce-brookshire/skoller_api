defmodule Skoller.SkollerJobs.JobProfileStatus do
  use Ecto.Schema

  schema "job_profile_statuses" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.EthnicityType do
  use Ecto.Schema

  schema "ethnicity_types" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.CareerActivityType do
  use Ecto.Schema

  schema "career_activity_types" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.DegreeType do
  use Ecto.Schema

  schema "degree_types" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.JobSearchType do
  use Ecto.Schema

  schema "job_search_types" do
    field :name, :string
  end
end
