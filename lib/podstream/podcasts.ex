defmodule Podstream.Podcasts do
  require Logger
  @known_fields [
    :id,
    :url,
    :title,
    :lastUpdate,
    :link,
    :lastHttpStatus,
    :dead,
    :contentType,
    :itunesId,
    :originalUrl,
    :itunesAuthor,
    :itunesOwnerName,
    :explicit,
    :imageUrl,
    :itunesType,
    :generator,
    :newestItemPubdate,
    :language,
    :oldestItemPubdate,
    :episodeCount,
    :popularityScore,
    :priority,
    :createdOn,
    :updateFrequency,
    :chash,
    :host,
    :newestEnclosureUrl,
    :podcastGuid,
    :description,
    :category1,
    :category2,
    :category3,
    :category4,
    :category5,
    :category6,
    :category7,
    :category8,
    :category9,
    :category10,
    :newestEnclosureDuration
  ]
  @default_fields [
    :id,
    :title,
    :url,
    :lastUpdate,
    :dead,
    :episodeCount,
    :description,
    :category1,
    :category2,
    :category3
  ]

  @default_filters [
    "dead = 0",
    "category1 = 'technology'"
  ]

  def fetch_set(offset, limit) when is_integer(offset) and is_integer(limit) do
    _fields =
        @default_fields
        |> Enum.map(&Atom.to_string/1)
        |> Enum.join(",")

    filters =
        @default_filters
        |> Enum.join(" AND ")

    query = ["select * from podcasts where #{filters} limit #{limit} offset #{offset}"]
    Podstream.Db.query(query, 30_000)
  end

  @entry_prefix "podstream/entry/"
  def store_entry(entry) do
    key =
        [@entry_prefix, "#{entry.id}.json"]
        |> Path.join()

    Tigris.put!(key, Jason.encode!(entry))
    #Logger.info("Stored entry: #{key}")
  end

  @offset_key "podstream/entry_offset"
  def store_offset(offset) do
    Tigris.put!(@offset_key, to_string(offset))
    Logger.info("Stored entry offset: #{offset}")
  end

  def get_offset(default \\ 0) do
    {offset, _} =
        Tigris.get(@offset_key)
        |> Integer.parse()
    offset
  rescue
    _ -> default
  end

  def get_entries do
    Tigris.list_keys!("podstream/entry/")
    |> Task.async_stream(&Tigris.get/1)
    |> Enum.map(fn {:ok, entry} ->
      Jason.decode!(entry)
    end)
  end

  @feed_base "podstream/entry_feed/"
  def store_feed(id, feed) do
    data = Jason.encode!(feed)

    Tigris.put!(Path.join(@feed_base, "#{id}.json"), data)
  end
end
