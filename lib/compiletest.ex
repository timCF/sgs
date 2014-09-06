defmodule GS1 do

	use Sgs.Macro
	
	@timeout :timer.seconds(10)

	init_sgs state: :not_found, nameproc: :some_other_name, cleanup_reasons: [:my_reason, :normal] do
		{:ok , %{nameproc: :some_other_name, state: 2}}
	end
	init_sgs state: :not_found, nameproc: :my_name, cleanup_reasons: [:my_reason, :normal] do
		{:ok , %{nameproc: :my_name, state: 1}}
	end
	init_sgs state: :not_found, nameproc: name, cleanup_reasons: [:my_reason, :normal] do
		{:ok , %{nameproc: name, state: 0}}
	end

	call_sgs get_state, state: state = %{} do
		{:reply, state, state}
	end
	call_sgs kill(reason), state: state = %{} do
		{:stop, reason, true, state}
	end

	reserve_sgs nameproc: nameproc, state: state = %{nameproc: nameproc, state: 0} do
		IO.puts "HELLO , #{inspect state}"
	end
	reserve_sgs nameproc: nameproc, state: state = %{nameproc: nameproc, state: 1} do
		IO.puts "HELLO , #{inspect state}"
	end
	reserve_sgs nameproc: nameproc, state: state do
		IO.puts "HI THERE, #{inspect state}"
	end

	#end_sgs

end