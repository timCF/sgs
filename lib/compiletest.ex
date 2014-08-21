defmodule CompileTest do

	use Sgs.Macro
	
	@timeout :timer.seconds(10)

	init_sgs state: :not_found, nameproc: name do
		IO.puts "HELLO, #{name}!"
		IO.puts "Can't found your state :("
		IO.puts "Set it 0"
		{:ok , 0, @timeout}
	end

	init_sgs state: state, nameproc: name, when: (name == :myself) do
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

	info_sgs :timeout, state: some_state = 3 do
		IO.inspect 3
		IO.puts "timeout!"
		IO.puts "auto increment of state: #{some_state+1}"
		{:noreply, some_state+1, @timeout}
	end

	info_sgs :timeout, state: some_state = 2 do
		IO.inspect 2
		IO.puts "timeout!"
		IO.puts "auto increment of state: #{some_state+1}"
		{:noreply, some_state+1, @timeout}
	end

	info_sgs :timeout, state: some_state = 0 do
		IO.inspect 0
		IO.puts "timeout!"
		IO.puts "auto increment of state: #{some_state+1}"
		{:noreply, some_state+1, @timeout}
	end

	info_sgs :timeout, state: some_state = 1 do
		IO.inspect 1
		IO.puts "timeout!"
		IO.puts "auto increment of state: #{some_state+1}"
		{:noreply, some_state+1, @timeout}
	end


	terminate_sgs reason: reason, state: state do
		IO.puts "Terminating becouse of reason #{inspect reason}, when state was #{inspect state}"
	end

end