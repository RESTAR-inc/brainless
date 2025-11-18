NimbleCSV.define(BrainlessSeedParser, separator: ",", escape: "\"")

defmodule Mix.Tasks.Seed do
  @moduledoc "Seed the database"

  use Mix.Task

  import Ecto.Changeset
  require Logger

  alias Brainless.Repo

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.{Movie, Genre, Person}

  @requirements ["app.start"]

  @csv_movies "priv/data/imdb_top_1000.csv"

  defp movie_row([
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
    File.stream!(@csv_movies)
    |> BrainlessSeedParser.parse_stream()
    |> Stream.map(fn row ->
      %{genre: genre} = movie_row(row)

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

  defp seed_persons do
    File.stream!(@csv_movies)
    |> BrainlessSeedParser.parse_stream()
    |> Stream.map(fn row ->
      movie_row(row)
      |> Map.take([:director, :star1, :star2, :star3, :star4])
      |> Map.values()
      |> Enum.map(&String.trim(&1))
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn name ->
      case MediaLibrary.create_person(%{name: name}) do
        {:ok, %Person{} = new_person} ->
          Logger.info("Person:ok #{new_person.id}/#{new_person.name}")
          new_person

        {:error, _} ->
          Logger.error("Person:error #{name}")
          raise "Person Import Error"
      end
    end)
    |> Enum.into(%{}, &{&1.name, &1})
  end

  defp seed_movies(genres, persons) do
    File.stream!(@csv_movies)
    |> BrainlessSeedParser.parse_stream()
    |> Stream.map(fn row ->
      data =
        movie_row(row)
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

      release_date =
        case Integer.parse(data[:release_year]) do
          {value, _} -> Date.new!(value, 1, 1)
          :error -> nil
        end

      meta_score =
        case Integer.parse(data[:meta_score]) do
          {value, _} -> value
          :error -> nil
        end

      imdb_rating =
        case Integer.parse(data[:imdb_rating]) do
          {value, _} -> value
          :error -> nil
        end

      number_of_votes =
        case Integer.parse(data[:number_of_votes]) do
          {value, _} -> value
          :error -> nil
        end

      gross =
        case data[:gross] do
          nil ->
            nil

          value when is_binary(value) ->
            case String.replace(value, ",", "") |> Integer.parse() do
              {val, _} -> val
              :error -> nil
            end
        end

      director = Map.get(persons, String.trim(data[:director]))
      genres = prepare_genre(data[:genre]) |> Enum.map(&Map.fetch!(genres, &1))

      cast =
        data
        |> Map.take([:star1, :star2, :star3, :star4])
        |> Map.values()
        |> Enum.map(&String.trim(&1))
        |> Enum.uniq()
        |> Enum.map(&Map.get(persons, &1))

      attrs =
        %{
          title: data[:title],
          description: data[:description],
          poster_url: data[:poster_url],
          release_date: release_date,
          imdb_rating: imdb_rating,
          meta_score: meta_score,
          gross: gross,
          number_of_votes: number_of_votes,
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

        {:error, _} ->
          Logger.error("Movie:error #{data[:title]}")
          raise "Movie Import Error"
      end
    end)
    |> Stream.run()
  end

  def run(_) do
    genres = seed_genres()
    persons = seed_persons()
    seed_movies(genres, persons)
  end
end
