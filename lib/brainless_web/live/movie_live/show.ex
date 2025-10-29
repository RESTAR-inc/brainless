defmodule BrainlessWeb.MovieLive.Show do
  use BrainlessWeb, :live_view

  alias Brainless.MediaLibrary

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Movie {@movie.id}
        <:subtitle>This is a movie record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/movies"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/movies/#{@movie}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit movie
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@movie.title}</:item>
        <:item title="Description">{@movie.description}</:item>
        <:item title="Poster url">{@movie.poster_url}</:item>
        <:item title="Genre">{@movie.genre}</:item>
        <:item title="Director">{@movie.director}</:item>
        <:item title="Release date">{@movie.release_date}</:item>
        <:item title="Imdb rating">{@movie.imdb_rating}</:item>
        <:item title="Meta score">{@movie.meta_score}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Movie")
     |> assign(:movie, MediaLibrary.get_movie!(id))}
  end
end
