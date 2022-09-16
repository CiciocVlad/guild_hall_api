defmodule GuildHall.PTODays.PTOBackendGoogleCalendar do
  @moduledoc """
  The PTODays Google Calendar backend.
  """

  alias GuildHall.PTODays.Backend

  @behaviour Backend

  defp get_and_validate_config!(filters) do
    (filters[:config] || get_config_from_application_env())
    |> validate_config!()
  end

  defp module_name() do
    __MODULE__
    |> Atom.to_string()
    |> then(fn string -> Regex.replace(~r/^Elixir\./, string, "") end)
  end

  defp validate_config!(config) do
    if is_nil(config[:base_url]) or config[:base_url] == "" do
      raise ArgumentError,
            """
            Missing :base_url for #{module_name()}; please configure it, for example:

            \tconfig app_name, #{module_name()},
            \t    base_url: "https://www.googleapis.com/calendar/v3/calendars"
            """
    end

    uri = URI.parse(config[:base_url])

    if is_nil(uri.scheme) or is_nil(uri.host) do
      raise ArgumentError,
            """
            Cannot use the :base_url set for #{module_name()}: '#{config[:base_url]}'

            \tPlease set it to a full URL, including the scheme, for example:

            \tconfig app_name, #{module_name()},
            \t    base_url: "https://www.googleapis.com/calendar/v3/calendars"
            """
    end

    if is_nil(config[:time_zone]) or config[:time_zone] == "" do
      raise ArgumentError,
            """
            Missing or empty :time_zone for #{module_name()}; please configure it, for example:

            \tconfig app_name, #{module_name()},
            \t    time_zone: "Europe/Bucharest"
            """
    end

    if is_nil(config[:calendars]) or Enum.empty?(config[:calendars]) do
      raise ArgumentError,
            """
            Missing or empty :calendars for #{module_name()}; please configure it, for example:

            \tconfig app_name, #{module_name()},
            \t    calendars: %{
            \t        legal: "ro.romanian.official%23holiday%40group.v.calendar.google.com",
            \t        pto: "pto-calendar-id",
            \t        bonus_pto: "bonus-pto-calendar-id",
            \t        extra: "extra-days-calendar-id"
            \t    }
            """
    end

    config
  end

  defp get_config_from_application_env() do
    Application.fetch_env!(:guild_hall, __MODULE__)
  end

  defp build_calendar_url!(filters, config) do
    if is_nil(filters[:type]) or filters[:type] == "" do
      raise ArgumentError, "Must set a :type filter"
    end

    calendar_url_part =
      config
      |> Kernel.get_in([:calendars, filters[:type]])

    if is_nil(calendar_url_part) do
      raise ArgumentError, "Results type '#{inspect(filters[:type])}' is not supported"
    end

    # doc says timeMin and timeMax filters are exclusive and that milliseconds are ignored
    # so using (beginning of day for start_date) and (beginning of next day for end_date)
    # https://developers.google.com/calendar/api/v3/reference/events/list

    params =
      filters
      |> Keyword.take([:start_date, :end_date, :max_results])
      |> Enum.map(fn
        {:start_date, date} ->
          {"timeMin",
           date
           |> DateTime.new!(~T[00:00:00], config[:time_zone])
           |> DateTime.to_iso8601()}

        {:end_date, date} ->
          {"timeMax",
           date
           |> Date.add(1)
           |> DateTime.new!(~T[00:00:00], config[:time_zone])
           |> DateTime.to_iso8601()}

        {:max_results, value} ->
          {"maxResults", to_string(value)}
      end)
      # return instances of recurring events, not the recurring events themselves
      |> Enum.into(%{"singleEvents" => "true"})

    calendar_base_uri =
      config[:base_url]
      |> URI.parse()

    calendar_base_uri
    |> URI.merge(Enum.join([calendar_base_uri.path, calendar_url_part, "events"], "/"))
    |> Map.put(:query, URI.encode_query(params))
    |> to_string()
  end

  defp filter_by_email(items, filters) do
    case Keyword.fetch(filters, :creator_email) do
      {:ok, value} ->
        Enum.filter(items, fn item -> Kernel.get_in(item, ["creator", "email"]) == value end)

      :error ->
        items
    end
  end

  defp parse_date_time!(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, result, _offset} ->
        result

      {:error, error} ->
        raise(
          ArgumentError,
          "cannot parse \"#{datetime}\" as datetime, reason: #{inspect(error)}"
        )
    end
  end

  defp parse_item!(item) do
    %{
      start_date: Kernel.get_in(item, ["start", "date"]) |> Date.from_iso8601!(),
      # the end date in the Google Calendar API is exclusive
      end_date: Kernel.get_in(item, ["end", "date"]) |> Date.from_iso8601!() |> Date.add(-1),
      summary: Map.get(item, "summary"),
      created_at: item |> Map.get("created") |> parse_date_time!(),
      updated_at: item |> Map.get("updated") |> parse_date_time!(),
      creator_email: Kernel.get_in(item, ["creator", "email"])
    }
  end

  defp filter_legal_holidays(items, filters) do
    case Keyword.fetch(filters, :type) do
      {:ok, :legal} ->
        Enum.reject(items, fn item ->
          case Map.fetch(item, "summary") do
            {:ok, value} when is_binary(value) ->
              upcased =
                value
                |> String.upcase()

              String.contains?(upcased, "SECTORUL PUBLIC") or
                String.contains?(upcased, "AJUNUL CRĂCIUNULUI") or
                String.contains?(upcased, "AJUNUL CRACIUNULUI")

            _ ->
              false
          end
        end)

      _ ->
        items
    end
  end

  defp reject_datetime_items(items) do
    Enum.reject(items, fn item -> is_nil(Kernel.get_in(item, ["start", "date"])) end)
  end

  defp parse_filter_items(items, filters) do
    try do
      result =
        items
        |> reject_datetime_items()
        |> filter_by_email(filters)
        |> filter_legal_holidays(filters)
        |> Enum.map(&parse_item!/1)

      {:ok, result}
    rescue
      e ->
        {:error, e}
    end
  end

  @doc """
  Lists the holidays based on filters.

  Uses the Google Calendar API v3 - the list calendar events method.
  https://developers.google.com/calendar/api/v3/reference/events/list

  Returns an inclusive end date (as opposed to the Google Calendar that
  returns an exclusive one).
  """

  @impl Backend
  @spec list(filters :: Backend.list_filters()) :: Backend.list_result()
  def list(filters) do
    config = get_and_validate_config!(filters)

    calendar_url = build_calendar_url!(filters, config)

    with {:get_token, {:ok, %{token: token}}} <-
           {:get_token, Goth.Token.for_scope("https://www.googleapis.com/auth/calendar")},
         {:get_calendar_data, {:ok, %{body: body, status_code: 200}}} <-
           {:get_calendar_data, HTTPoison.get(calendar_url, authorization: "Bearer #{token}")},
         {:json_decode_data, {:ok, data}} <- {:json_decode_data, Jason.decode(body)},
         {:get_calendar_items, {:ok, items}} <- {:get_calendar_items, Map.fetch(data, "items")},
         {:parse_filter_items, {:ok, to_return}} <-
           {:parse_filter_items, parse_filter_items(items, filters)} do
      {:ok, to_return}
    else
      {:get_calendar_data, {:ok, %HTTPoison.Response{status_code: code, body: body}}} ->
        {:error,
         {:get_calendar_data,
          "Could not retrieve calendar data: status code #{code} != 200, response = '#{body}'"}}

      {:get_calendar_items, :error} ->
        {:error, {:get_calendar_items, "The calendar response is missing the 'items' field"}}

      {step, {:error, error}} ->
        {:error, {step, error}}
    end
  end
end
