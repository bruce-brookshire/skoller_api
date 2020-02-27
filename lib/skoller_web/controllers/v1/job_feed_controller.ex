defmodule SkollerWeb.Api.V1.JobFeedController do
  use SkollerWeb, :controller

  alias Skoller.JobGateListings
  alias Skoller.JobGateListings.JobGateClassification
  alias Skoller.JobGateListings.JobGateClassificationJoiner

  require Logger

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

  def create(conn, params) do
    conn
    |> put_resp_content_type("text/xml")
    |> put_resp_header(
      "content-disposition",
      ~s[attachment; filename="feed_response.xml"; filename*="feed_response.xml"]
    )
    |> send_resp(200, process_job_xml(params))
  end

  defp process_job_xml(body) do
    body
    # Extract
    |> Map.get("Jobs")
    |> Map.get("Job")
    # Preprocess
    |> Enum.map(&preprocess_job_listing/1)
    |> Enum.filter(&(&1 != nil))
    # Either get or insert classification and link relation
    |> Enum.map_reduce(%{}, &map_reduce_classifications/2)
    |> Kernel.elem(0)
    # Store
    |> Enum.map(&JobGateListings.perform_job_action/1)
    # Result
    |> Enum.map(&generate_listing_result/1)
    |> Enum.join()
    |> aggregate_body
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

  defp map_params({"AdditionalClassification1", classification}),
    do: {:classification, {classification, primary: false}}

  defp map_params({"AdditionalClassification2", classification}),
    do: {:classification, {classification, primary: false}}

  defp map_params({"AdditionalClassification3", classification}),
    do: {:classification, {classification, primary: false}}

  defp map_params({"AdditionalClassification4", classification}),
    do: {:classification, {classification, primary: false}}

  defp map_params({key, value}), do: {@job_gate_param_map[key], value}

  # Reduce job params into accumulator
  defp coalesce_job_params(nil, acc), do: acc
  defp coalesce_job_params({nil, _val}, acc), do: acc
  defp coalesce_job_params({_key, nil}, acc), do: acc
  defp coalesce_job_params({_key, []}, acc), do: acc

  defp coalesce_job_params({:classification, val}, %{classifications: vals} = acc),
    do: %{acc | classifications: [val | vals]}

  defp coalesce_job_params({key, val}, acc), do: Map.put(acc, key, val)

  defp map_reduce_classifications(%{classifications: elems} = listing, acc) do
    {new_elems, new_acc} =
      Enum.map_reduce(elems, acc, fn {elem, primary: prim}, acc ->
        case acc[elem] do
          id when is_integer(id) ->
            {
              %JobGateClassificationJoiner{job_gate_classification_id: id, is_primary: prim},
              acc
            }

          nil ->
            %{id: id} = JobGateClassification.get_or_insert(elem)

            {
              %JobGateClassificationJoiner{job_gate_classification_id: id, is_primary: prim},
              Map.put(acc, elem, id)
            }
        end
      end)

    {%{listing | classifications: new_elems}, new_acc}
  end

  defp map_reduce_classifications(listing, acc), do: {listing, acc}

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
