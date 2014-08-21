Sgs
===

Wrapper under ExActor.GenServer , it keep its state on disc (using ets). To use it, add :sgs to your deps and list of applications. Add this to target module

```elixir
	use Sgs.Macro
```

And than define callbacks/api like in ExActor, but with some extra options. You can use pattern matching and guards where you want:

```elixir
	init_sgs opts do
		IO.puts "HELLO, WORLD!"
		IO.puts "Init state is #{inspect state}"
		IO.puts "If state not defined in DB, set it 0"
		{:ok , 0, @timeout}
	end

	# where opts is keylist like this

	[
		nameproc: nameproc, # access to registered name of this gen_server. In sgs, gen servers are always registered!
		state: state, # access to state, if no state in storage, in becomes :not_found
		when: when, # here you can define guard expression
		cleanup_delay: cleanup_delay, # it can be integer or :infinity. When process is not alive, this value means timeout, after it reached - state of process will be deleted (only in case where process not alive now).
		cleanup_reasons: cleanup_reasons # here can be defined list of reasons of termination. If process terminate with one of them - it state will delete immediately
	]

```