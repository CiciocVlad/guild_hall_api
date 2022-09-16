defmodule GuildHall.PTODays.Backend do
  @type filter_item ::
          {:creator_email, binary()}
          | {:start_date, Date.t()}
          | {:end_date, Date.t()}
          | {:max_results, non_neg_integer()}
          | {:type, :pto | :bonus_pto | :extra | :legal}
  @type result_item :: %{
          start_date: Date.t(),
          end_date: Date.t(),
          creator_email: binary() | nil,
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          summary: binary()
        }

  @type list_filters :: keyword(filter_item())
  @type list_result :: {:ok, list(result_item())} | {:error, term()}

  @callback list(filters :: list_filters()) :: list_result()
end
