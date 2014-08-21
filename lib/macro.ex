

defmodule Sgs.Macro do

	defmacro __using__(_) do
		quote do 
			use ExActor.GenServer
			import Sgs.Macro

			# init here
			defp init_return( {:ok, state}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state)
				end
				{:ok, name}
			end
			defp init_return( {:ok, state, some}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state)
				end
				{:ok, name, some}
			end
			defp init_return( some_else, _name ) do
				some_else
			end


			# cast and info here
			defp cast_info_return( {:noreply, state}, name ) do
				Exdk.put(name, state)
				{:noreply, name}
			end
			defp cast_info_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state)
				{:noreply, name, some}
			end
			defp cast_info_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, name}
			end


			#call here
			defp call_return( {:reply, reply, state}, name ) do
				Exdk.put(name, state)
				{:reply, reply, name}
			end
			defp call_return( {:reply, reply, state, some}, name ) do
				Exdk.put(name, state)
				{:reply, reply, name, some}
			end
			defp call_return( {:noreply, state}, name ) do
				Exdk.put(name, state)
				{:noreply, name}
			end
			defp call_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state)
				{:noreply, name, some}
			end
			defp call_return( {:stop, reason, reply, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, reply, name}
			end
			defp call_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, name}
			end

			terminate_sgs [] do end
			defoverridable [ terminate: 2 ]

		end
	end


	defp do_pattern_matching( argname, nil ) do
		argname
	end
	defp do_pattern_matching( argname, val_to_match ) do
		quote do unquote(argname) = unquote(val_to_match) end
	end

	defp make_guard( nil ) do
		quote do true end
	end
	defp make_guard( expr ) do
		expr
	end

	# cleanup delay =  integer | :infinity 
	defp make_cleanup_delay( nil ) do
		:infinity
	end
	defp make_cleanup_delay( num ) when is_integer(num) do
		num
	end

	# cleanup reasons = [ term ], where term - any reason for terminate
	# also term can be == :unexpected, it will cleanup state
	# in case where terminate function was not called in previous session
	defp make_cleanup_reasons( nil ) do
		[ :normal ]
	end
	defp make_cleanup_reasons( lst ) when is_list(lst) do
		lst
	end
	defp make_cleanup_reasons( some ) do
		[ some ]
	end

	#
	# TODO : daemon to cleanup
	#

	defmacro init_sgs(opts \\ [], [do: body]) do

		__name__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]
		__cleanup_delay__ = make_cleanup_delay( opts[:cleanup_delay] )
		__cleanup_reasons__ = make_cleanup_reasons( opts[:cleanup_reasons] )

		res = quote do

				defp definit_body( 	unquote(do_pattern_matching( quote do __name__ end, __name__ )),
									unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
					:erlang.register(__name__, self())
					init_return( unquote(body), __name__ )
				end

				# notice, GS is named, name !!is atom!! 
				definit name, when: is_atom(name), do: ( definit_body( name, Exdk.get(name)) )
			end
		IO.puts Macro.to_string(res)
		res
	end

	defmacro cast_sgs(funcdef, opts \\ [], [do: body]) do
		case opts[:state] do
			nil -> 
				quote do
					defcast	unquote(funcdef), state: name do
						cast_info_return(unquote(body), name) # cast and info return values are the same
					end
				end
			some_state ->
				quote do
					defcast	unquote(funcdef), state: name do
						unquote(some_state) = Exdk.get(name) # bound state with variable, defined by user 
						cast_info_return(unquote(body), name) # cast and info return values are the same
					end
				end
		end
	end

	defmacro call_sgs(funcdef, opts \\ [], [do: body]) do
		case opts[:state] do
			nil ->
				quote do
					defcall	unquote(funcdef), state: name do
						call_return(unquote(body), name)
					end
				end
			some_state ->
				quote do
					defcall	unquote(funcdef), state: name do
						unquote(some_state) = Exdk.get(name) # bound state with variable, defined by user 
						call_return(unquote(body), name)
					end
				end
		end
	end

	defmacro info_sgs(some, opts \\ [], [do: body]) do
		case opts[:state] do
			nil ->
				quote do
					definfo	unquote(some), state: name do
						cast_info_return(unquote(body), name) 
					end
				end 
			some_state ->
				quote do
					definfo	unquote(some), state: name do
						unquote(some_state) = Exdk.get(name) # bound state with variable, defined by user 
						cast_info_return(unquote(body), name) 
					end
				end 
		end
	end

	defmacro terminate_sgs opts \\ [], [do: body] do
		terminator1 = case opts[:state] do
						nil -> quote do end
						some_state -> quote do unquote(some_state) = Exdk.get(nameproc) end
					end
		terminator2 = case opts[:reason] do
						nil -> quote do end
						some_reason -> quote do unquote(some_reason) = reason end
					end
		res = quote do
			def terminate( reason, nameproc ) do
				unquote(terminator1)
				unquote(terminator2)
				unquote(body)
				if (reason == :normal) do
					Exdk.delete(nameproc)
				end
			end
		end
		#IO.puts (Macro.to_string(res))
		res
	end

	def cleanup_sgs(name) do
		Exdk.delete(name)
	end

end