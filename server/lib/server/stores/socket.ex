defmodule Server.Stores.Socket do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  def add_socket(sock_key, pid) do
    Logger.debug("#{__MODULE__}.add_socket #{inspect(sock_key)} => #{inspect(pid)}")
    GenServer.cast(__MODULE__, {:add_socket, sock_key, pid})
  end

  def rm_socket(sock_key) do
    Logger.debug("#{__MODULE__}.rm_socket #{inspect(sock_key)}")
    GenServer.cast(__MODULE__, {:rm_socket, sock_key})
  end

  def get_socket(sock_key) do
    Logger.debug("#{__MODULE__}.get_socket #{inspect(sock_key)}")
    GenServer.call(__MODULE__, {:get_socket, sock_key})
  end

  def list_sockets() do
    Logger.debug("#{__MODULE__}.list_sockets")
    GenServer.call(__MODULE__, :list_sockets)
  end

  @impl true
  def handle_cast({:add_socket, sock_key, pid}, state) do
    state = Map.put(state, sock_key, pid)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:rm_socket, sock_key}, state) do
    state = Map.delete(state, sock_key)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_socket, sock_key}, _from, state) do
    state
    |> Map.get(sock_key)
    |> case do
      nil ->
        {:reply, {:error, :not_found}, state}

      socket ->
        {:reply, {:ok, socket}, state}
    end
  end

  @impl true
  def handle_call(:list_sockets, _from, state) do
    {:reply, state, state}
  end
end
