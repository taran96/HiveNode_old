# hive
Elixir application to allow seamless connections between network devices. Its main purpose is to provide an easy interface for connecting multple devices together. 

## Dependencies
- Erlang 20 (other versions not tested)
- Elixir 1.5.1 (other versions not test)
- RabbitMQ Server

## To Start the application
1. Clone the repository
1. Use the `config/config.exs` file to setup configurations
1. Run `mix release.init` and then `mix release` or `MIX_ENV="prod" mix release` (for production)
1. To run the application use `_build/rel/{ENV}/rel/hive/bin/hive start`, change `{ENV}` to the env chosen when running the command above.

## Using Hive
As of now the most practical way to interact with a hive node is to use RabbitMQ to send messages. Either use the HTTP API or STOMP provided by RabbitMQ, or create your own interface to send messages to RabbitMQ. For example, a Phoenix application can be the interface for this or any other framework/language that can support RabbitMQ
 
## Custom Actions
Currently the only thing a node can do is write to a serial port. To add custom actions, just provide the function within `lib/hive/job/job_list.ex`. 


## Contributing
Look at the project [wiki](https://github.com/taran96/hive/wiki) for the project roadmap

The requirements for contributing:
- Follow best practices of Elixir / OTP programming
- Provide documentation for new implementations
- Provide tests for new implementations or bug fixes

If you think your custom job should be included in the main project, then just submit a pull request. If you want the action but don't want to create it yourself then submit an issue.
