defmodule BrainlessWeb.Media.Components do
  @moduledoc """
  Media components
  """
  use BrainlessWeb, :html

  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Movie

  defp format_movie_year(%Movie{start_year: start_year, end_year: end_year}) do
    case {start_year, end_year} do
      {left, nil} when is_integer(left) -> "#{left} - now"
      {_, right} when is_integer(right) -> "n/a - #{right}"
      {left, right} when is_integer(left) and is_integer(right) -> "#{left} - #{right}"
      _ -> "n/a"
    end
  end

  attr :type, :string, values: ~w(movie book), required: true
  attr :image, :string, required: true
  attr :class, :string, default: nil
  attr :score, :float, default: nil
  slot :title, required: true

  slot :prop do
    attr :label, :string
  end

  slot :inner_block

  defp media(assigns) do
    ~H"""
    <div class={["flex flex-col gap-2 relative", @class]}>
      <%!-- <%= if @score != nil do %>
        <span class="text-sm absolute top-0 right-0">[{@score}]</span>
      <% end %> --%>
      <h2 class="text-2xl flex items-center gap-2">
        <.icon :if={@type == "movie"} name="hero-film" class="size-6" />
        <.icon :if={@type == "book"} name="hero-book-open" class="size-6" />
        {render_slot(@title)}
      </h2>
      <div class="grid grid-cols-[100px_1fr] gap-4">
        <img src={@image} width="100" />

        <div class="flex flex-col gap-2">
          <dl class="grid grid-cols-[auto_1fr] gap-2 [&_dt]:font-bold [&_dt]:after:content-[':']">
            <%= for p <- @prop do %>
              <dt>{p[:label]}</dt>
              <dd>{render_slot(p)}</dd>
            <% end %>
          </dl>
          <div class="text-sm">{render_slot(@inner_block)}</div>
        </div>
      </div>
    </div>
    """
  end

  attr :movie, Movie
  attr :score, :float, default: nil
  attr :rest, :global

  def movie(assigns) do
    ~H"""
    <.media type="movie" image={@movie.image_url} score={@score} {@rest}>
      <:title>
        <div class="flex flex-col gap-2">
          <.link navigate={~p"/movies/#{@movie}"}>
            {@movie.title} ({@movie.type})
          </.link>
          <div class="text-sm">{format_movie_year(@movie)}</div>
        </div>
      </:title>
      <:prop label="Genres">{Enum.map_join(@movie.genres, ", ", & &1.name)}</:prop>
      <:prop label="Cast">{Enum.map_join(@movie.cast, ", ", & &1.name)}</:prop>
      <:prop label="Rating">{@movie.rating || "n/a"}</:prop>

      {@movie.summary}
    </.media>
    """
  end

  attr :book, Book
  attr :score, :float, default: nil
  attr :rest, :global

  def book(assigns) do
    ~H"""
    <.media type="book" image={@book.thumbnail} score={@score} {@rest}>
      <:title>{@book.title}</:title>
      <:prop label="Authors">{Enum.map_join(@book.authors, ", ", & &1.name)}</:prop>
      <:prop label="Genres">{Enum.map_join(@book.genres, ", ", & &1.name)}</:prop>
      <:prop :if={@book.published_at != nil} label="Published">{@book.published_at}</:prop>
      <:prop label="ISBN13">{@book.isbn13}</:prop>
      <:prop label="ISBN10">{@book.isbn10}</:prop>
      <:prop :if={@book.average_rating != nil} label="Average Rating">{@book.average_rating}</:prop>
      <:prop :if={@book.num_pages != nil} label="Num. pages">{@book.num_pages}</:prop>
      <:prop :if={@book.ratings_count != nil} label="Total Ratings">{@book.ratings_count}</:prop>

      {@book.description}
    </.media>
    """
  end
end
