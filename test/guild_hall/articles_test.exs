defmodule GuildHall.ArticlesTest do
  use GuildHall.DataCase

  alias GuildHall.Articles
  alias GuildHall.Factory

  describe "articles" do
    alias GuildHall.Articles.Article

    @valid_attrs %{link: "some link"}
    @update_attrs %{link: "some updated link"}
    @invalid_attrs %{link: nil}

    def article_fixture(attrs \\ %{}) do
      {:ok, article} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Articles.create_article()

      article
    end

    test "list_articles/0 returns all articles" do
      user = Factory.insert(:user)
      article = article_fixture(%{user_id: user.id})
      assert Articles.list_articles() == [article]
    end

    test "get_article!/1 returns the article with given id" do
      user = Factory.insert(:user)
      article = article_fixture(%{user_id: user.id})
      assert Articles.get_article!(article.id) == article
    end

    test "create_article/1 with valid data creates a article" do
      user = Factory.insert(:user)

      assert {:ok, %Article{} = article} =
               Articles.create_article(@valid_attrs |> Enum.into(%{user_id: user.id}))

      assert article.link == "some link"
    end

    test "create_article/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Articles.create_article(@invalid_attrs)
    end

    test "update_article/2 with valid data updates the article" do
      user = Factory.insert(:user)
      article = article_fixture(%{user_id: user.id})
      assert {:ok, %Article{} = article} = Articles.update_article(article, @update_attrs)
      assert article.link == "some updated link"
    end

    test "update_article/2 with invalid data returns error changeset" do
      user = Factory.insert(:user)
      article = article_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = Articles.update_article(article, @invalid_attrs)
      assert article == Articles.get_article!(article.id)
    end

    test "delete_article/1 deletes the article" do
      user = Factory.insert(:user)
      article = article_fixture(%{user_id: user.id})
      assert {:ok, %Article{}} = Articles.delete_article(article)
      assert_raise Ecto.NoResultsError, fn -> Articles.get_article!(article.id) end
    end

    test "change_article/1 returns a article changeset" do
      user = Factory.insert(:user)
      article = article_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = Articles.change_article(article)
    end
  end
end
