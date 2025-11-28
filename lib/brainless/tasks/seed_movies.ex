defmodule Brainless.Tasks.SeedMovies do
  @moduledoc """
  Seed movies
  """
  import Ecto.Changeset
  require Logger

  alias Brainless.Repo

  alias Brainless.CsvParser
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Tasks.Utils

  @csv "priv/data/imdb_top_1000.csv"

  defp row_to_map([
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

  def seed do
    File.stream!(@csv)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      data = row_to_map(row)

      director =
        data[:director]
        |> String.trim()
        |> Utils.get_or_create_person(:director)

      cast =
        data
        |> Map.take([:star1, :star2, :star3, :star4])
        |> Map.values()
        |> Enum.map(&String.trim(&1))
        |> Enum.uniq()
        |> Enum.map(&Utils.get_or_create_person(&1, :actor))

      genres = data[:genre] |> Utils.create_genres()

      attrs =
        %{
          title: data[:title],
          description: data[:description],
          poster_url: data[:poster_url],
          release_date: Utils.parse_year(data[:release_year]),
          imdb_rating: Utils.parse_int(data[:imdb_rating]),
          meta_score: Utils.parse_int(data[:meta_score]),
          gross: parse_value(:gross, data),
          number_of_votes: Utils.parse_int(data[:number_of_votes]),
          director_id: director.id
        }

      case MediaLibrary.create_movie(attrs) do
        {:ok, %Movie{} = new_movie} ->
          new_movie
          |> Repo.preload([:genres, :cast])
          |> MediaLibrary.change_movie()
          |> cast_assoc(:genres)
          |> put_assoc(:genres, genres)
          |> cast_assoc(:cast)
          |> put_assoc(:cast, cast)
          |> Repo.update()

          Logger.info("Movie:ok #{new_movie.id}/#{new_movie.title}")

        {:error, _error} ->
          Logger.error("Movie:error #{data[:title]}")
          raise "Movie Import Error"
      end
    end)
    |> Stream.run()
  end
end
