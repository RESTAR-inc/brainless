defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  alias Brainless.Shop
  alias Brainless.MediaLibrary
  alias Brainless.Rag.Embedding

  @requirements ["app.start", "app.config"]

  def run(_) do
    case Application.fetch_env!(:brainless, :ai_provider) do
      "gemini" ->
        update_books_embeddings(:gemini)
        update_movies_embeddings(:gemini)

      "bumblebee" ->
        update_books_embeddings(:bumblebee)
        update_movies_embeddings(:bumblebee)
    end
  end

  defp update_movies_embeddings(:gemini) do
    MediaLibrary.list_movies()
    |> Enum.chunk_every(50)
    |> Enum.map(fn movies ->
      texts = Enum.map(movies, & &1.description)

      {:ok, embeddings} = Embedding.predict_many(:gemini, texts)

      if length(embeddings) != length(movies) do
        raise "embeddings size != movies size"
      end

      Enum.with_index(movies)
      |> Enum.map(fn {movie, idx} ->
        embedding = Enum.at(embeddings, idx)

        case MediaLibrary.update_movie(movie, %{embedding: embedding}) do
          {:ok, updated_movie} ->
            dbg({"updated", movie.id, movie.title})
            updated_movie

          {:error, changeset} ->
            dbg({"error", movie.id, movie.title, changeset.errors})
            movie
        end
      end)
    end)
    |> List.flatten()
  end

  defp update_movies_embeddings(:bumblebee) do
    []
  end

  defp update_books_embeddings(:gemini) do
    Shop.list_books()
    |> Enum.chunk_every(50)
    |> Enum.map(fn books ->
      texts = Enum.map(books, & &1.description)

      {:ok, embeddings} = Embedding.predict_many(:gemini, texts)

      if length(embeddings) != length(books) do
        raise "embeddings size != books size"
      end

      Enum.with_index(books)
      |> Enum.map(fn {book, idx} ->
        embedding = Enum.at(embeddings, idx)

        case Shop.update_book(book, %{embedding: embedding}) do
          {:ok, updated_book} ->
            dbg({"updated", book.id, book.name})
            updated_book

          {:error, changeset} ->
            dbg({"error", book.id, book.name, changeset.errors})
            book
        end
      end)
    end)
    |> List.flatten()
  end

  defp update_books_embeddings(:bumblebee) do
    Shop.list_books()
    |> Enum.map(fn book ->
      %{embedding: embedding} = Embedding.predict(:bumblebee, book.description)

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
