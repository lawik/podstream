defmodule Podstream.Db do
  use GenServer

  require Logger

  @temp Path.expand("../sqlite3vfshttp/sqlite3http-ext/httpvfs.so")
  def start_link(opts) do
    GenServer.start_link(Podstream.Db, opts, name: Podstream.Db)
  end

  def query(query, timeout \\ 10_000) do
    GenServer.call(Podstream.Db, {:query, query}, timeout)
  end

  @impl GenServer
  def init(opts) do
    # extension_path = Keyword.get(opts, :extension_path, @temp)
    # {:ok, conn} = Exqlite.Sqlite3.open("memory:")
    # :ok = Exqlite.Sqlite3.enable_load_extension(conn, true)

    # :ok =
    #   Exqlite.Sqlite3.execute(
    #     conn,
    #     "select load_extension('#{extension_path}')"
    #   )

    # {:ok, conn} = Exqlite.Sqlite3.open("file:///foo.db?vfs=httpvfs")
    {:ok, conn} = Exqlite.Sqlite3.open("file:///workbench/podcastindex_feeds.db")
    state = %{conn: conn}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:query, query}, _from, %{conn: conn} = state) do
    {t, {columns, rows}} =
        :timer.tc(fn -> 
            {:ok, stmt} = Exqlite.Sqlite3.prepare(conn, query)
            {:ok, columns} = Exqlite.Sqlite3.columns(conn, stmt)
            {:ok, rows} = Exqlite.Sqlite3.fetch_all(conn, stmt)
            :ok = Exqlite.Sqlite3.release(conn, stmt)
            {columns, rows}
        end)

    Logger.debug("Full exqlite query took #{t/1000}ms")
    columns = Enum.map(columns, &String.to_atom/1)

    entries =
      rows
      |> Enum.map(fn row ->
        columns
        |> Enum.zip(row)
        |> Map.new()
      end)

    {:reply, entries, state}
  end
end
