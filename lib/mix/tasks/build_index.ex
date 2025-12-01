defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  import Ecto.Query, warn: false

  require Logger

  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Query
  alias Brainless.Rag.Document.MediaDocument
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Embedding.Client
  alias Brainless.Rag.Embedding.EmbedData

  @requirements ["app.start", "app.config"]

  @doc_types ["movies", "books"]

  def run(args) do
    Logger.configure(level: :info)

    {parsed, _, _} =
      OptionParser.parse(args,
        strict: [
          type: [:string, :keep]
        ]
      )

    update_all(parsed)
  end

  defp update_all([]), do: Enum.each(@doc_types, &update({:type, &1}))
  defp update_all(types), do: Enum.each(types, &update/1)

  defp update({:type, "movies"}), do: update_all_movies()
  defp update({:type, "books"}), do: update_all_books()
  defp update(_), do: nil

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
    |> Stream.each(&update_entities/1)
    |> Stream.run()
  end

  defp update_all_books do
    from(book in Book)
    |> Query.stream_all(chunk_size(),
      preload: [:genres, :authors]
    )
    |> Stream.each(&update_entities/1)
    |> Stream.run()
  end

  defp update_index(%EmbedData{} = data, index_name) do
    case Client.insert_index(index_name, data) do
      :ok ->
        Logger.info("Index created for #{data.id}")
        :ok

      {:error, _error} ->
        Logger.error("Index failed: #{data.id}")
    end
  end

  defp update_entities(entities) do
    documents = Enum.map(entities, &MediaDocument.document/1)
    index_name = MediaDocument.index_name()

    ids_to_index = Enum.map_join(documents, ", ", & &1.id)
    Logger.info("Indexes in queue: #{ids_to_index}")

    case Embedding.docs_to_index_list(documents) do
      {:ok, embeddings} ->
        Enum.each(embeddings, &update_index(&1, index_name))

      {:error, _error} ->
        raise "Unbale to build an index"
    end
  end
end
