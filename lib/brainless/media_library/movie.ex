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
      :director_id
    ])
    |> validate_required([
      :title,
      :description,
      :director_id
    ])
  end
end
