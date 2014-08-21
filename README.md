Sgs
===

Wrapper under ExActor.GenServer. It defines gen_server which keep its state on disc (using ets). To use it, add :sgs to your deps and list of applications. Add this to target module

```elixir
	use Sgs.Macro
```

And than define callbacks/api like in ExActor, but with some extra options. You can use pattern matching and guards where you want:

```elixir
	init_sgs opts do
		any_expression
	end

	# where opts is keylist like this

	[
		nameproc: nameproc, # access to registered name of this gen_server. 
		# In sgs, gen servers are always registered!
		state: state, # access to state, if no state in storage, in becomes :not_found
		when: when, # here you can define guard expression
		cleanup_delay: cleanup_delay, # it can be integer or :infinity. 
		# When process is not alive, this value means timeout, after it reached - 
		# state of process will be deleted (only in case where process not alive now).
		# By default cleanup_delay == :infinity
		cleanup_reasons: cleanup_reasons # here can be defined list of reasons of termination. 
		# If process terminate with one of them - its state will be deleted immediately. 
		# By default, cleanup_reasons == [:normal]
		# In this list can be extra reason :unexpected - it means state cleanup in case of
		# terminate function was not called in previous gen_server start.
	]

	# example :

	init_sgs state: :not_found, nameproc: name do
		IO.puts "HELLO, #{name}!"
		IO.puts "Can't found your state :("
		IO.puts "Set it 0"
		{:ok , 0, @timeout}
	end

	init_sgs state: state, nameproc: name, when: (name == :myself), cleanup_reasons: [:unexpected] do
		IO.puts "HELLO, here i am!"
		IO.puts "Init state is #{inspect state}"
		IO.puts "If state not defined in DB, set it 0"
		{:ok , 0, @timeout}
	end

	init_sgs state: state, nameproc: name do
		IO.puts "HELLO, #{name}!"
		IO.puts "Init state is #{inspect state}"
		IO.puts "If state not defined in DB, set it 0"
		{:ok , 0, @timeout}
	end

```

In call_sgs, cast_sgs and info_sgs macro, you can use options: state, nameproc and when. Example :

```elixir
	cast_sgs reset_state do
		IO.puts "set state to 0"
		{:noreply, 0, @timeout}
	end

	call_sgs add_to_state(arg1), when: arg1 >= 0, state: state do
		IO.puts "args are:"
		IO.inspect arg1
		IO.puts "state now is #{state+10}"
		{:reply, state+10, state+10, @timeout}
	end

	info_sgs :timeout, state: some_state do
		IO.puts "timeout!"
		IO.puts "auto increment of state: #{some_state+1}"
		{:noreply, some_state+1, @timeout}
	end
```

In terminate_sgs macro, you can use options: state, nameproc, when and reason. Example :

```elixir
	terminate_sgs reason: reason, state: state do
		IO.puts "Terminating becouse of reason #{inspect reason}, when state was #{inspect state}"
	end
```