defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  alias Brainless.Shop
  alias Brainless.Rag.Embedding

  @requirements ["app.start", "app.config"]

  def run(_) do
    case Application.fetch_env!(:brainless, :ai_provider) do
      "bumblebee" ->
        update_index(:bumblebee, Shop.list_books())

      "gemini" ->
        update_index(:gemini, Shop.list_books())
    end
  end

  defp update_books(books, embeddings) do
    Enum.with_index(books)
    |> Enum.map(fn {book, idx} ->
      %{values: embedding} = Enum.at(embeddings, idx)

      case Shop.update_book(book, %{embedding: embedding}) do
        {:ok, updated_book} ->
          dbg({"updated", book.id, book.name})
          updated_book

        {:error, changeset} ->
          dbg({"error", book.id, book.name, changeset.errors})
          book
      end
    end)
  end

  defp update_index(:gemini, books) do
    texts = Enum.map(books, & &1.description)

    {:ok, response} =
      ExLLM.Providers.Gemini.Embeddings.embed_texts("models/text-embedding-004", texts,
        cache: true,
        cache_ttl: :timer.minutes(10)
      )

    if length(response) != length(books) do
      raise "response size != books size"
    end

    update_books(books, response)
  end

  defp update_index(:bumblebee, books) do
    Enum.map(books, fn book ->
      %{embedding: embedding} = Embedding.predict(book.description)

      case Shop.update_book(book, %{embedding: embedding}) do
        {:ok, updated_book} ->
          dbg({"updated", book.id, book.name})
          updated_book

        {:error, changeset} ->
          dbg({"error", book.id, book.name, changeset.errors})
          book
      end
    end)
  end
end
