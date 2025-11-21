defmodule BrainlessWeb.MovieLive.Index do
  use BrainlessWeb, :live_view

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Movies")
     |> assign(:ai_response, nil)
     |> stream(:movies, [])}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    movie = MediaLibrary.get_movie!(id)
    {:ok, _} = MediaLibrary.delete_movie(movie)

    {:noreply, stream_delete(socket, :movies, movie)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if String.length(query) == 0 do
      {:noreply, socket |> stream(:movies, [], reset: true)}
    else
      {:ok, movies, ai_response} = Rag.predict(query)

      {:noreply,
       socket
       |> stream(:movies, movies, reset: true)
       |> assign(:ai_response, ai_response)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Movies
        <:actions>
          <.button variant="primary" navigate={~p"/movies/new"}>
            <.icon name="hero-plus" /> New Movie
          </.button>
        </:actions>
      </.header>

      <form phx-submit="search">
        <.input type="text" name="query" value="" />
        <.button phx-disable-with="..." variant="primary">Search</.button>
      </form>

      <div :if={@ai_response != nil} class="whitespace-pre-wrap p-4 w-full">
        {@ai_response}
      </div>

      <.table
        id="movies"
        rows={@streams.movies}
        row_click={fn {_id, movie} -> JS.navigate(~p"/movies/#{movie}") end}
      >
        <:col :let={{_id, movie}} label="#">
          <img src={movie.poster_url} width="50" />
        </:col>
        <:col :let={{_id, movie}} label="Title">
          <div class="group hover:ring ring-primary rounded p-1">
            <h2 class="text-lg">{movie.title}</h2>
            <p>{Movie.format_genres(movie)}</p>
            <div class="invisible rounded-lg p-4 absolute group-hover:visible right-0 z-50 left-1/3 bg-info-content text-info shadow-xl">
              {movie.description}
            </div>
          </div>
        </:col>
        <:col :let={{_id, movie}} label="Director">{movie.director.name}</:col>
        <:col :let={{_id, movie}} label="Release date">{movie.release_date}</:col>
        <:col :let={{_id, movie}} label="Score">
          <p>IMDB: {movie.imdb_rating}</p>
          <p>Meta Score: {movie.meta_score}</p>
        </:col>
        <:action :let={{_id, movie}}>
          <div class="sr-only">
            <.link navigate={~p"/movies/#{movie}"}>Show</.link>
          </div>
          <.link navigate={~p"/movies/#{movie}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, movie}}>
          <.link
            phx-click={JS.push("delete", value: %{id: movie.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
