defmodule HiveNode.MQ.Server do
  use GenServer
  require Logger

  @moduledoc """
  This module provides a GenServer to receive messages from RabbitMQ.
  """

  @doc """
  Starts the GerServer
  """
  def start_link([connection_string: connection_string,
                 node_name: node_name, name: name]) do
    Logger.info "Starting #{__MODULE__}"
    mq_settings = %{connection_string: connection_string, node_name: node_name}
    GenServer.start_link(__MODULE__, mq_settings, [name: name])
  end

  @doc """
  When the server initializes it tries to connect to the RabbitMQ server.
  It will try again and again until the connection is made. When the 
  connection is established then a unique queue is created and binded to
  the `hive_exchange` with a routing key drived from the node name. Lastly
  an entry is added to the `HiveNode.MQ.NodeAgent`, which contains information
  of the current node. After the information is added then a broadcast
  message to all the other nodes is sent containing a greet message.
  """
  def init(mq_settings) do
    {:ok, chan} = rabbitmq_connect(mq_settings)
    {:ok, mq_settings |> Map.put(:channel, chan)}
  end

  defp rabbitmq_connect(%{connection_string: conn_str,
    node_name: name} = state) do
      Logger.info "Connecting to #{conn_str}"
      case AMQP.Connection.open(conn_str) do
        {:ok, conn} ->
          {:ok, chan} = AMQP.Channel.open(conn)
          Process.monitor(chan.pid)
          AMQP.Basic.qos(chan, prefetch_count: 10)
          {:ok, %{queue: queue}} = AMQP.Queue.declare(chan, "", exclusive: true)
          AMQP.Exchange.declare(chan, "hive_exchange", :topic)
          AMQP.Queue.bind(chan, queue, "hive_exchange", routing_key: "hive.broadcast")
          AMQP.Queue.bind(chan, queue, "hive_exchange", routing_key: "hive.node." <> name)
          {:ok, _consumer_tag} = AMQP.Basic.consume(chan, queue)
          HiveNode.MQ.NodeAgent.registerSelf(
            HiveNode.MQ.NodeAgent, "hive_exchange", 
            queue, "hive.node." <> name)
          json = HiveNode.MQ.NodeAgent.getSelf(HiveNode.MQ.NodeAgent)
                    |> Map.put(:reply, true)
                    |> Poison.encode!()
          payload =  "greet+++++++++++" <> json
          AMQP.Basic.publish(chan, "hive_exchange", "hive.broadcast", payload, reply_to: "hive.node." <> name)
          {:ok, chan}
        {:error, errmsg} ->
          Logger.error inspect errmsg
          Process.sleep(5000)
          rabbitmq_connect(state)
      end
    end

    #### Client API

    @doc """
    This endpoint of the server is just to get anything from the server's
    state.
    """
    def get(pid, key) do
      GenServer.call(pid, {:get, key})
    end

    # Server API

    ## Calls

    @doc """
    Handles the `get` calls.
    """
    def handle_call({:get, key}, _from, state) do
      {:reply, Map.get(state, key), state}
    end


    @doc """
    A catch all for call messages that logs the message.
    """
    def handle_call(msg, state) do
      Logger.warn "Unhandled call: " <> inspect(msg)
      {:reply, nil, state}
    end

    ## Casts


    @doc """
    A catch all for cast messages that also logs the message.
    """
    def handle_cast(msg, state) do
      Logger.warn "Unhandled cast: " <> inspect(msg)
      {:noreply, state}
    end

    ## Info

    @doc """
    This handler receives any message from RabbitMQ Server. It creates a
    monitor for consuming the message. All messages are sent to the 
    `HiveNode.MQ.MessageHandler`. Lastly an acknowledgement is sent back the
    RabbitMQ server.
    """
    def handle_info({:basic_deliver, payload, %{delivery_tag: tag, reply_to: routing_key}}, state) do
      cleaned_payload = case payload do
        "\"" <> _rest ->
          payload
          |> String.replace("\\\"", "\"")
          |> String.replace(~r/^"|"$/, "")
        _ -> payload
      end
      Logger.debug inspect(cleaned_payload)
      Process.monitor(spawn fn -> HiveNode.MQ.MessageHandler.consume(cleaned_payload, routing_key, state) end)
      AMQP.Basic.ack(Map.get(state, :channel), tag)
      {:noreply, state}
    end

    @doc """
    This handler catches all acknowledgements from RabbitMQ.
    """
    def handle_info({:basic_consume_ok, _}, state) do
      {:noreply, state}
    end

    @doc """
    If the connection to the RabbitMQ server goes down, then reconnects
    are attempted with the same procedure as the `init` function.
    """
    def handle_info({:DOWN, _ref, :process, _pid, {:shutdown, _}}, state) do
      {:ok, chan} = rabbitmq_connect(state)
      {:noreply, Map.put(state, :channel, chan)}
    end

    @doc """
    This handler logs all processes that go down normally
    """
    def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
      Logger.debug "Process " <> inspect(pid) <> " exited normally"
      {:noreply, state}
    end

    @doc """
    This handler logs all processes that go down abnormally
    """
    def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
      Logger.error "Process " <> inspect(pid) <> " died!!"
      Logger.error "Reason: " <> inspect(reason)
      {:noreply, state}
    end

    @doc """
    This handler logs any unrecognized message.
    """
    def handle_info(msg, state) do
      Logger.warn "Unhandled message in HiveNode.MQServer"
      Logger.warn inspect(msg)
      {:noreply, state}
    end
end
