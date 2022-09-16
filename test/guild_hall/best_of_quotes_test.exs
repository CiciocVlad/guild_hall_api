defmodule GuildHall.BestOfQuotesTest do
  use GuildHall.DataCase

  alias GuildHall.BestOfQuotes
  alias GuildHall.Factory

  describe "best_of_quotes" do
    alias GuildHall.BestOfQuotes.Quote

    @valid_attrs %{quote: "some quote"}
    @update_attrs %{quote: "some updated quote"}
    @invalid_attrs %{quote: nil}

    def quote_fixture(attrs \\ %{}) do
      {:ok, quote} =
        attrs
        |> Enum.into(@valid_attrs)
        |> BestOfQuotes.create_quote()

      quote
    end

    test "list_best_of_quotes/0 returns all best_of_quotes" do
      user = Factory.insert(:user)
      quote = quote_fixture(%{user_id: user.id})
      assert BestOfQuotes.list_quotes() == [quote]
    end

    test "get_quote!/1 returns the quote with given id" do
      user = Factory.insert(:user)
      quote = quote_fixture(%{user_id: user.id})
      assert BestOfQuotes.get_quote!(quote.id) == quote
    end

    test "create_quote/1 with valid data creates a quote" do
      user = Factory.insert(:user)

      assert {:ok, %Quote{} = quote} =
               BestOfQuotes.create_quote(@valid_attrs |> Enum.into(%{user_id: user.id}))

      assert quote.quote == "some quote"
    end

    test "create_quote/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = BestOfQuotes.create_quote(@invalid_attrs)
    end

    test "update_quote/2 with valid data updates the quote" do
      user = Factory.insert(:user)
      quote = quote_fixture(%{user_id: user.id})
      assert {:ok, %Quote{} = quote} = BestOfQuotes.update_quote(quote, @update_attrs)
      assert quote.quote == "some updated quote"
    end

    test "update_quote/2 with invalid data returns error changeset" do
      user = Factory.insert(:user)
      quote = quote_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = BestOfQuotes.update_quote(quote, @invalid_attrs)
      assert quote == BestOfQuotes.get_quote!(quote.id)
    end

    test "delete_quote/1 deletes the quote" do
      user = Factory.insert(:user)
      quote = quote_fixture(%{user_id: user.id})
      assert {:ok, %Quote{}} = BestOfQuotes.delete_quote(quote)
      assert_raise Ecto.NoResultsError, fn -> BestOfQuotes.get_quote!(quote.id) end
    end

    test "change_quote/1 returns a quote changeset" do
      user = Factory.insert(:user)
      quote = quote_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = BestOfQuotes.change_quote(quote)
    end
  end
end
