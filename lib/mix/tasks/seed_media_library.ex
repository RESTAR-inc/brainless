defmodule Mix.Tasks.SeedMediaLibrary do
  @moduledoc "Seed the database"

  use Mix.Task

  import Ecto.Changeset
  require Logger

  alias Brainless.Repo

  alias Brainless.CsvParser
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Genre
  alias Brainless.MediaLibrary.Movie
  alias Brainless.MediaLibrary.Person

  @requirements ["app.start"]

  @csv_file_path "priv/data/imdb_top_1000.csv"

  defp movie_row_to_map([
         poster_url,
         title,
         release_year,
         certificate,
         runtime,
         genre,
         imdb_rating,
         description,
         meta_score,
         director,
         star1,
         star2,
         star3,
         star4,
         number_of_votes,
         gross
       ]) do
    %{
      poster_url: poster_url,
      title: title,
      release_year: release_year,
      certificate: certificate,
      runtime: runtime,
      genre: genre,
      imdb_rating: imdb_rating,
      description: description,
      meta_score: meta_score,
      director: director,
      star1: star1,
      star2: star2,
      star3: star3,
      star4: star4,
      number_of_votes: number_of_votes,
      gross: gross
    }
  end

  defp prepare_genre(input) do
    input
    |> String.split(",")
    |> Enum.map(&String.trim(&1))
    |> Enum.uniq()
  end

  defp seed_genres do
    File.stream!(@csv_file_path)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      %{genre: genre} = movie_row_to_map(row)

      prepare_genre(genre)
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn name ->
      case MediaLibrary.create_genre(%{name: name}) do
        {:ok, %Genre{} = new_genre} ->
          Logger.info("Genre:ok #{new_genre.id}/#{new_genre.name}")
          new_genre

        {:error, _} ->
          Logger.error("Genre:error #{name}")
          raise "Genre Import Error"
      end
    end)
    |> Enum.into(%{}, &{&1.name, &1})
  end

  defp parse_int(input) do
    case Integer.parse(input) do
      {value, _} -> value
      :error -> nil
    end
  end

  defp parse_value(:release_year, data) do
    case Integer.parse(data[:release_year]) do
      {value, _} -> Date.new!(value, 1, 1)
      :error -> nil
    end
  end

  defp parse_value(:meta_score, data), do: parse_int(data[:meta_score])
  defp parse_value(:imdb_rating, data), do: parse_int(data[:imdb_rating])
  defp parse_value(:number_of_votes, data), do: parse_int(data[:number_of_votes])

  defp parse_value(:gross, data) do
    case data[:gross] do
      nil ->
        nil

      value when is_binary(value) ->
        case String.replace(value, ",", "") |> Integer.parse() do
          {val, _} -> val
          :error -> nil
        end
    end
  end

  defp create_person(name, occupation) do
    case MediaLibrary.create_person(%{name: name, occupations: [occupation]}) do
      {:ok, %Person{} = new_person} ->
        Logger.info("Person:created #{new_person.id}/#{new_person.name}")
        new_person

      {:error, _} ->
        raise "Person:create #{name}"
    end
  end

  defp update_person(%Person{} = person, occupation) do
    attrs = %{occupations: [occupation | person.occupations]}

    case MediaLibrary.update_person(person, attrs) do
      {:ok, %Person{} = updated_person} ->
        Logger.info("Person:updated #{updated_person.id}/#{updated_person.name}")
        updated_person

      {:error, _} ->
        raise "Person:update #{person.name}"
    end
  end

  defp get_or_create_person(name, occupation) do
    case MediaLibrary.get_person_by_name(name) do
      %Person{} = person ->
        if occupation in person.occupations do
          person
        else
          update_person(person, occupation)
        end

      nil ->
        create_person(name, occupation)
    end
  end

  defp seed_movies(genres) do
    File.stream!(@csv_file_path)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      data =
        movie_row_to_map(row)
        |> Map.take([
          :title,
          :description,
          :release_year,
          :poster_url,
          :imdb_rating,
          :meta_score,
          :genre,
          :gross,
          :number_of_votes,
          :director,
          :star1,
          :star2,
          :star3,
          :star4
        ])

      genres = prepare_genre(data[:genre]) |> Enum.map(&Map.fetch!(genres, &1))

      director =
        data[:director]
        |> String.trim()
        |> get_or_create_person(:director)

      cast =
        data
        |> Map.take([:star1, :star2, :star3, :star4])
        |> Map.values()
        |> Enum.map(&String.trim(&1))
        |> Enum.uniq()
        |> Enum.map(&get_or_create_person(&1, :actor))

      attrs =
        %{
          title: data[:title],
          description: data[:description],
          poster_url: data[:poster_url],
          release_date: parse_value(:release_year, data),
          imdb_rating: parse_value(:imdb_rating, data),
          meta_score: parse_value(:meta_score, data),
          gross: parse_value(:gross, data),
          number_of_votes: parse_value(:number_of_votes, data),
          director_id: director.id
        }

      case MediaLibrary.create_movie(attrs) do
        {:ok, %Movie{} = new_movie} ->
          Logger.info("Movie:ok #{new_movie.id}/#{new_movie.title}")

          new_movie
          |> Repo.preload([:genres, :cast])
          |> MediaLibrary.change_movie()
          |> cast_assoc(:genres)
          |> put_assoc(:genres, genres)
          |> cast_assoc(:cast)
          |> put_assoc(:cast, cast)
          |> Repo.update()

        {:error, _error} ->
          Logger.error("Movie:error #{data[:title]}")
          raise "Movie Import Error"
      end
    end)
    |> Stream.run()
  end

  def run(_opts) do
    genres = seed_genres()
    seed_movies(genres)
  end
end
