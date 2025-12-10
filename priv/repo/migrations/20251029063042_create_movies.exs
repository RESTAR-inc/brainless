defmodule Brainless.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:persons) do
      add :name, :string, null: false

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
      add :start_year, :integer
      add :end_year, :integer
      add :type, :string
      add :country, :string
      add :description, :text
      add :summary, :text
      add :rating, :float
      add :number_of_votes, :integer
      add :image_url, :string

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
