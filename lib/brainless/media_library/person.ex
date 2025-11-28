defmodule Brainless.MediaLibrary.Person do
  @moduledoc """
  Person schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  @occupation_choices [:actor, :director, :writer]

  schema "persons" do
    field :name, :string
    field :occupations, {:array, Ecto.Enum}, values: @occupation_choices

    has_many :movies, Brainless.MediaLibrary.Movie, foreign_key: :director_id

    many_to_many :acted_in_movies, Brainless.MediaLibrary.Person, join_through: "movies_cast"
    many_to_many :wrote_books, Brainless.MediaLibrary.Book, join_through: "books_authors"

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = person, attrs) do
    person
    |> cast(attrs, [:name, :occupations])
    |> validate_required([:name])
  end
end
