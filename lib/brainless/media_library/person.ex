defmodule Brainless.MediaLibrary.Person do
  @moduledoc """
  Person schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "persons" do
    field :name, :string

    many_to_many :acted_in_movies, Brainless.MediaLibrary.Person, join_through: "movies_cast"
    many_to_many :wrote_books, Brainless.MediaLibrary.Book, join_through: "books_authors"

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = person, attrs) do
    person
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
