local step = 1.5
local fastStep = 14
local interval = 0.01

local scrollAmount = 1
local fastScrollAmount = 3
local scrollInterval = 0.13

local moveTimers = {}
local scrollTimers = {}
local dragging = false

local mouseMode = hs.hotkey.modal.new({ "ctrl" }, "space")

function mouseMode:entered()
	hs.alert.show("Mouse Mode")
end

function mouseMode:exited()
	hs.alert.show("Normal Mode")
end

local function moveOnce(dx, dy)
	local p = hs.mouse.absolutePosition()

	local newPos = {
		x = p.x + dx,
		y = p.y + dy,
	}

	if dragging then
		hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDragged, newPos):post()
	else
		hs.mouse.absolutePosition(newPos)
	end
end

local function startMove(name, dx, dy)
	if moveTimers[name] then
		return
	end

	moveOnce(dx, dy)

	moveTimers[name] = hs.timer.doEvery(interval, function()
		moveOnce(dx, dy)
	end)
end

local function stopMove(name)
	if moveTimers[name] then
		moveTimers[name]:stop()
		moveTimers[name] = nil
	end
end

local function startScroll(name, amount)
	if scrollTimers[name] then
		return
	end

	hs.eventtap.scrollWheel({ 0, amount }, {}, "line")

	scrollTimers[name] = hs.timer.doEvery(scrollInterval, function()
		hs.eventtap.scrollWheel({ 0, amount }, {}, "line")
	end)
end

local function stopScroll(name)
	if scrollTimers[name] then
		scrollTimers[name]:stop()
		scrollTimers[name] = nil
	end
end

local function stopEverything()
	for name, timer in pairs(moveTimers) do
		timer:stop()
		moveTimers[name] = nil
	end

	for name, timer in pairs(scrollTimers) do
		timer:stop()
		scrollTimers[name] = nil
	end
end

local function releaseDrag()
	if dragging then
		hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, hs.mouse.absolutePosition()):post()

		dragging = false
	end
end

-- NORMAL MOVEMENT

mouseMode:bind({}, "h", function()
	startMove("h", -step, 0)
end, function()
	stopMove("h")
end)

mouseMode:bind({}, "j", function()
	startMove("j", 0, step)
end, function()
	stopMove("j")
end)

mouseMode:bind({}, "k", function()
	startMove("k", 0, -step)
end, function()
	stopMove("k")
end)

mouseMode:bind({}, "l", function()
	startMove("l", step, 0)
end, function()
	stopMove("l")
end)

-- FAST MOVEMENT

mouseMode:bind({ "shift" }, "h", function()
	startMove("H", -fastStep, 0)
end, function()
	stopMove("H")
end)

mouseMode:bind({ "shift" }, "j", function()
	startMove("J", 0, fastStep)
end, function()
	stopMove("J")
end)

mouseMode:bind({ "shift" }, "k", function()
	startMove("K", 0, -fastStep)
end, function()
	stopMove("K")
end)

mouseMode:bind({ "shift" }, "l", function()
	startMove("L", fastStep, 0)
end, function()
	stopMove("L")
end)

-- SCROLL

mouseMode:bind({}, "d", function()
	startScroll("d", -scrollAmount)
end, function()
	stopScroll("d")
end)

mouseMode:bind({}, "u", function()
	startScroll("u", scrollAmount)
end, function()
	stopScroll("u")
end)

mouseMode:bind({}, "f", function()
	startScroll("f", -fastScrollAmount)
end, function()
	stopScroll("f")
end)

mouseMode:bind({}, "b", function()
	startScroll("b", fastScrollAmount)
end, function()
	stopScroll("b")
end)

-- LEFT CLICK

mouseMode:bind({}, "i", function()
	hs.eventtap.leftClick(hs.mouse.absolutePosition())
end)

-- RIGHT CLICK

mouseMode:bind({}, "o", function()
	hs.eventtap.rightClick(hs.mouse.absolutePosition())
end)

-- VISUAL / DRAG MODE

mouseMode:bind({}, "v", function()
	local p = hs.mouse.absolutePosition()

	if dragging then
		releaseDrag()
	else
		hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, p):post()

		dragging = true
	end
end)

-- YANK / COPY

mouseMode:bind({}, "y", function()
	releaseDrag()
	hs.eventtap.keyStroke({ "cmd" }, "c")
	hs.alert.show("Yanked")
end)

-- PASTE

mouseMode:bind({}, "p", function()
	releaseDrag()
	hs.eventtap.keyStroke({ "cmd" }, "v")
end)

-- ESC = EXIT MOUSE MODE

mouseMode:bind({}, "escape", function()
	stopEverything()
	releaseDrag()
	mouseMode:exit()
end)
