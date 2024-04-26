defmodule Podstream.Podfetcher do
    use GenServer

    require Logger

    @default_limit 1000

    def start_link(opts) do
        GenServer.start_link(Podstream.Podfetcher, opts, opts)
    end

    @impl GenServer
    def init(opts) do
        state = %{offset: Podstream.Podcasts.get_offset(), limit: opts[:limit] || @default_limit}
        {:ok, state, {:continue, :fetch}}
    end

    @impl GenServer
    def handle_continue(:fetch, state) do
        Logger.info("Fetching podcasts from offset #{state.offset} up to #{state.limit}")
        entries = Podstream.Podcasts.fetch_set(state.offset, state.limit)
        Logger.info("Fetched podcasts from offset #{state.offset} up to #{state.limit}")
        {t, _} = :timer.tc(fn ->
            entries
            |> Task.async_stream(fn entry ->
                Podstream.Podcasts.store_entry(entry)
            end, max_concurrency: System.schedulers_online() * 2, timeout: :infinity)
            |> Stream.run()
        end)
        Logger.debug("Uploaded #{Enum.count(entries)} entries in #{t/1000}ms")

        new_offset = state.offset + Enum.count(entries)
        Podstream.Podcasts.store_offset(new_offset)
        {:noreply, %{state | offset: new_offset}, {:continue, :fetch}}
    end
end