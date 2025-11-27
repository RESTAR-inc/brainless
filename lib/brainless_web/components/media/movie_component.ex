defmodule BrainlessWeb.Media.MovieComponent do
  @moduledoc """
  Movie components
  """
  use BrainlessWeb, :html

  alias Brainless.MediaLibrary.Movie

  attr :movie, Movie

  def movie(assigns) do
    ~H"""
    <div class="grid grid-cols-[50px_1fr] gap-4">
      <div>
        <img src={@movie.poster_url} width="50" />
      </div>
      <div class="flex flex-col gap-2">
        <h2 class="text-xl">
          <.link navigate={~p"/movies/#{@movie}"}>
            {@movie.title}
          </.link>
        </h2>
        <div>
          Genres: <span class="text-sm">{Enum.map_join(@movie.genres, ", ", & &1.name)}</span>
        </div>
        <div class="text-sm">{@movie.description}</div>
      </div>
    </div>
    """
  end
end
