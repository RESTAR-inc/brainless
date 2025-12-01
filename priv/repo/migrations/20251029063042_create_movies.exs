defmodule Brainless.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:persons) do
      add :name, :string, null: false
      add :occupations, {:array, :string}, null: false, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:persons, [:name])

    create table(:genres) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:genres, [:name])

    create table(:movies) do
      add :title, :string, null: false
      add :description, :text
      add :poster_url, :string
      add :release_date, :date
      add :imdb_rating, :float
      add :meta_score, :integer
      add :number_of_votes, :integer
      add :review_title, :string, size: 512
      add :review, :text

      add :director_id, references(:persons, on_delete: :nothing), null: true

      timestamps(type: :utc_datetime)
    end

    create table(:movies_genres) do
      add :movie_id, references(:movies, on_delete: :delete_all)
      add :genre_id, references(:genres, on_delete: :delete_all)
    end

    create unique_index(:movies_genres, [:movie_id, :genre_id])

    create table(:movies_cast) do
      add :movie_id, references(:movies, on_delete: :delete_all)
      add :person_id, references(:persons, on_delete: :delete_all)
    end

    create unique_index(:movies_cast, [:movie_id, :person_id])
  end
end
