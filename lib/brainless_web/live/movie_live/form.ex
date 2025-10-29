defmodule BrainlessWeb.MovieLive.Form do
  use BrainlessWeb, :live_view

  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage movie records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="movie-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:poster_url]} type="text" label="Poster url" />
        <.input field={@form[:genre]} type="text" label="Genre" />
        <.input field={@form[:director]} type="text" label="Director" />
        <.input field={@form[:release_date]} type="date" label="Release date" />
        <.input field={@form[:imdb_rating]} type="number" label="Imdb rating" step="any" />
        <.input field={@form[:meta_score]} type="number" label="Meta score" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Movie</.button>
          <.button navigate={return_path(@return_to, @movie)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    movie = MediaLibrary.get_movie!(id)

    socket
    |> assign(:page_title, "Edit Movie")
    |> assign(:movie, movie)
    |> assign(:form, to_form(MediaLibrary.change_movie(movie)))
  end

  defp apply_action(socket, :new, _params) do
    movie = %Movie{}

    socket
    |> assign(:page_title, "New Movie")
    |> assign(:movie, movie)
    |> assign(:form, to_form(MediaLibrary.change_movie(movie)))
  end

  @impl true
  def handle_event("validate", %{"movie" => movie_params}, socket) do
    changeset = MediaLibrary.change_movie(socket.assigns.movie, movie_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"movie" => movie_params}, socket) do
    save_movie(socket, socket.assigns.live_action, movie_params)
  end

  defp save_movie(socket, :edit, movie_params) do
    case MediaLibrary.update_movie(socket.assigns.movie, movie_params) do
      {:ok, movie} ->
        {:noreply,
         socket
         |> put_flash(:info, "Movie updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, movie))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_movie(socket, :new, movie_params) do
    case MediaLibrary.create_movie(movie_params) do
      {:ok, movie} ->
        {:noreply,
         socket
         |> put_flash(:info, "Movie created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, movie))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _movie), do: ~p"/movies"
  defp return_path("show", movie), do: ~p"/movies/#{movie}"
end
