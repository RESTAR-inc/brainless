defmodule Brainless.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string, null: false
      add :description, :text
      add :poster_url, :string
      add :genre, :string
      add :director, :string
      add :release_date, :date
      add :imdb_rating, :float
      add :meta_score, :integer
      add :embedding, :vector, size: 768

      timestamps(type: :utc_datetime)
    end

    create index("movies", ["embedding vector_l2_ops"], using: :hnsw)
  end
end
