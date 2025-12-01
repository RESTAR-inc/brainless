defmodule Brainless.Tasks.SeedBooks do
  @moduledoc """
  Seed books
  """
  import Ecto.Changeset
  require Logger

  alias Brainless.CsvParser
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Book
  alias Brainless.Repo
  alias Brainless.Tasks.Utils

  @csv "priv/data/books_dataset.csv"

  defp row_to_map([
         isbn13,
         isbn10,
         title,
         subtitle,
         authors,
         categories,
         thumbnail,
         description,
         published_year,
         average_rating,
         num_pages,
         ratings_count
       ]) do
    %{
      isbn13: isbn13,
      isbn10: isbn10,
      title: title,
      subtitle: subtitle,
      authors: authors,
      categories: categories,
      thumbnail: thumbnail,
      description: description,
      published_year: published_year,
      average_rating: average_rating,
      num_pages: num_pages,
      ratings_count: ratings_count
    }
  end

  defp create_book(data) do
    MediaLibrary.create_book(%{
      title: data[:title],
      subtitle: data[:subtitle],
      isbn13: data[:isbn13],
      isbn10: data[:isbn10],
      thumbnail: data[:thumbnail],
      description: data[:description] || "",
      published_at: Utils.parse_year(data[:published_at]),
      average_rating: Utils.parse_float(data[:average_rating]),
      num_pages: Utils.parse_int(data[:num_pages]),
      ratings_count: Utils.parse_int(data[:ratings_count])
    })
  end

  defp update_book(%Book{} = book, authors_str, genres_str) do
    with {:ok, authors} <- Utils.create_persons_from_str(authors_str, :writer, ";"),
         {:ok, genres} <- Utils.create_genres_from_str(genres_str) do
      book
      |> Repo.preload([:genres, :authors])
      |> MediaLibrary.change_book()
      |> cast_assoc(:genres)
      |> put_assoc(:genres, genres)
      |> cast_assoc(:authors)
      |> put_assoc(:authors, authors)
      |> Repo.update()
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp import_book(data) do
    with {:ok, created_book} <- create_book(data),
         {:ok, updated_book} <- update_book(created_book, data[:authors], data[:categories]) do
      {:ok, updated_book}
    else
      {:error, error} ->
        {:error, error}

      _ ->
        {:error, "Unknown error"}
    end
  end

  def seed do
    File.stream!(@csv)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      data = row_to_map(row)

      Logger.info("Book to import: #{data[:title]}")

      case import_book(data) do
        {:ok, book} ->
          Logger.info("Book imported: #{book.id}/#{book.title}")

        {:error, _} ->
          Logger.error("Book failed: #{data[:title]}")
      end
    end)
    |> Stream.run()
  end
end
