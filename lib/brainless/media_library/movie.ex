defmodule Brainless.MediaLibrary.Movie do
  @moduledoc """
  Movie schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "movies" do
    field :title, :string
    field :start_year, :integer
    field :end_year, :integer
    field :type, :string
    field :country, :string
    field :description, :string
    field :summary, :string
    field :rating, :float
    field :number_of_votes, :integer
    field :image_url, :string

    many_to_many :genres, Brainless.MediaLibrary.Genre, join_through: "movies_genres"
    many_to_many :cast, Brainless.MediaLibrary.Person, join_through: "movies_cast"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [
      :title,
      :start_year,
      :end_year,
      :type,
      :country,
      :description,
      :summary,
      :rating,
      :number_of_votes,
      :image_url
    ])
    |> validate_required([:title, :description, :summary])
  end
end
