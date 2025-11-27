defmodule BrainlessWeb.MediaLive.Index do
  use BrainlessWeb, :live_view

  import BrainlessWeb.Media.MovieComponent

  # alias Brainless.MediaLibrary
  # alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag
  alias Brainless.Rag.Document.MediaDocument

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Media")
     |> assign(:ai_response, "")
     |> assign(:media_list, [])}
  end

  @impl true
  def handle_event("delete", %{"id" => _id}, socket) do
    # movie = MediaLibrary.get_movie!(id)
    # {:ok, _} = MediaLibrary.delete_movie(movie)

    # {:noreply, stream_delete(socket, :movies, movie)}
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)
    search(socket, query)
  end

  defp search(socket, "") do
    {:noreply, socket |> assign(:media_list, [])}
  end

  defp search(socket, query) do
    case Rag.search(MediaDocument.index_name(), query) do
      {:ok, media, ai_response} ->
        {:noreply,
         socket
         |> assign(:media_list, media)
         |> assign(:ai_response, ai_response)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:media_list, [])
         |> assign(:ai_response, "")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Media
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

      <div>Found: {length(@media_list)}</div>

      <div :if={@ai_response != ""} class="whitespace-pre-wrap p-4 w-full">
        {@ai_response}
      </div>
      <ul class="flex flex-col gap-4">
        <li :for={{media_type, media} <- @media_list}>
          <.movie :if={media_type == "movie"} movie={media} />
        </li>
      </ul>

      <%!-- <.table
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
      </.table> --%>
    </Layouts.app>
    """
  end
end
