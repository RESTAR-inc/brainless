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

  @csv "priv/data/imdb-movies-dataset.csv"

  defp row_to_map([
         poster_url,
         title,
         release_year,
         certificate,
         runtime,
         genre,
         imdb_rating,
         meta_score,
         director,
         cast,
         number_of_votes,
         description,
         review_count,
         review_title,
         review
       ]) do
    %{
      poster_url: poster_url,
      title: title,
      release_year: release_year,
      certificate: certificate,
      runtime: runtime,
      genre: genre,
      imdb_rating: imdb_rating,
      meta_score: meta_score,
      director: director,
      cast: cast,
      number_of_votes: number_of_votes,
      description: description,
      review_count: review_count,
      review_title: review_title,
      review: review
    }
  end

  defp create_director(data) do
    data[:director] |> String.trim() |> Utils.get_or_create_person(:director)
  end

  defp update_movie(%Movie{} = movie, cast_str, genres_str) do
    with {:ok, cast} <- Utils.create_persons_from_str(cast_str, :actor),
         {:ok, genres} <- Utils.create_genres_from_str(genres_str) do
      movie
      |> Repo.preload([:genres, :cast])
      |> MediaLibrary.change_movie()
      |> cast_assoc(:genres)
      |> put_assoc(:genres, genres)
      |> cast_assoc(:cast)
      |> put_assoc(:cast, cast)
      |> Repo.update()
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp create_movie(data, director) do
    MediaLibrary.create_movie(%{
      title: data[:title],
      description: data[:description],
      poster_url: data[:poster_url],
      release_date: Utils.parse_year(data[:release_year]),
      imdb_rating: Utils.parse_float(data[:imdb_rating]),
      meta_score: Utils.parse_int(data[:meta_score]),
      number_of_votes: Utils.parse_int(data[:number_of_votes]),
      director_id: director.id,
      review_title: data[:review_title],
      review: data[:review]
    })
  end

  defp import_movie(%{director: ""}), do: {:skip, nil}

  defp import_movie(data) do
    with {:ok, director} <- create_director(data),
         {:ok, created_movie} <- create_movie(data, director),
         {:ok, updated_movie} <- update_movie(created_movie, data[:cast], data[:genre]) do
      {:ok, updated_movie}
    else
      {:error, error} ->
        {:error, error}

      _ ->
        {:error, "Unknown error"}
    end
  end

  def seed do
    File.stream!(@csv)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      data = row_to_map(row)

      Logger.info("Movie to import: #{data[:title]}")

      case import_movie(data) do
        {:ok, movie} ->
          Logger.info("Movie imported: #{movie.id}/#{movie.title}")

        {:skip, nil} ->
          Logger.info("Movie skipped: #{data[:title]}")

        {:error, _} ->
          Logger.error("Movie failed: #{data[:title]}")
      end
    end)
    |> Stream.run()
  end
end
