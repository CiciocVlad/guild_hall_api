defmodule GuildHall.Repo.CodeVsDb do
  @doc """
  Compares the code and the db restrictions (nullable and default values).

  Run with `mix run priv/repo/code_vs_db.exs`.

  Don't trust anything it says, especially the migrations part!
  """

  import Ecto.Query

  alias GuildHall.Repo

  def required_fields(module, changeset_fn \\ nil) do
    changeset_fn = changeset_fn || fn struct, attrs -> module.changeset(struct, attrs) end
    values = struct(module)

    module.__schema__(:fields)
    |> Enum.reduce(values, fn field, accu ->
      Map.put(accu, field, nil)
    end)
    |> changeset_fn.(%{})
    |> Map.get(:errors)
    |> Enum.reduce(MapSet.new(), fn
      {field, {_error, validation: :required}}, accu ->
        MapSet.put(accu, field)

      {_field, _error}, accu ->
        accu
    end)
  end

  def get_code_state(module, changeset_fn) do
    required_fields = required_fields(module, changeset_fn)
    values = struct(module)

    module.__schema__(:fields)
    |> Enum.reduce([], fn field, accu ->
      [
        %{
          default: Map.get(values, field),
          name: to_string(field),
          is_nullable: field not in required_fields,
          type: module.__schema__(:type, field)
        }
        | accu
      ]
    end)
    |> Enum.sort_by(fn item -> Map.get(item, :name) end)
  end

  def get_db_state(struct_name) do
    table_name = struct_name.__schema__(:source)
    table_schema = struct_name.__schema__(:prefix) || "public"

    from(c in "columns",
      prefix: "information_schema",
      where: c.table_name == ^table_name and c.table_schema == ^table_schema,
      select: %{
        name: c.column_name,
        default: c.column_default,
        type: c.data_type,
        is_nullable: c.is_nullable == "YES"
      },
      order_by: c.column_name
    )
    |> Repo.all()
    |> Enum.map(fn item ->
      Map.update!(item, :default, fn
        nil ->
          nil

        db_val ->
          atom_name =
            item
            |> Map.fetch!(:name)
            |> String.to_existing_atom()

          type = struct_name.__schema__(:type, atom_name)

          case Ecto.Type.cast(type, db_val) do
            {:ok, cast} ->
              cast

            :error ->
              db_val
          end
      end)
    end)
  end

  def colourise(colour, string) do
    [colour, string, IO.ANSI.reset()]
    |> IO.ANSI.format_fragment(true)
    |> IO.iodata_to_binary()
  end

  def compare_field(field, code_type, code, db) do
    if code == db do
      :same
    else
      result =
        code
        |> Map.merge(db, fn k, v_code, v_db ->
          if acceptable?(field, code_type, k, v_code, v_db) do
            :same
          else
            {v_code, v_db}
          end
        end)
        |> Enum.reject(fn {_k, v} -> v == :same end)
        |> Enum.into(%{})

      if result == %{} do
        :same
      else
        {:diff, result}
      end
    end
  end

  def acceptable?("id", Ecto.UUID, :default, nil, "gen_random_uuid()") do
    true
  end

  def acceptable?("id", Ecto.UUID, :is_nullable, true, false) do
    true
  end

  def acceptable?(timestamp, _code_type, :default, nil, "now()")
      when timestamp in ["inserted_at", "updated_at"] do
    true
  end

  def acceptable?(timestamp, _code_type, :is_nullable, true, false)
      when timestamp in ["inserted_at", "updated_at"] do
    true
  end

  def acceptable?(_field, code_type, :default, code_value, db_value) do
    Ecto.Type.equal?(code_type, code_value, db_value)
  end

  def acceptable?(_field, _code_type, _item, code_value, db_value) do
    code_value == db_value
  end

  def compare_code_with_db(module, changeset_fn) do
    code_state =
      module
      |> get_code_state(changeset_fn)
      |> Map.new(fn item -> {Map.get(item, :name), Map.delete(item, :name)} end)

    db_state =
      module
      |> get_db_state()
      |> Map.new(fn item -> {Map.get(item, :name), Map.delete(item, :name)} end)

    compare_on = [:default, :is_nullable]

    diff =
      code_state
      |> Map.merge(db_state, fn field, code, db ->
        compare_field(
          field,
          Map.get(code, :type),
          Map.take(code, compare_on),
          Map.take(db, compare_on)
        )
      end)

    {diff, db_state}
  end

  def field_text(field, result) do
    case result do
      %{^field => {in_code, in_db}} ->
        [
          inspect(in_db),
          " -> ",
          inspect(in_code)
        ]

      _ ->
        []
    end
  end

  def print_diff_table([]) do
    nil
  end

  def print_diff_table(diff, name) do
    rows_count = Enum.count(diff)

    table_body =
      diff
      |> Enum.map(fn {field, {:diff, result}} ->
        per_item =
          [:is_nullable, :default]
          |> Enum.map(fn item ->
            content =
              field_text(item, result)
              |> IO.iodata_to_binary()
              |> String.pad_trailing(25 - 2)

            [" | ", content]
          end)

        [" ", String.pad_trailing(field, 25), " ", per_item, "\n"]
      end)

    separator_line = [
      String.duplicate("-", 25 + 3),
      "+",
      String.duplicate("-", 25),
      "+",
      String.duplicate("-", 25),
      "\n"
    ]

    table_header = [
      [
        " ",
        String.pad_trailing(name, 25 + 2),
        "|",
        String.pad_trailing(" is_nullable", 25),
        "|",
        String.pad_trailing(" default", 25),
        "\n"
      ],
      separator_line
    ]

    table_footer = [
      separator_line,
      [" ", to_string(rows_count), " row(s)", "\n"]
    ]

    [
      table_header,
      table_body,
      table_footer
    ]
    |> IO.iodata_to_binary()
    |> IO.puts()
  end

  def print_migrations([], _code_state, _table_name) do
    nil
  end

  def print_migrations(diff, db_state, table_name) do
    migrations =
      diff
      |> Enum.map(fn {field, {:diff, result}} ->
        generate_field_migrations(
          result,
          field,
          Kernel.get_in(db_state, [field, :type]),
          table_name
        )
      end)

    [
      [
        "# #{table_name}",
        "\n"
      ]
      | migrations
    ]
    |> IO.iodata_to_binary()
    |> IO.puts()
  end

  def generate_field_migrations(diff, field, type, table_name) do
    {update, opts} =
      case Map.fetch(diff, :default) do
        {:ok, {code_default, _db_default}} ->
          {[
             """
             {_count, nil} =
               from(
                 s in "#{table_name}",
                 where: is_nil(s.#{field})
               )
               |> repo().update_all(set: [#{field}: #{inspect(code_default)}])
             """,
             "\n"
           ], default: code_default}

        :error ->
          {[], []}
      end

    opts =
      case Map.fetch(diff, :is_nullable) do
        {:ok, {code_value, _db_value}} ->
          Keyword.put(opts, :null, code_value)

        :error ->
          opts
      end

    atom_field = String.to_existing_atom(field)

    atom_type =
      case type do
        "character varying" ->
          :string

        _ ->
          String.to_atom(type)
      end

    alter = """
    alter table("#{table_name}") do
      modify(#{inspect(atom_field)}, #{inspect(atom_type)}, #{inspect(opts)})
    end
    """

    [update, alter, "\n"]
  end

  def print_diff(module, changeset_fn, opts) do
    {diff, db_state} =
      module
      |> compare_code_with_db(changeset_fn)

    diff =
      diff
      |> Enum.reject(fn {_field, result} -> result == :same end)

    table_name = module.__schema__(:source)

    unless opts[:migrations_only] do
      print_diff_table(diff, table_name)
    end

    if opts[:migrations] || opts[:migrations_only] do
      print_migrations(diff, db_state, table_name)
    end
  end
end

{opts, _arguments} =
  OptionParser.parse!(System.argv(), strict: [migrations: :boolean, migrations_only: :boolean])

for module <- [
      GuildHall.Users.User,
      GuildHall.Categories.Category,
      GuildHall.Attributes.Attribute,
      GuildHall.UsersAttributes.UserAttribute,
      GuildHall.Projects.Project,
      GuildHall.UsersProjects.UserProject,
      GuildHall.PTODays.PTO,
      GuildHall.Roles.Role,
      GuildHall.RedirectUrls.RedirectUrl,
      GuildHall.BestOfQuotes.Quote,
      GuildHall.Articles.Article
    ] do
  changeset_fn =
    case module do
      GuildHall.PTODays.PTO ->
        &GuildHall.PTODays.PTO.changeset_for_create/2

      _ ->
        nil
    end

  GuildHall.Repo.CodeVsDb.print_diff(module, changeset_fn, opts)
end
