defmodule GuildHallWeb.PTOView do
  use GuildHallWeb, :view
  alias GuildHallWeb.PTOView

  def render("index.json", %{pto_days: pto_days}), do: render_many(pto_days, PTOView, "pto.json")

  def render("show.json", %{pto: pto}), do: render_one(pto, PTOView, "pto.json")

  def render("pto.json", %{pto: pto}), do: pto |> Map.from_struct() |> Map.take(~w[days year]a)
end
