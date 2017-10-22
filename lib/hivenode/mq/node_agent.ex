defmodule HiveNode.MQ.NodeAgent do
  use Agent
  require Logger

  @moduledoc """
  This agent is responsible to keep track of all nodes that are connected
  to the network.
  """

  @doc """
  Starts the agent with an empty map
  """
  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{} end, opts)
  end

  @doc """
  This endpoint is used to add a node to the agent. This function only
  accepts a `%HiveNode.MQ.Message.Greet{}`, otherwise it returns 
  `{:error, :wrngmsg}`. If the entry of the same hostname exists then
  the existing entry is updated. It returns `:ok` on successful additions.
  """
  def add(pid, greet_msg) do
    if greet_msg.__struct__ == HiveNode.MQ.Message.Greet do
      %{hostname: hostname} = greet_msg
      node_info = greet_msg
                  |> Map.from_struct
                  |> Map.delete(:reply)
      Logger.info "Adding #{hostname} to Node Agent: " <> inspect pid
      Agent.update(pid, &Map.put(&1, hostname, node_info))
    else
      {:error, :wrngmsg}
    end
  end


  @doc """
  This endpoint gets the requested node based on the node's hostname. A map 
  containing similar fields to the `HiveNode.MQ.Message.Greet` struct is returned
  if found. If the hostname is not found then `:notfound` is returned.
  """
  def get(pid, key) do
    getter = fn map ->
      case Map.fetch(map, key) do
        {:ok, value} -> value
        :error -> :notfound
      end
    end
    Agent.get(pid,getter)
  end

  
  defp getIPAddress() do
    interface = Application.get_env(:hivenode, :interface, "lo")
    {:ok, lst} = :inet.getifaddrs
    getIPAddress(interface, lst)
  end

  defp getIPAddress(interface, [head | tail]) do
    case head do
      {^interface, lst} ->
        {a, b, c, d} = Keyword.get(lst, :addr)
        "#{a}.#{b}.#{c}.#{d}"
      _ -> getIPAddress(interface, tail)
    end
  end

  defp getIPAddress(_interface, []) do
    :notfound
  end

  
  @doc """
  This endpoint just registers the current node in the agent's state. It takes
  parameters based on the RabbitMQ connection and is supposed to be called
  when the connection to RabbitMQ is established.
  """
  def registerSelf(pid, exchange, queue, routing_key) do
    os_version = case :os.version do
      {maj, min, _} -> "#{maj}.#{min}"
      version -> inspect version
    end
    os = case :os.type do
      {:unix, type} -> "#{type}"
      type -> inspect type
    end
    {:ok, hostname} = :inet.gethostname
    greet = %HiveNode.MQ.Message.Greet{
      routing_key: routing_key,
      hostname: hostname,
      ip_address: getIPAddress(),
      exchange: exchange,
      queue: queue,
      os: os,
      os_version: os_version,
      purpose: Application.get_env(:hivenode, :purpose, "UNKNOWN"),
    }
    add(pid, greet)
  end


  @doc """
  This endpoint is a simple get of the current node
  """
  def getSelf(pid) do
    {:ok, hostname} = :inet.gethostname
    get(pid, hostname)
  end
end

