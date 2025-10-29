defmodule Brainless.MediaLibrary.Movie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "movies" do
    field :title, :string
    field :description, :string
    field :poster_url, :string
    field :genre, :string
    field :director, :string
    field :release_date, :date
    field :imdb_rating, :float
    field :meta_score, :integer
    field :embedding, Pgvector.Ecto.Vector

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [
      :title,
      :description,
      :poster_url,
      :genre,
      :director,
      :release_date,
      :imdb_rating,
      :meta_score,
      :embedding
    ])
    |> validate_required([
      :title,
      :description,
      :poster_url,
      :genre,
      :director,
      :release_date,
      :imdb_rating,
      :meta_score
    ])
  end
end
