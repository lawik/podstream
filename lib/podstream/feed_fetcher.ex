defmodule Podstream.FeedFetcher do
    use GenServer

    require Logger

    def start_link(opts) do
        GenServer.start_link(Podstream.FeedFetcher, opts, opts)
    end

    @impl GenServer
    def init(_) do
        state = %{}
        {:ok, state, {:continue, :fetch}}
    end

    @impl GenServer
    def handle_continue(:fetch, state) do
        entries = Podstream.Podcasts.get_entries()
        Logger.info("Fetching podcast feeds: #{Enum.count(entries)}")
        {t, _} = :timer.tc(fn ->
            entries
            #|> Enum.take(2)
            |> Task.async_stream(fn %{"id" => id, "url" => url} ->
                Logger.info("URL: #{url}")
                result =
                    Finch.build(:get, url)
                    |> Finch.request(Podstream.Finch)

                case result do
                    {:ok, %{status: 200, body: body}} ->
                        %{id: id, url: url, body: body}
                    other ->
                        Logger.warning("URL gave special response: #{url}\n#{inspect(other)}")
                        nil
                end
            end, max_concurrency: System.schedulers_online() * 2, timeout: :infinity)
            |> Stream.filter(fn result ->
                case result do
                    {:ok, out} when not is_nil(out) -> true
                    _ -> false
                end
            end)
            |> Task.async_stream(fn {:ok, %{id: id, url: url, body: feed_body}} ->
                Logger.info("Parsing #{id}")
                try do
                    case Gluttony.parse_string(feed_body) do
                        {:ok, feed} ->
                            Logger.info("""
                            ======= #{feed.feed.title} =======")
                            URL: #{url}")
                            Entries: #{Enum.count(feed.entries)}
                            """)
                            Podstream.Podcasts.store_feed(id, feed)
                        _ -> nil
                    end
                rescue
                    e ->
                        Logger.error("Failed to parse feed string: #{inspect(e)}")
                end
            end, timeout: :infinity)
            |> Stream.run()
        end)
        
        {:noreply, state}
    end
end