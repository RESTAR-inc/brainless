defmodule Brainless.Rag.Document.MediaDocument do
  @moduledoc """
  Media Document formatter, etc.
  """
  use Brainless.Rag.Document

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Embedding.IndexData
  alias Brainless.Rag.Embedding.Meta
  alias Brainless.Rag.Result

  @max_movie_description_length 1000
  @max_book_description_length 1000

  @impl true
  def index_name, do: "media"

  @impl true
  def get_index_data(%Movie{} = movie) do
    %IndexData{
      id: "movie-#{movie.id}",
      content: format(movie),
      meta: %Meta{
        id: movie.id,
        type: "movie",
        data: %{}
      }
    }
  end

  def get_index_data(%Book{} = book) do
    %IndexData{
      id: "book-#{book.id}",
      content: format(book),
      meta: %Meta{
        id: book.id,
        type: "book",
        data: %{}
      }
    }
  end

  @impl true
  def get_meta_data_mappings do
    %{
      id: %{type: "integer"},
      type: %{type: "text"}
    }
  end

  @impl true
  def get_meta_data(%Movie{id: id}), do: %{id: id, type: "movie"}
  def get_meta_data(%Book{id: id}), do: %{id: id, type: "book"}

  @impl true
  def format(%Movie{} = movie) do
    """
    # #{movie.title} (#{movie.type})
    #{format_year(movie)}

    #{get_description(movie.description || "", @max_movie_description_length)}

    ## Synopsis

    #{get_description(movie.summary || "n/a", @max_movie_description_length)}

    ## Cast
      #{format_persons(movie)}

    ## Details
      - Genre: #{format_genres(movie)}
      - Country: #{movie.country || "n/a"}
      - Rating: #{movie.rating || "n/a"}
      - Number of votes: #{movie.number_of_votes || "n/a"}
    """
  end

  def format(%Book{} = book) do
    """
    # #{book.title} (#{format_year(book)})
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

  @impl true
  def retrieve(results) do
    results
    |> Enum.reduce(%{}, &unwrap_item/2)
    |> Enum.map(&retrieve_type/1)
    |> List.flatten()
    |> Enum.sort_by(& &1.score, :desc)
  end

  defp retrieve_type({type, ids_with_score}) do
    ids = Enum.map(ids_with_score, fn {id, _} -> id end)
    scores_map = Map.new(ids_with_score)

    type
    |> String.to_existing_atom()
    |> MediaLibrary.get_by_ids(ids)
    |> Enum.map(fn entity ->
      score = Map.get(scores_map, entity.id)

      %Result{
        type: type,
        data: entity,
        score: score
      }
    end)
  end

  defp unwrap_item({%IndexData{meta: %{id: id, type: type}}, score}, acc) do
    Map.update(acc, type, [{id, score}], fn existing_list ->
      existing_list ++ [{id, score}]
    end)
  end

  defp format_year(%Movie{start_year: start_year, end_year: end_year}) do
    case {start_year, end_year} do
      {left, nil} when is_integer(left) -> "#{left} - now"
      {_, right} when is_integer(right) -> "n/a - #{right}"
      {left, right} when is_integer(left) and is_integer(right) -> "#{left} - #{right}"
      _ -> "n/a"
    end
  end

  defp format_year(%Book{published_at: published_at}) do
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
