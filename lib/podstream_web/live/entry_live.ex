defmodule PodstreamWeb.EntryLive do
    use PodstreamWeb, :live_view

    def mount(_, _, socket) do
        Phoenix.PubSub.subscribe(Podstream.PubSub, "podcasts")
        {:ok, assign(socket, entries: [], entry_count: 0, feeds: [], feed_count: 0, status: %{}, feed_percentage: 0)}
    end

    def render(assigns) do
        ~H"""
        <div>Started: <%= @entry_count %></div>
        <div>Feed fetched: <%= @feed_count %></div>
        <div :for={{id, title} <- Enum.take(@entries, 1)}>Starting: <%= title %> (<%= id %>)</div>
        <div :for={{id, title} <- Enum.take(@feeds, 1)}><%= title %> (<%= id %>)</div>
        <div class="w-full rounded overflow-hidden bg-slate-300">
            <div 
                style={"width: #{@feed_percentage}%"}
                class="block h-4 bg-amber-300"
            ></div>
        </div>
        <!--<div class="flex flex-wrap gap-1">
        <span :for={{id, status} <- Enum.sort_by(@status, & elem(&1, 0), :desc) |> Enum.take(1000)} class="w-1 h-1 inline-block">
            <span :if={status == :started} class="w-1 h-1 block bg-slate-300" />
            <span :if={status == :feed_fetched} class="w-1 h-1 block bg-amber-300" />
        </span>
        </div>-->
        <%!-- <div class="flex">
            <section class="w-1/2">
                <h2>Entries</h2>
                <ul :for={{id, title} <- @entries}>
                    <li><%= title %> (<%= id %>)</li>
                </ul>
            </section>
            <section class="w-1/2">
                <h2>Feeds</h2>
                <ul :for={{id, title} <- @feeds}>
                    <li><%= title %> (<%= id %>)</li>
                </ul>
            </section>
        </div> --%>
        """
    end

    def handle_info({:entry, id, title}, socket) do
        {:noreply, assign(
            socket,
            entries: Enum.take([{id, title} | socket.assigns.entries], 25),
            entry_count: socket.assigns.entry_count + 1,
            feed_percentage: feed_percentage(socket.assigns)
            #status: Map.put(socket.assigns.status, id, :started)
        )}
    end
    def handle_info({:feed, id, title}, socket) do
        {:noreply, assign(
            socket,
            feeds: Enum.take([{id, title} | socket.assigns.feeds], 25),
            feed_count: socket.assigns.feed_count + 1,
            feed_percentage: feed_percentage(socket.assigns)
            #status: Map.put(socket.assigns.status, id, :feed_fetched)
        )}
    end

    defp feed_percentage(assigns) do
        if assigns.entry_count == 0 do
            0
        else
            cent = (assigns.entry_count / 100)
            feed_value = assigns.feed_count / cent
            feed_value
        end
    end
end