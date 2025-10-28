defmodule Brainless.Repo.Migrations.BooksAddEmbedding do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :embedding, :vector, size: 1536
    end

    create index("books", ["embedding vector_l2_ops"], using: :hnsw)
  end
end
