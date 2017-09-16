defmodule Hive.MQ.Message do
  @moduledoc """
  This module represents all types of messages
  """

  @type t :: 
  {
    greet :: atom,
    send_info :: atom,
    request_info :: atom,
    run_job :: atom,
  }


  defmodule Greet do

    defstruct( 
      routing_key: nil,
      hostname: nil,
      ip_address: nil,
      exchange: nil,
      queue: nil,
      os: nil,
      os_version: nil,
      purpose: nil,
      reply: false
    )

    @type greet :: %Greet{
      routing_key: String.t,
      hostname: String.t,
      ip_address: String.t,
      exchange: String.t,
      queue: String.t,
      os: String.t,
      os_version: String.t,
      purpose: String.t,
      reply: false
    }

  end

  defmodule SendInfo do
    defstruct(
      requested_type: nil,
      info: nil,
      format: nil
    )

    @type send_info :: %SendInfo{
      requested_type: String.t,
      info: String.t,
      format: String.t,
    }
  end

  defmodule RequestInfo do
    defstruct(
      type: nil,
      subtype: nil
    )

    @type request_info :: %RequestInfo{
      type: String.t,
      subtype: String.t,
    }
  end

  defmodule RunJob do
    defstruct(
      name: nil,
      args: nil,
      send_return_value: nil,
      id: nil
    )

    @type run_job :: %RunJob{
      name: String.t,
      args: List,
      send_return_value: boolean,
      id: String.t,
    }
  end

  defmodule JobReturnValue do
    defstruct(
      status: nil,
      return_value: nil,
      id: nil
    )

    @type job_return_value :: %JobReturnValue{
      status: String.t,
      return_value: String.t,
      id: String.t,
    }
  end

end

