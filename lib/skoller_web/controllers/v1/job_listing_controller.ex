defmodule SkollerWeb.Api.V1.JobListingController do
  use SkollerWeb, :controller

  alias Skoller.JobGateListings

  @job_gate_param_map %{
    "Action" => :action,
    "AdvertiserName" => :advertiser_name,
    "AdvertiserType" => :advertiser_type,
    "ApplicationURL" => :application_url,
    "Country" => :country,
    "Description" => :description_html,
    "DescriptionURL" => :description_url,
    "EmploymentType" => :employment_type,
    "SenderReference" => :sender_reference,
    "JobSource" => :job_source,
    "JobSourceURL" => :job_source_url,
    "JobType" => :job_type,
    "Area" => :locality,
    "LogoURL" => :logo_url,
    "Position" => :position,
    "Location" => :region,
    "RevenueType" => :revenue_type,
    "SalaryAdditional" => :salary_additional,
    "SalaryCurrency" => :salary_currency,
    "SalaryMaximum" => :salary_maximum,
    "SalaryMinimum" => :salary_minimum,
    "SalaryPeriod" => :salary_period,
    "SellPrice" => :sell_price,
    "StartDate" => :start_date,
    "WorkHours" => :work_hours
  }

  def show(conn, _) do
    case File.read("big_test.xml") do
      {:ok, contents} ->
        results =
          contents
          # Extract
          |> XmlToMap.naive_map()
          |> Map.get("Jobs")
          |> Map.get("Job")
          # Preprocess
          |> Enum.map(&preprocess_job_listing/1)
          |> Enum.filter(&(&1 != nil))
          # Store
          |> Enum.map(&JobGateListings.perform_job_action/1)
          # Result
          |> Enum.map(&generate_listing_result/1)
          |> Enum.join()
          |> aggregate_body

        File.write("result.xml", results)

        conn |> send_resp(200, "<!DOCTYPE html><html lang=\"en\">" <> results <> "</html>")

      _ ->
        conn |> send_resp(422, "")
    end
  end

  defp preprocess_job_listing(%{} = listing),
    do:
      listing
      |> Enum.map(&map_params/1)
      |> Enum.reduce(%{classifications: []}, &coalesce_job_params/2)

  defp preprocess_job_listing(_), do: nil

  defp map_params({_key, value}) when not is_binary(value), do: nil

  defp map_params({"Classification", classification}),
    do: {:classification, {classification, primary: true}}

  defp map_params({"AdditionalClassification1", {classification, primary: false}}),
    do: {:classification, classification}

  defp map_params({"AdditionalClassification2", {classification, primary: false}}),
    do: {:classification, classification}

  defp map_params({"AdditionalClassification3", {classification, primary: false}}),
    do: {:classification, classification}

  defp map_params({"AdditionalClassification4", {classification, primary: false}}),
    do: {:classification, classification}

  defp map_params({key, value}), do: {@job_gate_param_map[key], value}

  # Reduce job params into accumulator
  defp coalesce_job_params(nil, acc), do: acc
  defp coalesce_job_params({nil, _val}, acc), do: acc
  defp coalesce_job_params({_key, nil}, acc), do: acc
  defp coalesce_job_params({_key, []}, acc), do: acc

  defp coalesce_job_params({:classification, val}, %{classifications: vals} = acc),
    do: %{acc | classifications: [val | vals]}

  defp coalesce_job_params({key, val}, acc), do: Map.put(acc, key, val)

  defp generate_listing_result(%{
         sender_reference: sender_reference,
         message: message,
         success: success
       }),
       do: """
         <Job>
           <SenderReference>#{sender_reference}</SenderReference>
           <Successful>#{if(success, do: "True", else: "False")}</Successful>
           <Message>#{message}</Message>
         </Job>
       """

  defp generate_listing_result(_), do: ""

  defp aggregate_body(body), do: "<Jobs>\n" <> body <> "</Jobs>"
end
