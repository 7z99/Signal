local signal = {}
signal.__index = signal


local connection = {}
connection.__index = connection

-- connection methods --

local function assert(condition, message: any?, level)
	return (condition or error(message or 'Assertion failed!', (level or 1) + 2)) :: typeof(condition)
end

function connection:Disconnect()
	assert(not self._dead, 'Connection is dead!')
	assert(self.IsConnection :: boolean, 'Attempt to call member function Connection.Disconnect on a non-connection value')
	if not self.Connected then
		return
	end
	for i, v in ipairs(self.orgSelf._connections) do
		if v == self then
			table.remove(self.orgSelf._connections, i)
		end
	end
	self.Connected = false
	setmetatable(self, nil)
end

connection.IsConnection = true

-- signal methods --

function signal.new()
	return setmetatable({
		['_connections'] = {};
		['_once'] = {};
		['_yields'] = {};
	}, signal)
end

function signal:Fire(...)
	assert(not self._dead, 'Signal is dead!')
	assert(self.IsSignal, 'Attempt to call member function Signal.Fire on a non-signal value!')
	if self._dead then
		return
	end
	for i, v in ipairs(self._connections) do
		task.spawn(v.func, ...)
	end

	for i, v in ipairs(self._yields) do
		if coroutine.status(v) == 'suspended' then
			task.spawn(v, ...)
		end
	end
	
	table.clear(self._yields)
	
	for i,v in ipairs(self._once) do
		print(v)
		task.spawn(v.func, ...)
		if not v._dead then
			v:Disconnect()
		end
	end
	table.clear(self._once)
end

function signal:Connect(func)
	assert(not self._dead, 'Signal is dead!')
	assert(self.IsSignal, 'Attempt to call member function Signal.Connect on a non-signal value!')
	local connection = setmetatable({
		func = func;
		orgSelf = self;
		Connected = true
	}, connection)

	table.insert(self._connections, connection)
	return connection
end

function signal:Wait()
	assert(not self._dead, 'Signal is dead!')
	assert(self.IsSignal, 'Attempt to call member function Signal.Wait on a non-signal value!')
	table.insert(self._yields, coroutine.running())
	return coroutine.yield()
end

function signal:Destroy()
	assert(not self._dead, 'Signal is dead!')
	assert(self.IsSignal, 'Attempt to call member function Signal.Destroy on a non-signal value!')

	for i, v in ipairs(self._connections) do
		v:Disconnect()
	end
	table.clear(self._connections)
	
	for i, v in ipairs(self._yields) do
		if coroutine.status(v) == 'suspended' then
			task.cancel(v)
		end
	end
	table.clear(self._yields)
	
	for i, v in ipairs(self._once) do
		v:Disconnect()
	end
	table.clear(self._yields)
	
	table.clear(self)
	
	setmetatable(self, nil)

	self._dead = true
end

function signal:Once(func)
	assert(not self._dead, 'Signal is dead!')
	assert(self.IsSignal, 'Attempt to call member function Signal.Connect on a non-signal value!')
	assert(func, 'No function!')
	
	local newConnection = setmetatable({
		func = func;
		orgSelf = self;
		Connected = true
	}, connection)
	table.insert(self._once, newConnection)
	
	return newConnection
end
signal.IsSignal = true

type void = nil

export type Connection = {
	Disconnect: (self: Connection) -> void;
}

export type Signal <T...> = {
	Fire: (self: any, T...) -> (...any);
	Connect: (self: any, func: (T...) -> void) -> Connection;
	Once: (self: any, func: (T...) -> void) -> Connection;
	Wait: (self: any) -> T...;
}


return signal :: { new: () -> Signal <...any> }
