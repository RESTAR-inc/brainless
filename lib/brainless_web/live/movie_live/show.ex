defmodule BrainlessWeb.MovieLive.Show do
  use BrainlessWeb, :live_view

  alias Brainless.MediaLibrary

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    movie = MediaLibrary.get_movie!(id)

    {:ok,
     socket
     |> assign(:page_title, "Show Movie")
     |> assign(:movie, movie)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        <h1>{@movie.title}</h1>
        <:subtitle>{@movie.release_date}</:subtitle>
        <:actions>
          <.button navigate={~p"/media"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/movies/#{@movie}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit movie
          </.button>
        </:actions>
      </.header>

      <img src={@movie.poster_url} width="200" />
      <.list>
        <:item title="Genres">
          {Enum.map_join(@movie.genres, ", ", & &1.name)}
        </:item>
        <:item title="Description">{@movie.description}</:item>
        <:item title="Director">{@movie.director.name}</:item>
        <:item title="Cast">
          {Enum.map_join(@movie.cast, ", ", & &1.name)}
        </:item>
        <:item title="Release date">{@movie.release_date}</:item>
        <:item title="Imdb rating">{@movie.imdb_rating}</:item>
        <:item title="Meta score">{@movie.meta_score}</:item>
      </.list>
    </Layouts.app>
    """
  end
end
