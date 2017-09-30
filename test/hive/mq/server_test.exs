defmodule HiveTest.MQTest.ServerTest do
  use ExUnit.Case

  setup do
    Process.sleep(100)
    if Process.whereis(Hive.JobServer) == nil do
      Hive.JobServerSupervisor.start_link(name: Hive.JobServerSupervisor)
    end

    server_pid = case Process.whereis(Hive.MQ.Server) do
      nil ->
        Hive.MQ.ServerSupervisor.start_link(name: Hive.MQ.ServerSupervisor)
        Process.whereis(Hive.MQ.Server)
      pid -> pid 
    end

    init_server = &(Hive.MQ.Server.start_link([
      connection_string: Application.get_env(:hive, :connection_string, "amqp://localhost:5672"),
      node_name: Application.get_env(:hive, :node_name, &2),
      name: &1,
    ]))
    {:ok, conn} = AMQP.Connection.open(Application.get_env(:hive, :connection_string))
    {:ok, chan} = AMQP.Channel.open(conn)
    {:ok, %{queue: queue}} = AMQP.Queue.declare(chan, "", exclusive: true)
    AMQP.Basic.qos(chan, prefected_count: 10)
    AMQP.Exchange.declare(chan, "hive_exchange", :topic)
    AMQP.Queue.bind(chan, queue, "hive_exchange", routing_key: "hive.broadcast")
    AMQP.Queue.bind(chan, queue, "hive_exchange", routing_key: "hive.node.test_node")
    AMQP.Basic.consume(chan, queue)
    receive do
      {:basic_consume_ok, _} -> :ok
    end
    %{server: server_pid, client_channel: chan, client_queue: queue, init_server: init_server}
  end

  test "check for message ack", %{client_channel: chan, client_queue: queue, server: pid} do
    AMQP.Basic.publish(chan, "hive_exchange",
                       "hive.node." <> Hive.MQ.Server.get(pid, :node_name),
                       "hello",
                       reply_to: "hive.node.test_node")
    AMQP.Basic.consume(chan, queue)
    assert_receive {:basic_consume_ok, _}, 5_000
  end

  test "check for auto restart", %{server: pid} do
    Process.exit(pid, :abnormal)
    refute Process.whereis(Hive.MQ.Server) == nil
  end

  test "get function", %{server: pid} do
    refute nil == Hive.MQ.Server.get(pid, :channel)
    assert nil == Hive.MQ.Server.get(pid, :doesnotexist)
  end

  test "check if new nodes broadcast message", %{client_channel: chan, client_queue: queue, init_server: init_server} do
    Application.stop(:normal)
    {:ok, server} = init_server.(:another_server, "test_node")
    AMQP.Basic.consume(chan, queue)
    assert_receive {:basic_deliver, _payload, %{delivery_tag: _tag, reply_to: routing_key}}
    assert routing_key == "hive.node." <> Application.get_env(:hive, :node_name)
  end
end
