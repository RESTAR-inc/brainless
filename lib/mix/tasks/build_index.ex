defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Embedding

  @requirements ["app.start", "app.config"]

  def run(_) do
    rebuild_movies_index()
  end

  defp chunk_size do
    case Embedding.provider() do
      :gemini -> 100
      :local -> 500
    end
  end

  defp rebuild_movies_index() do
    MediaLibrary.list_movies()
    |> update_all(
      &Movie.format_for_embedding(&1),
      &"Movie [#{&1.id}] #{&1.title}",
      &MediaLibrary.update_movie(&1, %{embedding: &2})
    )
  end

  defp update_chunk(items, get_index_data, get_entity_repr, update) do
    texts = Enum.map(items, &get_index_data.(&1))
    {:ok, embeddings} = Embedding.to_vector_list(texts)

    if length(embeddings) != length(items) do
      raise "embeddings size != items size"
    end

    Enum.with_index(items)
    |> Enum.map(fn {entity, idx} ->
      embedding = Enum.at(embeddings, idx)

      case update.(entity, embedding) do
        {:ok, updated_entity} ->
          IO.puts("ok: #{get_entity_repr.(updated_entity)}")
          updated_entity

        {:error, _changeset} ->
          IO.puts("error: #{get_entity_repr.(entity)}")
          entity
      end
    end)
  end

  defp update_all(all_items, get_index_data, get_entity_repr, update) do
    all_items
    |> Enum.chunk_every(chunk_size())
    |> Enum.map(&update_chunk(&1, get_index_data, get_entity_repr, update))
    |> List.flatten()
  end
end
