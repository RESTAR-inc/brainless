defmodule Brainless.Rag.Document.MediaDocument do
  @moduledoc """
  Media Document formatter, etc.
  """
  use Brainless.Rag.Document

  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Embedding.EmbedData
  alias Brainless.Rag.Embedding.EmbedDocument

  @impl true
  def index_name, do: "media"

  @impl true
  def get_id(%EmbedData{meta: %{"id" => id, "type" => "movie"}}), do: "movie-#{id}"
  def get_id(%EmbedData{meta: %{id: id, type: "movie"}}), do: "movie-#{id}"

  @impl true
  def document(%Movie{} = movie) do
    %EmbedDocument{
      content: format(movie),
      meta: %{
        id: movie.id,
        type: "movie"
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

    Genre: #{format_genres(movie)}

    ## Synopsis

    #{movie.description}

    ## Details
      - Directed By: #{movie.director.name}
      - Cast: #{format_cast(movie)}

    ## Ratings
      - IMDB: #{movie.imdb_rating}
      - Meta Score: #{movie.meta_score}
    """
  end

  def format(_), do: ""

  defp format_release_year(%Movie{release_date: release_date}) do
    case release_date do
      nil -> "unknown"
      date -> "#{date.year}"
    end
  end

  defp format_genres(%Movie{genres: genres}) do
    Enum.map_join(genres, ", ", & &1.name)
  end

  defp format_cast(%Movie{cast: cast}) do
    Enum.map_join(cast, ", ", & &1.name)
  end
end
