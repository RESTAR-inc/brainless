defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  import Ecto.Query, warn: false

  require Logger

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Query
  alias Brainless.Rag.Embedding

  @requirements ["app.start", "app.config"]

  def run(_) do
    update_all_movies()
  end

  defp chunk_size do
    case Embedding.get_provider() do
      :gemini -> 100
      :local -> 10
    end
  end

  defp update_all_movies do
    from(movie in Movie)
    |> Query.stream_all(chunk_size(),
      preload: [:director, :cast, :genres],
      order_by: [asc: :id]
    )
    |> Stream.each(&update_movies/1)
    |> Stream.run()
  end

  defp update_movies(movies) do
    texts = Enum.map(movies, &Movie.format_for_embedding/1)
    {:ok, embeddings} = Embedding.to_vector_list(texts)

    if length(embeddings) != length(movies) do
      raise "embeddings size != items size"
    end

    Enum.with_index(movies)
    |> Enum.map(fn {entity, idx} ->
      embedding = Enum.at(embeddings, idx)

      case MediaLibrary.update_movie(entity, %{embedding: embedding}) do
        {:ok, updated_entity} ->
          Logger.info("Movie [#{updated_entity.id}] #{updated_entity.title}")

        {:error, _changeset} ->
          Logger.error("Movie [#{entity.id}] #{entity.title}")
      end
    end)
  end
end
