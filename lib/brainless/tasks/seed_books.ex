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

  def seed do
    File.stream!(@csv)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      data = row_to_map(row)
      genres = Utils.create_genres(data[:categories])

      authors =
        data[:authors]
        |> String.split(";")
        |> Enum.map(&String.trim(&1))
        |> Enum.uniq()
        |> Enum.map(&Utils.get_or_create_person(&1, :writer))
        |> Enum.reject(&is_nil/1)

      attrs = %{
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
      }

      case MediaLibrary.create_book(attrs) do
        {:ok, %Book{} = new_book} ->
          new_book
          |> Repo.preload([:genres, :authors])
          |> MediaLibrary.change_book()
          |> cast_assoc(:genres)
          |> put_assoc(:genres, genres)
          |> cast_assoc(:authors)
          |> put_assoc(:authors, authors)
          |> Repo.update()

          Logger.info("Book:ok #{new_book.id}/#{new_book.title}")

        {:error, _} ->
          Logger.error("Book:error #{data[:title]}")
          raise "Book Import Error"
      end
    end)
    |> Stream.run()
  end
end
