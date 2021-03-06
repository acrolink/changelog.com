defmodule Changelog.NewsSource do
  use Changelog.Data

  alias Changelog.{Files, NewsItem, Regexp}

  schema "news_sources" do
    field :name, :string
    field :slug, :string
    field :website, :string
    field :feed, :string
    field :regex, :string

    field :icon, Files.Icon.Type

    has_many :news_items, NewsItem, foreign_key: :source_id, on_delete: :nilify_all

    timestamps()
  end

  def file_changeset(source, attrs \\ %{}), do: cast_attachments(source, attrs, ~w(icon))

  def insert_changeset(source, attrs \\ %{}) do
    source
    |> cast(attrs, ~w(name slug website regex feed))
    |> validate_required([:name, :slug, :website])
    |> validate_format(:website, Regexp.http, message: Regexp.http_message)
    |> validate_format(:feed, Regexp.http, message: Regexp.http_message)
    |> unique_constraint(:slug)
  end

  def update_changeset(source, attrs \\ %{}) do
    source
    |> insert_changeset(attrs)
    |> file_changeset(attrs)
  end

  def get_by_url(url) do
    try do
      matching(url)
      |> Repo.all
      |> List.first
    rescue
      Postgrex.Error -> nil
    end
  end

  def matching(url), do: from(s in __MODULE__, where: fragment("? ~* regex", ^url))
end
