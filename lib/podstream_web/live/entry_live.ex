defmodule PodstreamWeb.EntryLive do
    use PodstreamWeb, :live_view

    def mount(_, _, socket) do
        Phoenix.PubSub.subscribe(Podstream.PubSub, "podcasts")
        {:ok, assign(socket, entries: [])}
    end

    def render(assigns) do
        ~H"""
        <h2>Entries</h2>
        <ul :for={{id, title} <- @entries}>
            <li><%= title %> (<%= id %>)</li>
        </ul>
        """
    end

    def handle_info({:entry, id, title}, socket) do
        {:noreply, assign(socket, entries: Enum.take([{id, title} | socket.assigns.entries], 25))}
    end
end