defmodule HiveNode.MQ.ServerSupervisor do
  use Supervisor

  require Logger


  def start_link(opts \\ []) do
    
    {:ok, pid} = Supervisor.start_link(__MODULE__, :ok, opts)
    Logger.info "Starting MQ.ServerSupervisor " <> inspect(pid)
    {:ok, pid}
  end

  def init(:ok) do
    children = [
      {HiveNode.MQ.Server, [
        connection_string: Application.get_env(
          :hivenode,
          :connection_string, "amqp://guest:guest@localhost:5672"),
        node_name: Application.get_env(:hivenode, :node_name, "no_name"),
        name: HiveNode.MQ.Server]},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.info "Going DOWN: " <> inspect(pid)
    Logger.info "For: " <> inspect(reason)
    {:noreply, state}
  end 

  def handle_info({:channel_exit, _ref, reason}, state) do
    Logger.info "ERRRRRORRO: " <> inspect(reason)
    {:noreply, state}
  end
    

end
