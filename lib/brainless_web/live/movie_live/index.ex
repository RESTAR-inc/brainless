defmodule BrainlessWeb.MovieLive.Index do
  use BrainlessWeb, :live_view

  import Ecto.Query
  import Pgvector.Ecto.Query

  alias Brainless.Repo
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Embedding

  defmodule BrainlessWeb.MovieLive.Index.SearchForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :query, :string
    end

    def changeset(search_form, attrs) do
      search_form
      |> cast(attrs, [:query])
      |> validate_required([:query])
    end
  end

  alias BrainlessWeb.MovieLive.Index.SearchForm

  @impl true
  def mount(_params, _session, socket) do
    search_form = SearchForm.changeset(%SearchForm{}, %{}) |> to_form()

    {:ok,
     socket
     |> assign(:page_title, "Listing Movies")
     |> assign(:search_form, search_form)
     |> stream(:movies, [])}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    movie = MediaLibrary.get_movie!(id)
    {:ok, _} = MediaLibrary.delete_movie(movie)

    {:noreply, stream_delete(socket, :movies, movie)}
  end

  @impl true
  def handle_event("search", %{"search_form" => %{"query" => query}}, socket) do
    query = String.trim(query)

    movies =
      if String.length(query) == 0 do
        []
      else
        {:ok, vector} = Embedding.predict(:gemini, query)

        Repo.all(
          from movie in Movie,
            order_by: l2_distance(movie.embedding, ^Pgvector.new(vector)),
            limit: 10
        )
      end

    {:noreply, socket |> stream(:movies, movies, reset: true)}
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

      <.form
        for={@search_form}
        id="search-form"
        phx-submit="search"
      >
        <.input field={@search_form[:query]} type="text" />
        <.button phx-disable-with="..." variant="primary">Search</.button>
      </.form>

      <.table
        id="movies"
        rows={@streams.movies}
        row_click={fn {_id, movie} -> JS.navigate(~p"/movies/#{movie}") end}
      >
        <:col :let={{_id, movie}} label="Poster">
          <img src={movie.poster_url} width="50" />
        </:col>
        <:col :let={{_id, movie}} label="Title">
          <div class="group hover:ring ring-primary rounded p-1">
            {movie.title}
            <div class="invisible rounded-lg p-4 absolute group-hover:visible right-0 z-50 left-1/3 bg-info-content text-info shadow-xl">
              {movie.description}
            </div>
          </div>
        </:col>
        <:col :let={{_id, movie}} label="Genre">{movie.genre}</:col>
        <:col :let={{_id, movie}} label="Director">{movie.director}</:col>
        <:col :let={{_id, movie}} label="Release date">{movie.release_date}</:col>
        <:col :let={{_id, movie}} label="Imdb rating">{movie.imdb_rating}</:col>
        <:col :let={{_id, movie}} label="Meta score">{movie.meta_score}</:col>
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
