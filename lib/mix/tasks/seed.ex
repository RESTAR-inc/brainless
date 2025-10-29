NimbleCSV.define(BrainlessSeedParser, separator: ",", escape: "\"")

defmodule Mix.Tasks.Seed do
  @moduledoc "Seed the database"

  use Mix.Task

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Shop
  alias Brainless.Shop.Book

  @requirements ["app.start"]

  defp seed_movies do
    File.stream!("priv/data/imdb_top_1000.csv")
    |> BrainlessSeedParser.parse_stream()
    |> Stream.map(fn [
                       poster_url,
                       title,
                       release_year,
                       _certificate,
                       _runtime,
                       genre,
                       imdb_rating,
                       description,
                       meta_score,
                       director,
                       _star1,
                       _star2,
                       _star3,
                       _star4,
                       _no_of_votes,
                       _gross
                     ] ->
      release_date =
        case Integer.parse(release_year) do
          {value, _} -> Date.new!(value, 1, 1)
          :error -> nil
        end

      attrs =
        %{
          title: title,
          description: description,
          poster_url: poster_url,
          genre: genre,
          director: director,
          release_date: release_date,
          imdb_rating: imdb_rating,
          meta_score: meta_score
        }

      case MediaLibrary.create_movie(attrs) do
        {:ok, %Movie{}} ->
          dbg({"Movie:ok", title})

        {:error, changeset} ->
          dbg({"Movie:error", title, changeset.errors})
      end
    end)
    |> Stream.run()
  end

  defp seed_books() do
    File.stream!("priv/data/books.csv")
    |> BrainlessSeedParser.parse_stream()
    |> Stream.map(fn [name, description, price, is_available, isbn, author, published_at] ->
      attrs = %{
        name: name,
        description: description,
        price: String.to_integer(price),
        is_available:
          case is_available do
            "true" -> true
            _ -> false
          end,
        isbn: isbn,
        author: author,
        published_at: Date.from_iso8601!(published_at)
      }

      case Shop.create_book(attrs) do
        {:ok, %Book{}} ->
          dbg({"Book:ok", name})

        {:error, %Ecto.Changeset{} = changeset} ->
          dbg({"Book:error", name, changeset.errors})
      end
    end)
    |> Stream.run()
  end

  def run(_) do
    seed_books()
    seed_movies()
  end
end
