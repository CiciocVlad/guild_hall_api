defmodule GuildHall.PTODays do
  @moduledoc """
  The PTODays context.
  """

  @max_backend_results 2500

  import Ecto.Query, warn: false
  alias GuildHall.Repo

  alias GuildHall.PTODays.PTO

  def list_pto do
    Repo.all(PTO)
  end

  def get_pto!(id), do: Repo.get!(PTO, id)

  def get_pto_of_user(user_id) do
    from(
      pto in PTO,
      where: pto.user_id == ^user_id
    )
    |> Repo.all()
  end

  def create_pto(attrs \\ %{}) do
    %PTO{}
    |> PTO.changeset_for_create(attrs)
    |> Repo.insert()
  end

  def update_pto(%PTO{} = pto, attrs) do
    pto
    |> PTO.changeset_for_update(attrs)
    |> Repo.update()
  end

  def delete_pto(%PTO{} = pto) do
    Repo.delete(pto)
  end

  @spec get_pto_for_user_email_and_year(user_email :: binary(), year :: non_neg_integer()) ::
          map() | nil
  def get_pto_for_user_email_and_year(user_email, year) do
    from(
      pto in PTO,
      join: u in assoc(pto, :user),
      where: u.email == ^user_email and pto.year == ^year,
      select: pto
    )
    |> Repo.one()
  end

  @spec get_past_pto_for_user_email(user_email :: binary()) :: map() | nil
  def get_past_pto_for_user_email(user_email) do
    current_year = DateTime.utc_now() |> DateTime.to_date() |> Map.get(:year)

    from(
      pto in PTO,
      join: u in assoc(pto, :user),
      where: u.email == ^user_email and pto.year != ^current_year,
      select: %{days: pto.days, year: pto.year}
    )
    |> Repo.all()
  end

  defp count_days(%{start_date: start_date, end_date: end_date}) do
    Date.diff(end_date, start_date) + 1
  end

  defp count_working_days(%{start_date: start_date, end_date: end_date}, year, legal_holidays) do
    Date.range(start_date, end_date)
    |> Enum.into([])
    |> Enum.reject(fn date -> date.year != year or Date.day_of_week(date) > 5 end)
    |> MapSet.new()
    |> MapSet.difference(legal_holidays)
    |> Enum.count()
  end

  defp days_set(%{start_date: start_date, end_date: end_date}) do
    Date.range(start_date, end_date)
    |> Enum.into([])
    |> MapSet.new()
  end

  defp days_set(intervals) when is_list(intervals) do
    intervals
    |> Enum.map(&days_set/1)
    |> Enum.reduce(MapSet.new(), &MapSet.union/2)
  end

  defp backend_list(filters, opts) do
    backend = opts[:backend] || Application.fetch_env!(:guild_hall, :pto_backend)

    filters
    |> backend.list()
  end

  @spec get_yearly_status(user_email :: binary(), year :: non_neg_integer(), opts :: keyword()) ::
          {:ok,
           %{
             nominal: integer(),
             extra: integer(),
             taken: integer(),
             remaining: integer(),
             details: [
               %{
                 start_date: Date.t(),
                 end_date: Date.t(),
                 working_days: non_neg_integer(),
                 summary: binary()
               }
             ]
           }}
          | {:error, term()}
  def get_yearly_status(user_email, year, opts \\ []) do
    filters = [
      start_date: Date.new!(year, 1, 1),
      end_date: Date.new!(year, 12, 31),
      max_results: @max_backend_results
    ]

    with {:get_pto_record, %PTO{} = pto_record} <-
           {:get_pto_record, get_pto_for_user_email_and_year(user_email, year)},
         {:get_legal, {:ok, legal_holidays}} <-
           {:get_legal, backend_list(Keyword.merge(filters, type: :legal), opts)},
         {:get_taken, {:ok, taken}} <-
           {:get_taken,
            backend_list(Keyword.merge(filters, type: :pto, creator_email: user_email), opts)},
         {:get_extra, {:ok, extra}} <-
           {:get_extra,
            backend_list(Keyword.merge(filters, type: :extra, creator_email: user_email), opts)},
         {:get_bonus, {:ok, bonus}} <-
           {:get_bonus,
            backend_list(
              Keyword.merge(filters, type: :bonus_pto, creator_email: user_email),
              opts
            )} do
      legal_holidays_set =
        legal_holidays
        |> days_set()

      taken =
        taken
        |> Enum.map(fn item ->
          Map.put(item, :working_days, count_working_days(item, year, legal_holidays_set))
        end)

      extra_days =
        extra
        |> Enum.map(&count_days/1)
        |> Enum.sum()

      taken_days =
        taken
        |> Enum.map(fn %{working_days: days} -> days end)
        |> Enum.sum()

      details =
        taken
        |> Enum.map(&Map.take(&1, [:start_date, :end_date, :summary, :working_days]))

      add_days =
        extra |> Enum.map(fn item -> item |> Map.put(:working_days, count_days(item)) end)

      add_days =
        add_days |> Enum.map(&Map.take(&1, ~w[start_date end_date summary working_days]a))

      bonus_days =
        bonus |> Enum.map(fn item -> item |> Map.put(:working_days, count_days(item)) end)

      bonus_days =
        bonus_days |> Enum.map(&Map.take(&1, ~w[start_date end_date summary working_days]a))

      {:ok,
       %{
         nominal: pto_record.days,
         extra: extra_days,
         taken: taken_days,
         remaining: pto_record.days + extra_days - taken_days,
         add_days: add_days,
         bonus_days: bonus_days,
         details: details
       }}
    else
      {type, {:error, error}} -> {:error, {type, error}}
      {:get_pto_record, nil} -> {:error, {:get_pto_record, "nominal PTO record not found"}}
    end
  end

  @doc """
  List the users that have paid time off set for the given date.

  Returns a map with the user email as key and the interval as value.
  If there are more than one intervals one is chosen randomly.
  """
  @spec get_daily_status(date :: Date.t(), opts :: keyword()) ::
          {:ok,
           %{
             binary() => %{
               optional(:summary) => binary(),
               optional(:creator_email) => binary(),
               start_date: Date.t(),
               end_date: Date.t()
             }
           }}
          | {:error, term()}
  def get_daily_status(date, opts \\ []) do
    filters = [
      start_date: date,
      end_date: date,
      max_results: @max_backend_results
    ]

    with {:get_taken, {:ok, taken}} <-
           {:get_taken, backend_list(Keyword.merge(filters, type: :pto), opts)},
         {:get_bonus, {:ok, bonus}} <-
           {:get_bonus, backend_list(Keyword.merge(filters, type: :bonus_pto), opts)} do
      merged =
        taken
        |> Kernel.++(bonus)
        |> Enum.map(fn item ->
          {item[:creator_email],
           Map.take(item, [:start_date, :end_date, :creator_email, :summary])}
        end)
        |> Enum.into(%{})

      {:ok, merged}
    else
      {type, {:error, error}} -> {:error, {type, error}}
    end
  end
end
