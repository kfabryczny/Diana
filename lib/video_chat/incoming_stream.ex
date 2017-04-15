defmodule VideoChat.IncomingStream do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    incoming_port = Application.get_env(:video_chat, :incoming_port)
    IO.puts "---> Listening on port #{incoming_port} for incoming stream"

    {:ok, _socket} = :gen_udp.open(incoming_port, [:binary,
      {:active, true}, {:buffer, 1024}
      ])
  end

  # Incoming streaming data from the webcam.
  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    # IO.inspect "---> Received #{byte_size(data)} bytes from #{_port}"

    # Write to the bucket
    VideoChat.EncodingBucket.add data
    VideoChat.EncodingBucket.push data

    {:noreply, state}
  end

  def handle_info({_, _socket}, state) do
    {:noreply, state}
  end

  # Optional format
  defp parse_message(message) do
    # channel: 001
    # resolution: 1 | 2 | 3 | 4
    # size: 4000
    # data: binary
    <<
      channel :: little-unsigned-integer-size(24),
      resolution :: little-unsigned-integer-size(8),
      size :: little-unsigned-integer-size(8),
      data :: bits
    >> = message

    %{
      channel: channel,
      resolution: resolution,
      size: size,
      data: data
    }
  end
end
