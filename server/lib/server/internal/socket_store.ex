defmodule Server.Internal.SocketStore do
  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  def add_socket(ip, pid) do
    Logger.debug("#{__MODULE__}.add_socket #{inspect(ip)} => #{inspect(pid)}")
    GenServer.cast(__MODULE__, {:add_socket, ip, pid})
  end

  def rm_socket(ip) do
    Logger.debug("#{__MODULE__}.rm_socket #{inspect(ip)}")
    GenServer.cast(__MODULE__, {:rm_socket, ip})
  end

  def get_socket(ip) do
    Logger.debug("#{__MODULE__}.get_socket #{inspect(ip)}")
    GenServer.call(__MODULE__, {:get_socket, ip})
  end

  def list_sockets() do
    Logger.debug("#{__MODULE__}.list_sockets")
    GenServer.call(__MODULE__, :list_sockets)
  end

  @impl true
  def handle_cast({:add_socket, ip, pid}, state) do
    state = Map.update(state, ip, [pid], &[pid | &1])
    {:noreply, state}
  end

  @impl true
  def handle_cast({:rm_socket, ip}, state) do
    state = Map.delete(state, ip)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_socket, ip}, _from, state) do
    state
    |> Map.get(ip)
    |> case do
      nil ->
        {:reply, {:error, :not_found}, state}

      sockets ->
        {:reply, {:ok, Enum.random(sockets)}, state}
    end
  end

  @impl true
  def handle_call(:list_sockets, _from, state) do
    {:reply, state, state}
  end
end
