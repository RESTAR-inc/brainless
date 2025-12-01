defmodule Brainless.Rag.Document.MediaDocument do
  @moduledoc """
  Media Document formatter, etc.
  """
  use Brainless.Rag.Document

  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Embedding.EmbedDocument

  @max_movie_description_length 1000
  @max_book_description_length 1000

  @impl true
  def index_name, do: "media"

  @impl true
  def document(%Movie{} = movie) do
    %EmbedDocument{
      id: "movie-#{movie.id}",
      content: format(movie),
      meta: %{
        id: movie.id,
        type: "movie"
      }
    }
  end

  def document(%Book{} = book) do
    %EmbedDocument{
      id: "book-#{book.id}",
      content: format(book),
      meta: %{
        id: book.id,
        type: "book"
      }
    }
  end

  @impl true
  def mappings do
    %{
      id: %{
        type: "integer"
      },
      type: %{
        type: "text"
      }
    }
  end

  @impl true
  def format(%Movie{} = movie) do
    """
    # #{movie.title} (#{format_release_year(movie)})

    Directed By: #{movie.director.name}
    Genre: #{format_genres(movie)}

    ## Synopsis

    #{get_description(movie.description || "n/a", @max_movie_description_length)}

    ## Details
      - Cast: #{format_persons(movie)}
      - IMDB: #{movie.imdb_rating}
      - Meta Score: #{movie.meta_score}

    ## Review: #{movie.review_title || "n/a"}
    #{get_description(movie.review || "n/a", @max_movie_description_length)}
    """
  end

  def format(%Book{} = book) do
    """
    # #{book.title} (#{format_release_year(book)})
    ## #{book.subtitle || "---"}

    Authors: #{format_persons(book)}
    Genre: #{format_genres(book)}

    ## Synopsis

    #{get_description(book.description || "n/a", @max_book_description_length)}

    ## Details
      - Pages: #{book.num_pages || "n/a"}
      - ISBN13: #{book.isbn13}
      - ISBN10: #{book.isbn10}
      - Average Rating: #{book.average_rating || "n/a"}
      - Ratings Count: #{book.ratings_count || "n/a"}
    """
  end

  def format(_), do: ""

  defp format_release_year(%Movie{release_date: release_date}) do
    case release_date do
      nil -> "n/a"
      date -> "#{date.year}"
    end
  end

  defp format_release_year(%Book{published_at: published_at}) do
    case published_at do
      nil -> "n/a"
      date -> "#{date.year}"
    end
  end

  defp format_genres(%Movie{genres: genres}), do: Enum.map_join(genres, ", ", & &1.name)
  defp format_genres(%Book{genres: genres}), do: Enum.map_join(genres, ", ", & &1.name)

  defp format_persons(%Movie{cast: cast}), do: Enum.map_join(cast, ", ", & &1.name)
  defp format_persons(%Book{authors: authors}), do: Enum.map_join(authors, ", ", & &1.name)

  defp get_description(value, max) when is_binary(value) and is_integer(max) do
    if String.length(value) > max do
      String.slice(value, 0, max) <> "..."
    else
      value
    end
  end
end
