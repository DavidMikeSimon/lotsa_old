defmodule Lotsa.UniverseJS do
  # TODO Factor out common stuff into new node_erlastic behavior
  use GenServer

  ####
  ## Client API
  ####
 
  def start(options \\ %{}) do
    GenServer.start(__MODULE__, {options}, [])
  end

  def start_link(options \\ %{}) do
    GenServer.start_link(__MODULE__, {options}, [])
  end

  def ping(js) do
    GenServer.call(js, {:ping, {}})
  end

  def stop(js) do
    GenServer.stop(js)
  end

  ####
  ## Server Callbacks
  ####

  def init({options}) do
    :gproc.reg({:n, :l, :universe_js}) # FIXME temporary

    js_path = Path.expand Path.join(["..", "universe_js", "server.js"])
    port = Port.open(
      {:spawn, "node #{js_path}"},
      [:binary, :exit_status, packet: 4]
    )
    send(port, {self(), {:command, :erlang.term_to_binary(options)}})
    {:ok, port}
  end

  def handle_cast(term, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(term)}})
    {:noreply, port}
  end

  def handle_call(term, _reply_to, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(term)}})
    response = receive do
      {^port, {:data, b}} -> :erlang.binary_to_term(b)
    end
    {:reply, response, port}
  end

  def handle_info({port, {:exit_status,0}}, port), do: {:stop, :normal, port}
  def handle_info({port, {:exit_status,_}}, port), do: {:stop, :port_terminated, port}
  def handle_info(_, port), do: {:noreply, port}
end
