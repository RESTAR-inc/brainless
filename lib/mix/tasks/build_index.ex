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

  @requirements ["app.start", "app.config"]

  @doc_types ["movies", "books"]

  def run(args) do
    Logger.configure(level: :info)

    {targets, _, _} =
      OptionParser.parse(args,
        strict: [
          type: [:string, :keep]
        ]
      )

    index_name = MediaDocument.index_name()
    meta_mappings = MediaDocument.get_meta_data_mappings()

    Client.delete_index(index_name)
    Client.create_index(index_name, meta_mappings)

    update_all(targets)
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
      preload: [:cast, :genres],
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

  defp update_entities(entities) do
    index_data_list = Enum.map(entities, &MediaDocument.get_index_data/1)
    index_name = MediaDocument.index_name()

    with {:ok, embedding_data} <- Embedding.to_index_list(index_data_list),
         {:ok, created_items} <- Client.bulk_index(index_name, embedding_data) do
      ids = Enum.map_join(created_items, ", ", fn %{"index" => %{"_id" => id}} -> id end)
      Logger.info("RAG Index #{index_name} OK: #{ids}")
      {:ok, created_items}
    else
      {:error, _error} ->
        raise "Unbale to build an index"
    end
  end
end
