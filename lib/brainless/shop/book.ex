defmodule Brainless.Shop.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :name, :string
    field :description, :string
    field :price, :integer
    field :is_available, :boolean, default: false
    field :isbn, :string
    field :author, :string
    field :published_at, :date

    field :embedding, Pgvector.Ecto.Vector

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name, :description, :price, :is_available, :isbn, :author, :published_at])
    |> validate_required([
      :name,
      :description,
      :price,
      :is_available,
      :isbn,
      :author,
      :published_at
    ])
  end
end
