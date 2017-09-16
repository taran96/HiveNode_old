defmodule HiveTest.MQTest.NodeAgentTest do
  use ExUnit.Case


  setup do
    agent = case Process.whereis(Hive.MQ.NodeAgent) do
      nil ->
        {:ok, pid} = Hive.MQ.NodeAgent.start_link(name: Hive.MQ.NodeAgent)
        pid
      pid -> pid
    end
    %{agent: agent}
  end

  test "adding node", %{agent: agent} do
    assert :ok == Hive.MQ.NodeAgent.add(agent, %Hive.MQ.Message.Greet{})
  end

  test "getting node", %{agent: agent} do
    {:ok, hostname} = :inet.gethostname
    old = struct(Hive.MQ.Message.Greet, Hive.MQ.NodeAgent.get(agent, hostname))
    assert :ok == Hive.MQ.NodeAgent.add(agent, old)
    refute old == Hive.MQ.NodeAgent.get(agent, hostname)
  end

  test "registering self", %{agent: agent} do
    assert :ok == Hive.MQ.NodeAgent.registerSelf(
      agent, "hive_exchange", "test_queue", "hive.node.test_node")
    refute :notfound == Hive.MQ.NodeAgent.getSelf(agent)
  end

  test "getting non existing object", %{agent: agent} do
    assert :notfound == Hive.MQ.NodeAgent.get(agent, :doesnotexist)
  end

  test "updating an entry", %{agent: agent} do
    {:ok, hostname} = :inet.gethostname
    old = struct(Hive.MQ.Message.Greet, Hive.MQ.NodeAgent.get(agent, hostname))
    assert :ok == Hive.MQ.NodeAgent.add(agent, %{old | ip_address: "CHANGED"})
    refute old == Hive.MQ.NodeAgent.get(agent, hostname)
  end

end
