defmodule Server.External.Tcp.Worker do
  @moduledoc false

  use GenServer

  alias Server.Internal.Tcp.Worker, as: InternalWorker
  alias Server.Stores.{IPSocket, Socket}

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def send_message(pid, message), do: GenServer.cast(pid, {:message, message})

  @impl true
  def init({socket, to, key}) do
    [client_ip_raw, client_port] = String.split(to, ":")

    {:ok, {ip0, ip1, ip2, ip3}} = client_ip_raw |> to_charlist() |> :inet.parse_address()

    :inet.setopts(socket, active: false)
    send(self(), :tcp_connection_req)

    {:ok,
     %{
       socket: socket,
       key: key,
       client_ip: <<ip0, ip1, ip2, ip3>>,
       client_port: String.to_integer(client_port),
       status: 0,
       buffer: :queue.new()
     }}
  end

  @impl true
  def handle_info(
        :tcp_connection_req,
        %{client_ip: client_ip, client_port: client_port, key: key, socket: socket} = state
      ) do
    Logger.info("#{__MODULE__} send tcp connecntion request")

    client_ip
    |> send_msg(<<0x09, 0x03, key::16, client_port::16>>)
    |> case do
      :ok ->
        :inet.setopts(socket, active: true)
        {:noreply, Map.put(state, :status, 1)}

      _ ->
        send(self(), {:tcp_closed, :client_miss})
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:tcp_connection_set, %{buffer: buffer, key: key, client_ip: client_ip} = state) do
    Logger.info("#{__MODULE__} recv tcp connecntion finished")

    flush_buffer(buffer, key, client_ip)

    new_state =
      state
      |> Map.put(:status, 2)
      |> Map.put(:buffer, :queue.new())

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info(
        {:tcp, _, data},
        %{status: status, client_ip: client_ip, key: key, buffer: buffer} = state
      ) do
    Logger.info("#{__MODULE__} external recv: #{inspect(data)}")

    new_state =
      case status do
        2 ->
          # already set
          :ok = send_msg(client_ip, <<key::16>> <> data)
          state

        _ ->
          # not set, go to buffer
          Map.put(state, :buffer, :queue.in(data, buffer))
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:message, message}, %{socket: socket} = state) do
    Logger.debug("#{__MODULE__} external send: #{inspect(message)}")
    :gen_tcp.send(socket, message)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("#{__MODULE__} terminating")
    cleanup(reason, state)
    state
  end

  defp cleanup(_reason, %{client_ip: client_ip, key: key}) do
    # Cleanup whatever you need cleaned up

    send_msg(client_ip, <<0x09, 0x04, key::16>>)
    Socket.rm_socket(key)
  end

  defp send_msg(ip, msg) do
    case IPSocket.get_socket(ip) do
      nil ->
        Logger.warn("#{__MODULE__} no socket avaiable")
        {:error, :no_socket_available}

      pid ->
        InternalWorker.send_message(pid, msg)
    end
  end

  defp flush_buffer(buffer, key, ip) do
    buffer
    |> :queue.out()
    |> case do
      {{:value, msg}, buf} ->
        send_msg(ip, <<key::16>> <> msg)
        flush_buffer(buf, key, ip)

      {:empty, _} ->
        nil
    end
  end
end
