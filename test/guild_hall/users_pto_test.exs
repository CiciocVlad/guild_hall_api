defmodule GuildHall.UsersPTOTest do
  use GuildHall.DataCase

  alias GuildHall.PTODays
  alias GuildHall.PTODays.PTO

  setup_all do
    Mox.defmock(MockBackend, for: PTODays.Backend)

    :ok
  end

  setup do
    user = Factory.insert(:user)
    pto_2020 = Factory.insert(:pto, user_id: user.id, year: 2020)
    Factory.insert(:pto, user_id: user.id, year: 2022)

    {:ok, user: user, pto_2020: pto_2020}
  end

  describe "get_yearly_status/3" do
    test "returns the defaults when the backend doesn't return any items", %{user: user} do
      Mox.stub(MockBackend, :list, fn filters ->
        assert filters
               |> Enum.into(%{})
               |> Map.drop([:creator_email, :type]) == %{
                 start_date: ~D[2020-01-01],
                 end_date: ~D[2020-12-31],
                 max_results: 2500
               }

        unless filters[:type] == :legal do
          assert filters[:creator_email] == user.email
        end

        {:ok, []}
      end)

      assert {:ok, %{nominal: 21, extra: 0, taken: 0, remaining: 21}} =
               PTODays.get_yearly_status(user.email, 2020, backend: MockBackend)
    end

    test "counts days excluding weekends and legal holidays", %{user: user} do
      Mox.stub(MockBackend, :list, fn filters ->
        result =
          case filters[:type] do
            :pto ->
              [
                %{
                  start_date: ~D[2021-12-24],
                  end_date: ~D[2022-01-04],
                  summary: "Winter Holiday"
                },
                %{
                  start_date: ~D[2022-08-08],
                  end_date: ~D[2022-08-21],
                  summary: "Summer Holiday"
                },
                %{
                  start_date: ~D[2022-12-20],
                  end_date: ~D[2022-12-20],
                  summary: "#{user.preferred_name} off"
                }
              ]
              |> Enum.map(fn item ->
                Factory.build(
                  :pto_backend_item,
                  item
                )
              end)

            :bonus_pto ->
              []

            :extra ->
              [
                %{
                  start_date: ~D[2022-08-15],
                  end_date: ~D[2022-08-15],
                  summary: "#{user.preferred_name} working on a legal holiday"
                },
                %{
                  start_date: ~D[2022-11-30],
                  end_date: ~D[2022-12-01],
                  summary: "#{user.preferred_name} working on two legal holidays"
                },
                %{
                  start_date: ~D[2022-07-02],
                  end_date: ~D[2022-07-02],
                  summary: "#{user.preferred_name} working on a weekend day"
                }
              ]
              |> Enum.map(fn item ->
                Factory.build(
                  :pto_backend_item,
                  item
                )
              end)

            :legal ->
              Factory.build(:pto_backend_legal_holidays, %{year: 2022})
          end

        {:ok, result}
      end)

      assert {:ok,
              %{
                nominal: 21,
                extra: 4,
                taken: 12,
                remaining: 21 + 4 - 12,
                details: [
                  %{
                    start_date: ~D[2021-12-24],
                    end_date: ~D[2022-01-04],
                    working_days: 2,
                    summary: "Winter Holiday"
                  },
                  %{
                    start_date: ~D[2022-08-08],
                    end_date: ~D[2022-08-21],
                    working_days: 9,
                    summary: "Summer Holiday"
                  },
                  %{
                    start_date: ~D[2022-12-20],
                    end_date: ~D[2022-12-20],
                    working_days: 1,
                    summary: "#{user.preferred_name} off"
                  }
                ],
                bonus_days: [],
                add_days: [
                  %{
                    end_date: ~D[2022-08-15],
                    start_date: ~D[2022-08-15],
                    summary: "#{user.preferred_name} working on a legal holiday",
                    working_days: 1
                  },
                  %{
                    end_date: ~D[2022-12-01],
                    start_date: ~D[2022-11-30],
                    summary: "#{user.preferred_name} working on two legal holidays",
                    working_days: 2
                  },
                  %{
                    end_date: ~D[2022-07-02],
                    start_date: ~D[2022-07-02],
                    summary: "#{user.preferred_name} working on a weekend day",
                    working_days: 1
                  }
                ]
              }} ==
               PTODays.get_yearly_status(user.email, 2022, backend: MockBackend)
    end

    test "returns an error when the backend returns an error", %{user: user} do
      Mox.stub(MockBackend, :list, fn filters ->
        {:error, "some error for get_#{filters[:type]}"}
      end)

      assert {:error, {type, error}} =
               PTODays.get_yearly_status(user.email, 2020, backend: MockBackend)

      assert type in [:get_legal, :get_taken, :get_extra]
      assert String.starts_with?(error, "some error for ")
    end

    test "returns an error when no PTO record is found", %{user: user} do
      Mox.stub(MockBackend, :list, fn _filters ->
        {:ok, []}
      end)

      assert {:error, {:get_pto_record, "nominal PTO record not found"}} ==
               PTODays.get_yearly_status(user.email, 2021, backend: MockBackend)
    end
  end

  describe "get_daily_status/1" do
    test "returns an empty map when the backend doesn't return any items" do
      Mox.stub(MockBackend, :list, fn filters ->
        assert filters
               |> Enum.into(%{})
               |> Map.drop([:type]) == %{
                 start_date: ~D[2020-01-14],
                 end_date: ~D[2020-01-14],
                 max_results: 2500
               }

        assert filters[:type] in [:pto, :bonus_pto]

        {:ok, []}
      end)

      assert {:ok, %{}} == PTODays.get_daily_status(~D[2020-01-14], backend: MockBackend)
    end

    test "returns users intervals indexed by user email when the backend returns items", %{
      user: user
    } do
      Mox.stub(MockBackend, :list, fn filters ->
        result =
          case filters[:type] do
            :pto ->
              [
                %{
                  start_date: ~D[2021-12-24],
                  end_date: ~D[2022-01-04],
                  summary: "Winter Holiday",
                  creator_email: "email1"
                },
                %{
                  start_date: ~D[2022-08-08],
                  end_date: ~D[2022-08-21],
                  summary: "Summer Holiday",
                  creator_email: "email2"
                },
                %{
                  start_date: ~D[2022-12-21],
                  end_date: ~D[2022-12-22],
                  summary: "#{user.preferred_name} off",
                  creator_email: user.email
                }
              ]
              |> Enum.map(fn item ->
                Factory.build(
                  :pto_backend_item,
                  item
                )
              end)

            :bonus_pto ->
              [
                %{
                  start_date: ~D[2022-12-24],
                  end_date: ~D[2022-12-24],
                  summary: "Bonus",
                  creator_email: "email3"
                },
                %{
                  start_date: ~D[2022-12-19],
                  end_date: ~D[2022-12-20],
                  summary: "#{user.preferred_name} off",
                  creator_email: user.email
                }
              ]
              |> Enum.map(fn item ->
                Factory.build(
                  :pto_backend_item,
                  item
                )
              end)
          end

        {:ok, result}
      end)

      assert {:ok,
              %{
                user.email => %{
                  start_date: ~D[2022-12-19],
                  end_date: ~D[2022-12-20],
                  summary: "#{user.preferred_name} off",
                  creator_email: user.email
                },
                "email1" => %{
                  start_date: ~D[2021-12-24],
                  end_date: ~D[2022-01-04],
                  summary: "Winter Holiday",
                  creator_email: "email1"
                },
                "email2" => %{
                  start_date: ~D[2022-08-08],
                  end_date: ~D[2022-08-21],
                  summary: "Summer Holiday",
                  creator_email: "email2"
                },
                "email3" => %{
                  start_date: ~D[2022-12-24],
                  end_date: ~D[2022-12-24],
                  summary: "Bonus",
                  creator_email: "email3"
                }
              }} == PTODays.get_daily_status(~D[2020-01-14], backend: MockBackend)
    end

    test "returns an error when the backend returns an error" do
      Mox.stub(MockBackend, :list, fn filters ->
        {:error, "some error for get_#{filters[:type]}"}
      end)

      assert {:error, {type, error}} =
               PTODays.get_daily_status(~D[2020-10-10], backend: MockBackend)

      assert type in [:get_taken, :get_extra]
      assert String.starts_with?(error, "some error for ")
    end
  end

  describe "create_pto/1" do
    setup :add_start_timestamp

    test "creates a user PTO record with valid data", %{
      user: user,
      start_timestamp: start_timestamp
    } do
      input_data = Factory.string_params_for(:pto, year: 2001, user_id: user.id)
      assert {:ok, %PTO{} = pto} = PTODays.create_pto(input_data)

      assert pto == Repo.get(PTO, pto.id)

      returned_data =
        pto
        |> string_params_map()
        |> Map.drop(~w[id user inserted_at updated_at])

      assert returned_data == input_data

      assert pto.inserted_at == pto.updated_at
      assert NaiveDateTime.compare(user.inserted_at, start_timestamp) in [:eq, :gt]
    end

    test "returns an error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{} = changeset} =
               :invalid_pto
               |> Factory.string_params_for()
               |> PTODays.create_pto()

      assert MapSet.new([:days, :user_id, :year]) ==
               changeset
               |> errors_on()
               |> Map.keys()
               |> MapSet.new()
    end

    test "returns an error changeset with missing data" do
      assert {:error, %Ecto.Changeset{} = changeset} = PTODays.create_pto(%{})

      assert MapSet.new([:days, :user_id, :year]) ==
               changeset
               |> errors_on()
               |> Map.keys()
               |> MapSet.new()
    end

    test "returns an error changeset with a duplicate {user_id, year} combination", %{user: user} do
      assert {:error, %Ecto.Changeset{} = changeset} =
               :pto
               |> Factory.string_params_for(year: 2020, user_id: user.id)
               |> PTODays.create_pto()

      assert {:user_year, _} = hd(changeset.errors)
    end
  end

  describe "update_pto/1" do
    setup :add_start_timestamp

    test "updates a user PTO record with valid data", %{
      start_timestamp: start_timestamp,
      pto_2020: pto_2020
    } do
      input_data = Factory.string_params_for(:pto, year: 2001)
      assert {:ok, %PTO{} = pto} = PTODays.update_pto(pto_2020, input_data)

      returned_data =
        pto
        |> string_params_map()
        |> Map.drop(~w[id user user_id inserted_at updated_at])

      assert returned_data == input_data

      assert NaiveDateTime.compare(pto.inserted_at, pto.updated_at) in [:eq, :lt]
      assert NaiveDateTime.compare(pto.updated_at, start_timestamp) in [:eq, :gt]

      assert pto == Repo.get(PTO, pto.id)
    end

    test "ignores the user_id field", %{
      pto_2020: pto_2020
    } do
      assert {:ok, %PTO{} = pto} =
               PTODays.update_pto(pto_2020, %{"user_id" => "should be ignored"})

      assert pto.updated_at == pto_2020.updated_at
    end

    test "returns an error changeset with invalid data", %{
      pto_2020: pto_2020
    } do
      assert {:error, %Ecto.Changeset{} = changeset} =
               PTODays.update_pto(pto_2020, Factory.string_params_for(:invalid_pto))

      assert MapSet.new([:days, :year]) ==
               changeset
               |> errors_on()
               |> Map.keys()
               |> MapSet.new()
    end

    test "returns an error changeset with a duplicate {user_id, year} combination", %{
      pto_2020: pto_2020
    } do
      assert {:error, %Ecto.Changeset{} = changeset} =
               PTODays.update_pto(pto_2020, Factory.string_params_for(:pto, year: 2022))

      assert {:user_year, _} = hd(changeset.errors)
    end
  end

  test "delete_pto/1 deletes the pto record", %{pto_2020: pto} do
    assert {:ok, %PTO{}} = PTODays.delete_pto(pto)

    assert is_nil(Repo.get(PTO, pto.id))
  end
end
