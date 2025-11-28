defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  import Ecto.Query, warn: false

  require Logger

  alias Brainless.MediaLibrary.Movie
  alias Brainless.Query
  alias Brainless.Rag.Document.MediaDocument
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Embedding.Client
  alias Brainless.Rag.Embedding.EmbedData

  @requirements ["app.start", "app.config"]

  def run(_) do
    index_name = MediaDocument.index_name()
    dimensions = Embedding.dimensions()
    mappings = MediaDocument.mappings()

    Client.create_index(index_name, dimensions, mappings)
    update_all_movies()
  end

  defp chunk_size do
    case Embedding.provider() do
      :gemini -> 100
      :local -> 20
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
    documents = Enum.map(movies, &MediaDocument.document/1)
    index_name = MediaDocument.index_name()

    {:ok, embeddings} = Embedding.docs_to_index_list(documents)

    Enum.each(embeddings, fn %EmbedData{} = embed_data ->
      case Client.insert_index(index_name, embed_data) do
        :ok ->
          :ok

        {:error, error} ->
          raise error
      end
    end)
  end
end
