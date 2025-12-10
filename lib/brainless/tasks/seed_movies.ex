defmodule Brainless.Tasks.SeedMovies do
  @moduledoc """
  Seed movies
  """
  import Ecto.Changeset
  require Logger

  alias Brainless.Repo

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Tasks.Utils

  @csv "priv/data/netflix_list.csv"

  defp row_to_map([
         imdb_id,
         title,
         popular_rank,
         certificate,
         start_year,
         end_year,
         episodes,
         runtime,
         type,
         orign_country,
         language,
         plot,
         summary,
         rating,
         num_votes,
         genres,
         is_adult,
         cast,
         image_url
       ]) do
    %{
      imdb_id: imdb_id,
      title: title,
      popular_rank: popular_rank,
      certificate: certificate,
      start_year: start_year,
      end_year: end_year,
      episodes: episodes,
      runtime: runtime,
      type: type,
      orign_country: orign_country,
      language: language,
      plot: plot,
      summary: summary,
      rating: rating,
      num_votes: num_votes,
      genres: genres,
      is_adult: is_adult,
      cast: cast,
      image_url: image_url
    }
    |> Enum.map(fn {key, value} -> {key, String.trim(value)} end)
    |> Map.new()
  end

  defp create_cast("-"), do: {:ok, []}
  defp create_cast(cast_str), do: Utils.create_persons_from_str(cast_str)

  defp update_movie(%Movie{} = movie, cast, genres) do
    movie
    |> Repo.preload([:genres, :cast])
    |> MediaLibrary.change_movie()
    |> cast_assoc(:genres)
    |> put_assoc(:genres, genres)
    |> cast_assoc(:cast)
    |> put_assoc(:cast, cast)
    |> Repo.update()
  end

  defp create_movie(data) do
    MediaLibrary.create_movie(%{
      title: data[:title],
      start_year: Utils.parse_int(data[:start_year]),
      end_year: Utils.parse_int(data[:end_year]),
      type: data[:type],
      country: data[:orign_country],
      description: data[:plot],
      summary: data[:summary],
      rating: Utils.parse_float(data[:rating]),
      number_of_votes: Utils.parse_int(data[:num_votes]),
      image_url: data[:image_url]
    })
  end

  defp import_movie(%{plot: ""}), do: {:skip, nil}
  defp import_movie(%{summary: ""}), do: {:skip, nil}
  defp import_movie(%{plot: "-"}), do: {:skip, nil}
  defp import_movie(%{summary: "-"}), do: {:skip, nil}

  defp import_movie(data) do
    with {:ok, created_movie} <- create_movie(data),
         {:ok, cast} <- create_cast(data[:cast]),
         {:ok, genres} <- Utils.create_genres_from_str(data[:genres]),
         {:ok, updated_movie} <- update_movie(created_movie, cast, genres) do
      {:ok, updated_movie}
    else
      {:error, error} ->
        {:error, error}

      _ ->
        {:error, "Unknown error"}
    end
  end

  defp process_row(row) do
    data = row_to_map(row)
    Logger.info("Movie to import: #{data[:title]}")

    case import_movie(data) do
      {:ok, movie} ->
        Logger.info("Movie imported: #{movie.id}/#{movie.title}")
        :ok

      {:skip, nil} ->
        Logger.info("Movie skipped: #{data[:title]}")
        :skip

      {:error, _} ->
        Logger.error("Movie failed: #{data[:title]}")
        :error
    end
  end

  def seed do
    stats = Utils.seed(@csv, &process_row/1)
    Logger.info("\nok: #{stats[:ok]}\nerror: #{stats[:error] || 0}\nskip: #{stats[:skip] || 0}")
  end
end
