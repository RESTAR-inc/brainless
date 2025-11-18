defmodule Brainless.MediaLibrary.Movie do
  @moduledoc """
  Movie schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "movies" do
    field :title, :string
    field :description, :string
    field :poster_url, :string
    field :release_date, :date
    field :imdb_rating, :float
    field :meta_score, :integer
    field :gross, :integer
    field :number_of_votes, :integer
    field :embedding, Pgvector.Ecto.Vector

    belongs_to :director, Brainless.MediaLibrary.Person

    many_to_many :genres, Brainless.MediaLibrary.Genre, join_through: "movies_genres"
    many_to_many :cast, Brainless.MediaLibrary.Person, join_through: "movies_cast"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [
      :title,
      :description,
      :poster_url,
      :release_date,
      :imdb_rating,
      :meta_score,
      :gross,
      :number_of_votes,
      :embedding,
      :director_id
    ])
    |> validate_required([
      :title,
      :description,
      :director_id
    ])
  end

  defp format_release_year(movie) do
    case movie.release_date do
      nil -> "unknown"
      date -> "#{date.year}"
    end
  end

  def format_genres(movie) do
    Enum.map_join(movie.genres, ", ", & &1.name)
  end

  def format_cast(movie) do
    Enum.map_join(movie.cast, ", ", & &1.name)
  end

  def format_for_embedding(%__MODULE__{} = movie) do
    """
    # #{movie.title} (#{format_release_year(movie)})

    Genre: #{format_genres(movie)}

    ## Synopsis

    #{movie.description}

    ## Details
      - Directed By: #{movie.director.name}
      - Cast: #{format_cast(movie)}

    ## Ratings
      - IMDB: #{movie.imdb_rating}
      - Meta Score: #{movie.meta_score}
    """
  end
end
