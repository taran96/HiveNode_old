defmodule HiveNode.TCP.Client do
  use GenServer
  require Logger

  @moduledoc """
  This module is responsible for creating and maintaining a single TCP
  connection.
  """

  def start_link([{:host, host}, {:port, port} | opts] \\ []) do
    Logger.info "Starting a #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{host: host, port: port, opts: opts})
  end

  def init(%{host: host, port: port, opts: opts} = state) do
    port_num = case port do
      port when is_number(port) -> port
      port when is_binary(port) -> 
        {num, _} = Integer.parse(port)
        num
    end
    {:ok, socket} = host
                    |> to_charlist
                    |> :gen_tcp.connect(port_num, opts)
    Logger.debug "Connected to #{host}:#{port}"
    new_state = state
                |> Map.put(:socket, socket)
                |> Map.put(:queue, :queue.new())
    Logger.debug "Created State" <> inspect(new_state)
    {:ok, new_state}
  end

  def send_message(pid, msg) do
    GenServer.call(pid, {:send, msg})
  end

  @doc """
  Sends the message to the server. This callback is technically asynchronous
  since it does not wait for the response. Instead it enqueues it to a queue.
  """
  def handle_call({:send, msg}, from, %{socket: socket, queue: queue} = state) do
    :ok = :gen_tcp.send(socket, msg)
    {:noreply, Map.put(state,:queue,:queue.in(from, queue))}
  end

  @doc """
  Returns the replies to the messages sent based on the queue.
  """
  def handle_info({:tcp, _socket, msg}, %{queue: queue} = state) do
    {{:value, client}, new_queue} = :queue.out(queue)
    GenServer.reply(client, msg)
    {:noreply, %{state | queue: new_queue}}
  end


  @doc """
  Log the exit and close the socket
  """
  def terminate(reason, state) do
    case reason do
      :normal ->
        Logger.info "Shutting down #{__MODULE__}: #{self()}"
      other -> 
        Logger.error "Shutting down #{__MODULE__}: #{inspect(self())} 
                      with reason: #{other} \nState: #{inspect(state)}"
    end
    %{socket: socket} = state
    :gen_tcp.close(socket)
    reason
  end
end
