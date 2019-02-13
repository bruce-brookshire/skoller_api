defmodule Skoller.Repo.Migrations.ConvertClassTimes do
  use Ecto.Migration

  def up do
    alter table(:classes) do
      add :meet_start_time_temp, :time
      add :meet_end_time_temp, :time
    end

    flush()

    %{rows: classes} = Ecto.Adapters.SQL.query!(Skoller.Repo, "SELECT id, meet_start_time, meet_end_time FROM classes")
    Enum.each(classes, fn class ->
      IO.inspect("Updating Class " <> Enum.at(class, 0))
      # Start times
      time = Enum.at(class, 1)
      IO.inspect("Updating Start Time " <> time)
      if(time != nil) do
        time = if(String.length(time) < 8) do
          parts = String.split(time, ":")
          interim_s = Enum.reduce(parts, "", fn x, acc -> if(String.length(x) == 1)  do acc <> "0" <> x <> ":" else acc <> x <> ":" end end)
          String.slice(interim_s, 0..-2)
        else
          time
        end
        time_resp = Time.from_iso8601(time)
        case time_resp do
          {:ok, time} ->
            query = "UPDATE classes SET meet_start_time_temp='" <> Time.to_iso8601(time) <> "' WHERE id=" <> Integer.to_string(Enum.at(class, 0))
            Ecto.Adapters.SQL.query!(Skoller.Repo, query)
          _ ->
            IO.inspect("FAILURE START")
            IO.inspect(time)
            IO.inspect(time_resp)
        end
      end
      # End times
      time = Enum.at(class, 2)
      IO.inspect("Updating End Time " <> time)
      if(time != nil) do
        time = if(String.length(time) < 8) do
          parts = String.split(time, ":")
          interim_s = Enum.reduce(parts, "", fn x, acc -> if(String.length(x) == 1)  do acc <> "0" <> x <> ":" else acc <> x <> ":" end end)
          String.slice(interim_s, 0..-2)
        else
          time
        end
        time_resp = Time.from_iso8601(time)
        case time_resp do
          {:ok, time} ->
            query = "UPDATE classes SET meet_end_time_temp='" <> Time.to_iso8601(time) <> "' WHERE id=" <> Integer.to_string(Enum.at(class, 0))
            Ecto.Adapters.SQL.query!(Skoller.Repo, query)
          _ ->
            IO.inspect("FAILURE END")
            IO.inspect(time)
            IO.inspect(time_resp)
        end
      end
    end)

    flush()

    alter table(:classes) do
      remove :meet_start_time
      remove :meet_end_time
    end
    rename table(:classes), :meet_start_time_temp, to: :meet_start_time
    rename table(:classes), :meet_end_time_temp, to: :meet_end_time
  end

  def down do
    alter table(:classes) do
      add :meet_start_time_temp, :string
      add :meet_end_time_temp, :string
    end

    flush()
    
    %{rows: classes} = Ecto.Adapters.SQL.query!(Skoller.Repo, "SELECT id, meet_start_time, meet_end_time FROM classes")
    # Start Times
    Enum.each(classes, fn class ->
      time = Enum.at(class, 1)
      if(time != nil) do
        {hr, min, sec, mili} = time
        {:ok, time} = Time.new(hr, min, sec, mili)
        time =  Time.to_string(time)
        {dot_index, _length} = :binary.match(time, ".")
        dot_index = dot_index - 1
        time = String.slice(time, 0..dot_index)
        query = "UPDATE classes SET meet_start_time_temp='" <> time <> "' WHERE id=" <> Integer.to_string(Enum.at(class, 0))
        Ecto.Adapters.SQL.query!(Skoller.Repo, query)
      end
    end)
    # End Times
    Enum.each(classes, fn class ->
      time = Enum.at(class, 2)
      if(time != nil) do
        {hr, min, sec, mili} = time
        {:ok, time} = Time.new(hr, min, sec, mili)
        time =  Time.to_string(time)
        {dot_index, _length} = :binary.match(time, ".")
        dot_index = dot_index - 1
        time = String.slice(time, 0..dot_index)
        query = "UPDATE classes SET meet_end_time_temp='" <> time <> "' WHERE id=" <> Integer.to_string(Enum.at(class, 0))
        Ecto.Adapters.SQL.query!(Skoller.Repo, query)
      end
    end)

    flush()

    alter table(:classes) do
      remove :meet_start_time
      remove :meet_end_time
    end
    rename table(:classes), :meet_start_time_temp, to: :meet_start_time
    rename table(:classes), :meet_end_time_temp, to: :meet_end_time
  end

end
