defmodule Server.Internal.Tcp.Worker do
  @moduledoc false

  use GenServer

  alias Server.External.Tcp.Worker, as: ExternalTcpWorker
  alias Server.Stores.{IPSocket, Socket}

  require Logger

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def send_message(pid, message), do: GenServer.cast(pid, {:message, message})

  @impl true
  def init(socket: socket) do
    :inet.setopts(socket, active: true)
    {:ok, %{socket: socket}}
  end

  @impl true
  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info({:tcp, socket, <<0x09::8, 0x01::8, ip::32>> = data}, state) do
    Logger.info("#{__MODULE__} internal recv => #{inspect(data)}")
    IPSocket.add_socket(<<ip::32>>, self())
    # handshake
    :gen_tcp.send(socket, <<0x09, 0x02>>)
    {:noreply, Map.put(state, :ip, <<ip::32>>)}
  end

  @impl true
  def handle_info({:tcp, _socket, <<0x09::8, 0x03::8, key::16>>}, state) do
    case Socket.get_socket(key) do
      nil ->
        Logger.warn("#{__MODULE__} no external socket")

      pid ->
        send(pid, :tcp_connection_set)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, _socket, <<0x08::8, 0x01::8, key::16>>}, state) do
    case Socket.get_socket(key) do
      nil ->
        Logger.warn("#{__MODULE__} no external socket")

      pid ->
        send(pid, {:tcp_error, :key_error})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, _socket, <<key::16, real_data::binary>> = data}, state) do
    Logger.info("#{__MODULE__} internal recv => #{inspect(data)}")

    case Socket.get_socket(key) do
      nil ->
        Logger.warn("#{__MODULE__} no external socket")

      pid ->
        ExternalTcpWorker.send_message(pid, <<real_data::binary>>)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:message, message}, state) do
    Logger.debug("#{__MODULE__} internal send: #{inspect(message)}")
    :ok = :gen_tcp.send(state.socket, message)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("#{__MODULE__} terminating")
    cleanup(reason, state)
    state
  end

  defp cleanup(_reason, state) do
    IPSocket.rm_socket(state.ip)
  end
end
