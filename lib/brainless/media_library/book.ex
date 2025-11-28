defmodule Brainless.MediaLibrary.Book do
  @moduledoc """
  Book
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :title, :string
    field :subtitle, :string
    field :isbn13, :string
    field :isbn10, :string
    field :thumbnail, :string
    field :description, :string
    field :published_at, :date
    field :average_rating, :float
    field :num_pages, :integer
    field :ratings_count, :integer

    many_to_many :genres, Brainless.MediaLibrary.Genre, join_through: "books_genres"
    many_to_many :authors, Brainless.MediaLibrary.Person, join_through: "books_authors"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [
      :title,
      :subtitle,
      :isbn13,
      :isbn10,
      :thumbnail,
      :description,
      :published_at,
      :average_rating,
      :num_pages,
      :ratings_count
    ])
    |> validate_required([
      :title,
      :isbn13,
      :isbn10
    ])
    |> unique_constraint(:isbn10)
    |> unique_constraint(:isbn13)
  end
end
