defmodule Skoller.Organizations.IntensityScore do
  defmodule DateEntry do
    defstruct assgn_count: 0, c_weights: 0
  end

  defmodule ScoreEntry do
    defstruct [:day, score_7: %DateEntry{}, score_14: %DateEntry{}, score_30: %DateEntry{}]
  end

  def create_intensity_scores(assignments, time_zone) do
    today = DateTime.utc_now() |> Timex.to_datetime(time_zone) |> DateTime.to_date()

    assignment_days =
      assignments
      |> Enum.filter(&valid_assignment?(&1, today))
      |> Enum.reduce(%{}, fn %{due: due, relative_weight: weight}, acc ->
        key = DateTime.to_date(due)

        new_entry =
          case Map.get(acc, key) do
            nil ->
              %DateEntry{assgn_count: 1, c_weights: weight}

            %DateEntry{c_weights: c_weights, assgn_count: assgn_count} ->
              %DateEntry{assgn_count: assgn_count + 1, c_weights: Decimal.add(c_weights, weight)}
          end

        Map.put(acc, key, new_entry)
      end)
      |> Map.put_new(today, %DateEntry{})

    intensity_scores =
      assignment_days
      |> Map.keys()
      |> Task.async_stream(&generate_outlooks(&1, assignment_days))
      |> Enum.map(fn
        {:ok, result} -> result
        {:error, _} -> raise "Intensity score timeout"
      end)

    current_day = Enum.find(intensity_scores, &(&1.day == today))

    intensity_scores
    |> Enum.reduce(%ScoreEntry{}, &percentile(&1, &2, current_day))
    |> Map.drop([:day, :__struct__])
    |> Enum.map(&calc_intensity_score/1)
    |> Map.new()
  rescue
    err ->
      require Logger
      Logger.error("#{inspect(err)}")
      nil
  end

  defp valid_assignment?(%{due: due, weight: weight}, _today) when is_nil(due) or is_nil(weight),
    do: false

  defp valid_assignment?(%{due: due}, today),
    do: Date.compare(today, DateTime.to_date(due)) != :lt

  defp generate_outlooks(due_date, assignment_days) do
    days =
      for i <- 0..29 do
        new_day = Date.add(due_date, i)
        assignment_days[new_day]
      end

    slice_7 =
      days
      |> Enum.slice(0, 7)
      |> Enum.reduce(%DateEntry{}, &reduce_slice/2)

    slice_14 =
      days
      |> Enum.slice(7, 7)
      |> Enum.reduce(slice_7, &reduce_slice/2)

    slice_30 =
      days
      |> Enum.slice(14, 16)
      |> Enum.reduce(slice_14, &reduce_slice/2)

    %ScoreEntry{
      day: due_date,
      score_7: slice_7,
      score_14: slice_14,
      score_30: slice_30
    }
  end

  defp reduce_slice(%{assgn_count: da_cnt, c_weights: dw}, %{assgn_count: ta_cnt, c_weights: tw}),
    do: %DateEntry{
      assgn_count: da_cnt + ta_cnt,
      c_weights: Decimal.add(dw, tw)
    }

  defp reduce_slice(nil, acc), do: acc

  defp percentile(day_scores, score_acc, current_day) do
    day_scores
    |> Map.drop([:day, :__struct__])
    |> Enum.reduce(score_acc, fn {key, val}, acc ->
      a_count =
        Map.get(acc, key).assgn_count +
          eval_percentile_add(val.assgn_count, Map.get(current_day, key).assgn_count)

      w_count =
        Map.get(acc, key).c_weights +
          eval_percentile_add(val.c_weights, Map.get(current_day, key).c_weights)

      new_acc_val = %DateEntry{
        assgn_count: a_count,
        c_weights: w_count
      }

      Map.put(acc, key, new_acc_val)
    end)
  end

  defp eval_percentile_add(new_val, existing_val)
       when is_integer(new_val) and is_integer(existing_val) do
    cond do
      new_val == existing_val -> 0.5
      new_val < existing_val -> 1
      new_val > existing_val -> 0
    end
  end

  defp eval_percentile_add(new_val, existing_val) do
    cond do
      Decimal.equal?(new_val, existing_val) -> 0.5
      Decimal.lt?(new_val, existing_val) -> 1
      Decimal.gt?(new_val, existing_val) -> 0
    end
  end

  defp calc_intensity_score({key, %{assgn_count: a_count, c_weights: c_count}}),
    do: {key, round(:math.sqrt((a_count + c_count) / 200) * 100) / 10}
end
