defmodule GuildHall.Factory do
  @moduledoc """
  ExMachina based test data factory.
  """

  use ExMachina.Ecto, repo: GuildHall.Repo

  alias GuildHall.Users.User
  alias GuildHall.PTODays.PTO
  alias GuildHall.Categories.Category
  alias GuildHall.Attributes.Attribute
  alias GuildHall.UsersAttributes.UserAttribute
  alias GuildHall.Projects.Project
  alias GuildHall.Roles.Role
  alias GuildHall.UsersProjects.UserProject

  def user_factory() do
    # one or two first names and a last name
    name =
      Enum.take_random(
        [
          Faker.Person.En.first_name(),
          Faker.Person.It.first_name(),
          Faker.Person.Fr.first_name(),
          Faker.Person.Es.first_name(),
          Faker.Person.PtBr.first_name()
        ],
        Enum.random(1..2)
      ) ++
        Enum.take_random(
          [
            Faker.Person.En.last_name(),
            Faker.Person.It.last_name(),
            Faker.Person.Fr.last_name(),
            Faker.Person.Es.last_name(),
            Faker.Person.PtBr.last_name()
          ],
          1
        )

    slugs =
      for idx <- 4..2 do
        name
        |> Enum.take_random(idx)
        |> Kernel.++(Enum.take_random(["1", "7", "13", "33", "89", "93"], Enum.random(0..1)))
        |> Faker.Internet.slug()
      end

    joined_date = Faker.Date.backward(6 * 365)
    left_date = Date.add(joined_date, Enum.random(10..60))

    %User{
      avatar: Faker.Avatar.image_url(hd(slugs)),
      name: Enum.join(name, " "),
      bio: Faker.Lorem.paragraph(),
      email: "#{hd(slugs)}@#{Faker.Internet.free_email_service()}",
      hobbies:
        [
          Faker.Beer.name(),
          Faker.StarWars.character(),
          Faker.Team.En.name(),
          Faker.Team.PtBr.name(),
          Faker.Industry.industry(),
          Faker.Vehicle.En.make(),
          Faker.Color.En.fancy_name(),
          Faker.Food.En.ingredient()
        ]
        |> Enum.take_random(Enum.random(2..6)),
      job_title: Faker.Person.En.title_job(),
      joined_date: joined_date |> to_string(),
      left_date: left_date |> to_string(),
      phone: Faker.Phone.EnGb.mobile_number(),
      preferred_name: Enum.random(name),
      social_media:
        [
          {"facebook", "facebook.com/#{Enum.random(slugs)}"},
          {"github", "github.com/#{Enum.random(slugs)}"},
          {"pinterest", "pinterest.com/#{Enum.random(slugs)}"},
          {"linkedin", "linkedin.com/#{Enum.random(slugs)}"},
          {"twitter", "twitter.com/#{Enum.random(slugs)}"}
        ]
        |> Enum.take_random(Enum.random(1..3))
        |> Enum.into(%{}),
      is_admin: sequence(:is_admin, [true, false]),
      years_of_experience: "#{Faker.random_between(0, 15)}+",
      number_of_industries: "#{Faker.random_between(1, 5)}+",
      number_of_projects: "#{Faker.random_between(1, 20)}+"
    }
  end

  def invalid_user_factory() do
    %User{
      avatar: Faker.random_between(0, 100),
      name: Faker.random_between(0, 100),
      bio: Faker.random_between(0, 100),
      email: Faker.random_between(0, 100),
      hobbies: nil,
      job_title: Faker.random_between(0, 100),
      joined_date: Faker.Lorem.word(),
      left_date: Faker.Lorem.word(),
      phone: Faker.random_between(0, 100),
      preferred_name: Faker.random_between(0, 100),
      social_media: nil,
      is_admin: Faker.random_between(10, 100),
      years_of_experience: Faker.random_between(0, 100),
      number_of_industries: Faker.random_between(0, 100),
      number_of_projects: Faker.random_between(0, 100)
    }
  end

  def pto_factory() do
    %PTO{
      year: Date.utc_today().year - Enum.random(0..20),
      days: 21
    }
  end

  def invalid_pto_factory() do
    %PTO{
      year: "string",
      days: "21 Pilots",
      user_id: "user_id"
    }
  end

  defp sentence_case_words_with_spaces() do
    Faker.Lorem.sentence(Enum.random(1..3), "")
  end

  def category_factory() do
    %Category{
      name: sentence_case_words_with_spaces()
    }
  end

  def invalid_category_factory() do
    %Category{
      name: 123
    }
  end

  def attribute_factory() do
    %Attribute{
      name: sentence_case_words_with_spaces()
    }
  end

  def invalid_attribute_factory() do
    %Attribute{
      name: 123,
      category_id: "string"
    }
  end

  def user_attribute_factory() do
    %UserAttribute{}
  end

  def project_factory() do
    end_date = Faker.Date.backward(100)

    %Project{
      end_date: Enum.random([nil, to_string(end_date)]),
      start_date: Date.add(end_date, -Faker.random_between(0, 365 * 5)) |> to_string(),
      title: sentence_case_words_with_spaces(),
      category: sentence_case_words_with_spaces(),
      description: Faker.Lorem.paragraph()
    }
  end

  def role_factory() do
    %Role{
      title: Faker.Person.En.title_job()
    }
  end

  def user_project_factory() do
    end_date = Faker.Date.backward(100)

    %UserProject{
      end_date: Enum.random([nil, to_string(end_date)]),
      start_date: Date.add(end_date, -Faker.random_between(0, 365 * 5)) |> to_string(),
      user_impact: Faker.Lorem.sentence()
    }
  end

  def pto_backend_item_factory() do
    start_date = Faker.Date.backward(100)
    created_at = Faker.DateTime.backward(100)
    r = Faker.random_between(0, 10)

    updated_at =
      cond do
        r <= 5 -> created_at
        r <= 7 -> DateTime.add(created_at, Faker.random_between(0, 3600))
        true -> DateTime.add(created_at, Faker.random_between(3600, 3600 * 24 * 3))
      end

    %{
      start_date: start_date,
      end_date: Date.add(start_date, Faker.random_between(0, 15)),
      summary: Faker.Lorem.sentence(),
      creator_email: Faker.Internet.email(),
      created_at: created_at,
      updated_at: updated_at
    }
  end

  defp legal_holidays_in_romania(year) do
    result = [
      %{
        start_date: Date.new!(year, 1, 1),
        end_date: Date.new!(year, 1, 1),
        summary: "Anul nou"
      },
      %{
        start_date: Date.new!(year, 1, 2),
        end_date: Date.new!(year, 1, 2),
        summary: "Anul nou"
      },
      %{
        start_date: Date.new!(year, 1, 24),
        end_date: Date.new!(year, 1, 24),
        summary: "Ziua Unirii"
      },
      %{
        start_date: Date.new!(year, 5, 1),
        end_date: Date.new!(year, 5, 1),
        summary: "Ziua Muncii"
      },
      %{
        start_date: Date.new!(year, 6, 1),
        end_date: Date.new!(year, 6, 1),
        summary: "Ziua Copilului"
      },
      %{
        start_date: Date.new!(year, 8, 15),
        end_date: Date.new!(year, 8, 15),
        summary: "Adormirea Maicii Domnului"
      },
      %{
        start_date: Date.new!(year, 11, 30),
        end_date: Date.new!(year, 11, 30),
        summary: "Ziua Sfântului Andrei"
      },
      %{
        start_date: Date.new!(year, 12, 1),
        end_date: Date.new!(year, 12, 1),
        summary: "Ziua națională"
      },
      %{
        start_date: Date.new!(year, 12, 24),
        end_date: Date.new!(year, 12, 24),
        summary: "Ajunul Crăciunului"
      },
      %{
        start_date: Date.new!(year, 12, 25),
        end_date: Date.new!(year, 12, 25),
        summary: "Crăciunul"
      },
      %{
        start_date: Date.new!(year, 12, 26),
        end_date: Date.new!(year, 12, 26),
        summary: "a doua zi de Crăciun"
      }
    ]

    if year == 2022 do
      # yes, the Google calendar has this in 2022
      [
        %{
          start_date: Date.new!(year, 12, 2),
          end_date: Date.new!(year, 12, 2),
          summary: "Vacanță în Sectorul Public"
        }
        | result
      ]
    else
      result
    end
  end

  def pto_backend_legal_holidays_factory(attrs \\ %{}) do
    year = Map.get(attrs, :year, Date.utc_today().year)

    year
    |> legal_holidays_in_romania()
    |> Enum.map(fn data -> build(:pto_backend_item, data) end)
  end

  def google_event_factory() do
    start = Faker.Date.backward(100)

    %{
      "kind" => "calendar#event",
      "created" => Faker.DateTime.backward(100),
      "updated" => Faker.DateTime.backward(100),
      "summary" => Faker.Lorem.sentence(),
      "creator" => %{
        "email" => Faker.Internet.email()
      },
      "organizer" => %{
        "displayName" => Faker.Lorem.word(),
        "email" => Faker.Internet.email(),
        "self" => true
      },
      "start" => %{
        "date" => start
      },
      "end" => %{
        "date" => Date.add(start, Faker.random_between(1, 30))
      }
    }
  end

  def google_events_response_factory() do
    calendar_summary = Faker.Lorem.word()

    %{
      "kind" => "calendar#events",
      "summary" => calendar_summary,
      "updated" => Faker.DateTime.backward(100),
      "timeZone" => "Europe/Bucharest",
      "accessRole" => "reader",
      "items" =>
        build_list(10, :google_event, %{
          "organizer" => %{
            "displayName" => calendar_summary,
            "email" => Faker.Internet.email(),
            "self" => true
          }
        })
    }
  end

  def google_events_response_legal_holidays_factory(attrs \\ %{}) do
    year = Map.get(attrs, :year, Date.utc_today().year)

    items =
      year
      |> legal_holidays_in_romania()
      |> Enum.map(fn item ->
        build(:google_event, %{
          "start" => %{"date" => item[:start_date]},
          "end" => %{"date" => Date.add(item[:end_date], 1)},
          "summary" => item[:summary],
          "creator" => nil,
          "organizer" => %{
            "displayName" => "Legal Holidays Calendar",
            "email" => Faker.Internet.email(),
            "self" => false
          }
        })
      end)

    build(:google_event, %{
      "items" => items,
      "summary" => "Legal Holidays Calendar"
    })
  end
end
