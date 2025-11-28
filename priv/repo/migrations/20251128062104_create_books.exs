defmodule Brainless.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string, size: 512
      add :subtitle, :string
      add :isbn13, :string
      add :isbn10, :string
      add :thumbnail, :string
      add :description, :text
      add :published_at, :date
      add :average_rating, :float
      add :num_pages, :integer
      add :ratings_count, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books, [:isbn10])
    create unique_index(:books, [:isbn13])

    create table(:books_genres) do
      add :book_id, references(:books, on_delete: :delete_all)
      add :genre_id, references(:genres, on_delete: :delete_all)
    end

    create unique_index(:books_genres, [:book_id, :genre_id])

    create table(:books_authors) do
      add :book_id, references(:books, on_delete: :delete_all)
      add :person_id, references(:persons, on_delete: :delete_all)
    end

    create unique_index(:books_authors, [:book_id, :person_id])
  end
end
