defmodule Tigris do
    alias ExAws.S3
    def list!(prefix \\ "") do
      bucket!()
      |> S3.list_objects(prefix: prefix)
      |> ExAws.request!()
      |> then(fn %{body: %{contents: contents}} ->
        contents
      end)
    end

    def list_keys!(prefix \\ "") do
      prefix
      |> list!()
      |> Enum.map(& &1.key)
    end

    def put!(key, data) do
      bucket!()
      |> S3.put_object(key, data)
      |> ExAws.request!()
  
      :ok
    end
  
    def put_file!(key, from_filepath) do
      from_filepath
      |> S3.Upload.stream_file()
      |> Stream.map(fn chunk ->
        IO.puts("uploading...")
        chunk
      end)
      |> S3.upload(bucket!(), key)
      |> ExAws.request!()
    end
  
    def put_tons!(kv) do
      kv
      |> Task.async_stream(fn {key, value} ->
        IO.puts(key)
        put!(key, value)
      end)
      |> Stream.run()
    end
  
    def objects_to_keys(objects), do:
      objects
      |> Enum.map(& &1.key)
  
    def exterminate! do
      stream =
        bucket!()
        |> S3.list_objects()
        |> ExAws.stream!()
        |> Stream.map(& &1.key)
  
      S3.delete_all_objects(bucket!(), stream) |> ExAws.request()
  
      :exterminated
    end
  
    def presign_get(key) do
      :s3
      |> ExAws.Config.new([])
      |> S3.presigned_url(:get, bucket!(), key, [])
    end
  
    def get(key, range \\ nil) do
      opts =
        if range do
          [range: "bytes=#{range}"]
        else
          []
        end
  
      result =
        bucket!()
        |> S3.get_object(key, opts)
        |> ExAws.request()
  
      case result do
        {:ok, %{body: body}} -> body
        {:error, {:http_error, 404, _}} -> nil
        {:error, error} -> {:error, error}
      end
    end
  
    defp bucket!, do: System.fetch_env!("BUCKET_NAME")
  end
  