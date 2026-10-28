--[[
MIT License

Copyright (c) 2026 Len

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local env = (getgenv and getgenv()) or _G

if env.__DiserNotify then
	pcall(function()
		env.__DiserNotify:Destroy()
	end)
end

local Notify = {}
Notify.Version = "1.4.1"

local Config = {
	Side = "Left",
	Width = 300,
	MinHeight = 58,
	Spacing = 8,
	OffsetX = 16,
	OffsetY = 16,
	MaxVisible = 6,
	Duration = 3,
	BorderThickness = 2,
	CornerRadius = 8,
	SlideTime = 0.35,
	PauseOnHover = true,
	Stack = true,
	Queue = false,
	SwipeToDismiss = true,
	Fan = false,
	FanPeek = 12,
	FanVisible = 3,
	RightClickDismiss = true,
	Theme = "Dark",
	Background = Color3.fromRGB(24, 24, 28),
	BackgroundTransparency = 0,
	StrokeColor = Color3.new(1, 1, 1),
	StrokeTransparency = 0.9,
	GlyphColor = Color3.fromRGB(20, 20, 24),
	TitleColor = Color3.fromRGB(255, 255, 255),
	TextColor = Color3.fromRGB(160, 160, 172),
	TitleFont = Enum.Font.GothamSemibold,
	TextFont = Enum.Font.Gotham,
}

Notify.Config = Config

local Types = {
	Info = Color3.fromRGB(88, 152, 255),
	Success = Color3.fromRGB(74, 200, 130),
	Warning = Color3.fromRGB(240, 176, 64),
	Error = Color3.fromRGB(240, 86, 96),
}

local THEME_KEYS = {
	"Background",
	"BackgroundTransparency",
	"StrokeColor",
	"StrokeTransparency",
	"GlyphColor",
	"TitleColor",
	"TextColor",
}

local THEME_KEY_SET = {}
for _, key in ipairs(THEME_KEYS) do
	THEME_KEY_SET[key] = true
end

local Themes = {
	Dark = {
		Background = Color3.fromRGB(24, 24, 28),
		BackgroundTransparency = 0,
		StrokeColor = Color3.new(1, 1, 1),
		StrokeTransparency = 0.9,
		GlyphColor = Color3.fromRGB(20, 20, 24),
		TitleColor = Color3.fromRGB(255, 255, 255),
		TextColor = Color3.fromRGB(160, 160, 172),
	},
	Light = {
		Background = Color3.fromRGB(250, 250, 252),
		BackgroundTransparency = 0,
		StrokeColor = Color3.new(0, 0, 0),
		StrokeTransparency = 0.88,
		GlyphColor = Color3.new(1, 1, 1),
		TitleColor = Color3.fromRGB(24, 24, 30),
		TextColor = Color3.fromRGB(90, 90, 104),
	},
	Glass = {
		Background = Color3.fromRGB(20, 22, 30),
		BackgroundTransparency = 0.35,
		StrokeColor = Color3.new(1, 1, 1),
		StrokeTransparency = 0.8,
		GlyphColor = Color3.fromRGB(20, 20, 24),
		TitleColor = Color3.fromRGB(255, 255, 255),
		TextColor = Color3.fromRGB(190, 195, 210),
	},
	Midnight = {
		Background = Color3.fromRGB(10, 12, 24),
		BackgroundTransparency = 0,
		StrokeColor = Color3.fromRGB(88, 152, 255),
		StrokeTransparency = 0.75,
		GlyphColor = Color3.fromRGB(20, 20, 24),
		TitleColor = Color3.fromRGB(235, 240, 255),
		TextColor = Color3.fromRGB(130, 140, 170),
	},
}

local function getStyle(name)
	local theme = name and Themes[name]
	local style = {}
	for _, key in ipairs(THEME_KEYS) do
		local value
		if theme then
			value = theme[key]
			if value == nil then
				value = Themes.Dark[key]
			end
		else
			value = Config[key]
		end
		style[key] = value
	end
	return style
end

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function mountGui(gui)
	local candidates = {
		function()
			return gethui and gethui()
		end,
		function()
			return game:GetService("CoreGui")
		end,
		function()
			return Players.LocalPlayer:WaitForChild("PlayerGui")
		end,
	}
	for _, getParent in ipairs(candidates) do
		local ok = pcall(function()
			local parent = getParent()
			if parent then
				gui.Parent = parent
			end
		end)
		if ok and gui.Parent then
			return true
		end
	end
	return false
end

local function measureText(text, size, font, width)
	if text == nil or text == "" then
		return 0
	end
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(width, 10000))
	end)
	if ok and result then
		return result.Y
	end
	local charsPerLine = math.max(1, math.floor(width / (size * 0.5)))
	return math.ceil(#text / charsPerLine) * (size + 2)
end

local function part(parent, w, h, x, y, rot, color, from, delay)
	local frame = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Rotation = rot or 0,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	if from then
		local goalSize = UDim2.fromOffset(w, h)
		if from == "pop" then
			frame.Size = UDim2.fromOffset(0, 0)
			TweenService:Create(
				frame,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay or 0),
				{ Size = goalSize }
			):Play()
		else
			local r = math.rad(rot or 0)
			local sign = from == "top" and 1 or -1
			frame.Size = UDim2.fromOffset(w, 0)
			frame.Position = UDim2.fromOffset(x + math.sin(r) * h / 2 * sign, y - math.cos(r) * h / 2 * sign)
			TweenService:Create(
				frame,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay or 0),
				{ Size = goalSize, Position = UDim2.fromOffset(x, y) }
			):Play()
		end
	end
	return frame
end

local function buildGlyph(parent, kind, color, animate)
	local a = animate == true
	if kind == "Success" then
		part(parent, 3, 6, 12, 18, -45, color, a and "top", 0.2)
		part(parent, 3, 13, 19, 15.5, 45, color, a and "bottom", 0.36)
	elseif kind == "Error" then
		part(parent, 3, 14, 16, 16, 45, color, a and "top", 0.2)
		part(parent, 3, 14, 16, 16, -45, color, a and "top", 0.34)
	elseif kind == "Warning" then
		part(parent, 3, 11, 16, 12.5, 0, color, a and "top", 0.2)
		part(parent, 3, 3, 16, 22, 0, color, a and "pop", 0.42)
	else
		part(parent, 3, 10, 16, 19, 0, color, a and "top", 0.2)
		part(parent, 3, 3, 16, 10, 0, color, a and "pop", 0.4)
	end
end

local function ripple(icon, color, delay)
	task.delay(delay, function()
		if not icon.Parent then
			return
		end
		local disk = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = icon,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		TweenService:Create(
			disk,
			TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(52, 52), BackgroundTransparency = 1 }
		):Play()
		Debris:AddItem(disk, 0.8)
	end)
end

local function shake(icon, baseX)
	task.delay(0.35, function()
		for _, dx in ipairs({ -4, 4, -3, 2, 0 }) do
			if not icon.Parent then
				return
			end
			TweenService:Create(
				icon,
				TweenInfo.new(0.06, Enum.EasingStyle.Sine),
				{ Position = UDim2.fromOffset(baseX + dx, icon.Position.Y.Offset) }
			):Play()
			task.wait(0.06)
		end
	end)
end

local function playIcon(icon, kind, color)
	ripple(icon, color, 0.15)
	ripple(icon, color, 0.75)
	if kind == "Error" then
		shake(icon, 14)
	end
end

local function normalizeButtons(list)
	local result = {}
	if type(list) ~= "table" then
		return result
	end
	for _, item in ipairs(list) do
		if #result >= 3 then
			break
		end
		if type(item) == "string" then
			table.insert(result, { Text = item })
		elseif type(item) == "table" then
			table.insert(result, item)
		end
	end
	return result
end

local gui = create("ScreenGui", {
	Name = "N" .. tostring(math.random(100000, 999999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
	end
end)

mountGui(gui)

local holders = {}

local POSITIONS = {
	left = { name = "Left", h = "Left", v = "Middle" },
	top = { name = "Top", h = "Center", v = "Top" },
	right = { name = "Right", h = "Right", v = "Middle" },
	bottom = { name = "Bottom", h = "Center", v = "Bottom" },
	bottomright = { name = "Bottom Right", h = "Right", v = "Bottom" },
	bottomleft = { name = "Bottom Left", h = "Left", v = "Bottom" },
	topleft = { name = "Top Left", h = "Left", v = "Top" },
	topright = { name = "Top Right", h = "Right", v = "Top" },
}

local function resolvePosition(side)
	local key = string.lower((tostring(side):gsub("[%s_%-]", "")))
	return POSITIONS[key]
end

local function layoutHolder(entry, pos)
	local holder, layout = entry.frame, entry.layout
	local ox, oy = Config.OffsetX, Config.OffsetY

	local ax, px
	if pos.h == "Right" then
		ax, px = 1, UDim.new(1, -ox)
	elseif pos.h == "Center" then
		ax, px = 0.5, UDim.new(0.5, 0)
	else
		ax, px = 0, UDim.new(0, ox)
	end

	local ay, py
	if pos.v == "Bottom" then
		ay, py = 1, UDim.new(1, -oy)
	elseif pos.v == "Top" then
		ay, py = 0, UDim.new(0, oy)
	else
		ay, py = 0.5, UDim.new(0.5, 0)
	end

	holder.AnchorPoint = Vector2.new(ax, ay)
	holder.Position = UDim2.new(px.Scale, px.Offset, py.Scale, py.Offset)
	holder.Size = UDim2.fromOffset(Config.Width, 0)
	layout.HorizontalAlignment = pos.h == "Right" and Enum.HorizontalAlignment.Right
		or pos.h == "Center" and Enum.HorizontalAlignment.Center
		or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = pos.v == "Bottom" and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top
end

local function getHolder(pos)
	local entry = holders[pos.name]
	if not entry then
		local frame = create("Frame", {
			Name = "Holder",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = gui,
		}, {
			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}),
		})
		entry = { frame = frame, layout = frame:FindFirstChildOfClass("UIListLayout") }
		holders[pos.name] = entry
		layoutHolder(entry, pos)
	end
	return entry.frame
end

local function applySide()
	for name, entry in pairs(holders) do
		layoutHolder(entry, resolvePosition(name) or POSITIONS.left)
	end
end

applySide()

local active = {}
local queue = {}
local counter = 0
local processQueue
local fanHover = {}

local function refreshFan(name)
	local list = {}
	for _, item in ipairs(active) do
		if item.PosName == name then
			table.insert(list, item)
		end
	end
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	local expanded = (fanHover[name] or 0) > 0
	for i, item in ipairs(list) do
		item.SetFan(#list - i, expanded)
	end
end

local function refreshAllFans()
	for name in pairs(holders) do
		refreshFan(name)
	end
end

function Notify:Send(opts, _fromQueue)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local kind = Types[opts.Type] and opts.Type or "Info"
	local accent = opts.Color or Types[kind]
	local duration = tonumber(opts.Duration) or Config.Duration
	local persistent = duration <= 0 or duration == math.huge
	local title = tostring(opts.Title or kind)
	local content = opts.Content and tostring(opts.Content) or ""
	local pos = resolvePosition(opts.Position) or resolvePosition(Config.Side) or POSITIONS.left
	local style = getStyle(opts.Theme)

	local function makeKey(k, t, c, a)
		return table.concat({
			pos.name,
			k,
			t,
			c,
			tostring(opts.Theme or ""),
			tostring(opts.Icon or ""),
			tostring(a),
		}, "\31")
	end

	local key = makeKey(kind, title, content, accent)

	local newMergeable = Config.Stack
		and opts.Stack ~= false
		and typeof(opts.Callback) ~= "function"
		and not (type(opts.Buttons) == "table" and #opts.Buttons > 0)

	if newMergeable then
		for _, item in ipairs(active) do
			if item.Key == key and item.IsAlive() and item.CanMerge() then
				item.Bump()
				return item
			end
		end
	end

	local mustWait = #active >= Config.MaxVisible or (Config.Queue and not _fromQueue and #queue > 0)

	if mustWait then
		if Config.Queue then
			local entry = { opts = opts, cancelled = false }
			local proxy = {}
			entry.proxy = proxy
			proxy.Dismiss = function()
				if proxy.real then
					proxy.real.Dismiss()
				else
					entry.cancelled = true
					local idx = table.find(queue, entry)
					if idx then
						table.remove(queue, idx)
					end
				end
			end
			proxy.IsAlive = function()
				if proxy.real then
					return proxy.real.IsAlive()
				end
				return not entry.cancelled
			end
			proxy.Update = function(new)
				if proxy.real then
					proxy.real.Update(new)
				elseif type(new) == "table" then
					for k, v in pairs(new) do
						entry.opts[k] = v
					end
				end
			end
			proxy.Bump = function() end
			proxy.CanMerge = function()
				return false
			end
			table.insert(queue, entry)
			return proxy
		end
		while #active >= Config.MaxVisible do
			local oldest = table.remove(active, 1)
			oldest.Dismiss()
		end
	end

	local handle = {}
	local closed = false
	local hovering = false
	local hoverCount = 0
	local fanCounted = false
	local dragging = false
	local elapsed = 0
	local conn
	local inputConns = {}

	local W = Config.Width
	local T = Config.BorderThickness
	local R = Config.CornerRadius
	local textX = 58
	local textWidth = W - textX - 14

	local curKind, curAccent = kind, accent
	local curTitle, curContent = title, content
	local curButtons = normalizeButtons(opts.Buttons)
	local hasCustomIcon = opts.Icon ~= nil and opts.Icon ~= ""

	local function hoverIn()
		hoverCount += 1
		hovering = true
	end

	local function hoverOut()
		hoverCount = math.max(0, hoverCount - 1)
		hovering = hoverCount > 0
	end

	local function computeLayout()
		local ch = measureText(curContent, 13, Config.TextFont, textWidth)
		local info = { ch = ch }
		if #curButtons > 0 then
			local textBottom = ch > 0 and 33 + ch or 31
			info.titleY = 13
			info.btnY = textBottom + 8
			info.H = info.btnY + 28 + 13
			info.iconY = (13 + textBottom) / 2
		else
			info.H = ch > 0 and math.max(Config.MinHeight, 46 + ch) or Config.MinHeight
			info.titleY = ch > 0 and 13 or math.floor((info.H - 18) / 2)
			info.iconY = info.H / 2
		end
		return info
	end

	local layoutInfo = computeLayout()
	local H = layoutInfo.H

	local swipeDir
	if pos.h == "Left" then
		swipeDir = Vector2.new(-1, 0)
	elseif pos.h == "Right" then
		swipeDir = Vector2.new(1, 0)
	else
		swipeDir = Vector2.new(0, pos.v == "Top" and -1 or 1)
	end

	local function offFor(height)
		if pos.h == "Left" then
			return UDim2.new(-1.3, 0, 0, 0)
		elseif pos.h == "Right" then
			return UDim2.new(1.3, 0, 0, 0)
		end
		local dist = height + Config.Spacing + 30
		return UDim2.fromOffset(0, pos.v == "Top" and -dist or dist)
	end

	local offPos = offFor(H)

	counter += 1
	handle.Order = counter
	handle.PosName = pos.name

	local wrapper = create("Frame", {
		Name = "Wrapper",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(W, 0),
		LayoutOrder = counter,
		Parent = getHolder(pos),
	})

	TweenService:Create(
		wrapper,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(W, H + Config.Spacing) }
	):Play()

	local body = create("Frame", {
		Name = "Body",
		BackgroundColor3 = style.Background,
		BackgroundTransparency = style.BackgroundTransparency,
		BorderSizePixel = 0,
		Position = offPos,
		Size = UDim2.fromOffset(W, H),
		Parent = wrapper,
	}, {
		corner(R),
		create("UIStroke", {
			Color = style.StrokeColor,
			Transparency = style.StrokeTransparency,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})

	local iconFrame = create("Frame", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(14, layoutInfo.iconY),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = curAccent,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = body,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	if hasCustomIcon then
		local image = opts.Icon
		if type(image) == "number" then
			image = "rbxassetid://" .. tostring(image)
		end
		create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Image = image,
			ImageColor3 = style.GlyphColor,
			ZIndex = 3,
			Parent = iconFrame,
		})
	else
		buildGlyph(iconFrame, curKind, style.GlyphColor, true)
	end

	playIcon(iconFrame, curKind, curAccent)

	local count = 1
	local badge = create("TextLabel", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = style.TitleColor,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "x1",
		TextSize = 10,
		TextColor3 = style.GlyphColor,
		Visible = false,
		ZIndex = 6,
		Parent = iconFrame,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),
	})

	local titleLabel = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textX, layoutInfo.titleY),
		Size = UDim2.fromOffset(textWidth, 18),
		Font = Config.TitleFont,
		Text = curTitle,
		TextSize = 14,
		TextColor3 = style.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = body,
	})

	local contentLabel = create("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textX, 33),
		Size = UDim2.fromOffset(textWidth, math.max(layoutInfo.ch, 1)),
		Font = Config.TextFont,
		Text = curContent,
		TextSize = 13,
		TextColor3 = style.TextColor,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = layoutInfo.ch > 0,
		ZIndex = 3,
		Parent = body,
	})

	local buttonRow = create("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textX, layoutInfo.btnY or 0),
		Size = UDim2.fromOffset(textWidth, 28),
		Visible = #curButtons > 0,
		ZIndex = 9,
		Parent = body,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})

	local hardEdge = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4999, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 1),
	})

	local strokes = {}

	local function makeHalf(isRight)
		local clip = create("Frame", {
			Name = isRight and "RightHalf" or "LeftHalf",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Position = UDim2.new(isRight and 0.5 or 0, 0, 0, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			Visible = false,
			ZIndex = 4,
			Parent = body,
		})
		local ring = create("Frame", {
			Name = "Ring",
			BackgroundTransparency = 1,
			Position = UDim2.new(isRight and -1 or 0, T, 0, T),
			Size = UDim2.new(2, -2 * T, 1, -2 * T),
			ZIndex = 4,
			Parent = clip,
		}, { corner(math.max(R - T, 0)) })
		local stroke = create("UIStroke", {
			Color = curAccent,
			Thickness = T,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = ring,
		})
		table.insert(strokes, stroke)
		local gradient = create("UIGradient", {
			Transparency = hardEdge,
			Rotation = isRight and 0 or 180,
			Parent = stroke,
		})
		return clip, gradient
	end

	local rightClip, rightGradient = makeHalf(true)
	local leftClip, leftGradient = makeHalf(false)

	local function setProgress(alpha)
		local angle = math.clamp(alpha, 0, 1) * 360
		rightGradient.Rotation = math.clamp(angle, 0, 180)
		leftGradient.Rotation = math.clamp(angle, 180, 360)
		rightClip.Visible = angle > 0
		leftClip.Visible = angle > 180
	end

	setProgress(0)

	local hit = create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
		Parent = body,
	})

	local hoveredButtons = {}

	local function buildButtons()
		for _, child in ipairs(buttonRow:GetChildren()) do
			if child:IsA("TextButton") then
				if hoveredButtons[child] then
					hoveredButtons[child] = nil
					hoverOut()
				end
				child:Destroy()
			end
		end
		for i, def in ipairs(curButtons) do
			local primary = def.Primary == true
			local idleTransparency = primary and 0 or 0.9
			local hoverTransparency = primary and 0.15 or 0.8
			local button = create("TextButton", {
				Name = "Button" .. i,
				LayoutOrder = i,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 28),
				BackgroundColor3 = primary and curAccent or style.TitleColor,
				BackgroundTransparency = idleTransparency,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Font = Config.TitleFont,
				Text = tostring(def.Text or def.Title or "Button"),
				TextSize = 13,
				TextColor3 = primary and style.GlyphColor or style.TitleColor,
				ZIndex = 10,
				Parent = buttonRow,
			}, {
				corner(6),
				create("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
				}),
			})
			button.MouseEnter:Connect(function()
				if not hoveredButtons[button] then
					hoveredButtons[button] = true
					hoverIn()
				end
				button.BackgroundTransparency = hoverTransparency
			end)
			button.MouseLeave:Connect(function()
				if hoveredButtons[button] then
					hoveredButtons[button] = nil
					hoverOut()
				end
				button.BackgroundTransparency = idleTransparency
			end)
			button.MouseButton1Click:Connect(function()
				if closed then
					return
				end
				if typeof(def.Callback) == "function" then
					task.spawn(def.Callback, handle)
				end
				if def.Close ~= false then
					handle.Dismiss()
				end
			end)
		end
	end

	buildButtons()

	local fanDepth = 0
	local fanExpanded = true
	local fanned = false
	local fanHidden = false

	local function setFanHidden(hidden)
		if fanHidden == hidden then
			return
		end
		fanHidden = hidden
		iconFrame.Visible = not hidden
		titleLabel.Visible = not hidden
		contentLabel.Visible = not hidden and layoutInfo.ch > 0
		buttonRow.Visible = not hidden and #curButtons > 0
	end

	local function fanApply(force)
		local collapsed = Config.Fan == true and not fanExpanded and fanDepth > 0
		local wasFanned = fanned
		fanned = collapsed
		local wrapHeight = H + Config.Spacing
		local bodyWidth = W
		local bodyHeight = H
		local bodyX = 0
		if collapsed then
			wrapHeight = fanDepth <= Config.FanVisible and Config.FanPeek or 0
			bodyWidth = math.floor(W * math.max(0.5, 1 - 0.06 * fanDepth))
			bodyHeight = math.min(H, 40)
			bodyX = math.floor((W - bodyWidth) / 2)
		end
		local goal = { Size = UDim2.fromOffset(bodyWidth, bodyHeight) }
		if collapsed or wasFanned then
			goal.Position = UDim2.fromOffset(bodyX, 0)
		end
		local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(wrapper, info, { Size = UDim2.fromOffset(W, wrapHeight) }):Play()
		if collapsed or wasFanned or force then
			TweenService:Create(body, info, goal):Play()
		end
		setFanHidden(collapsed)
	end

	local function applyLayout()
		layoutInfo = computeLayout()
		H = layoutInfo.H
		offPos = offFor(H)
		iconFrame.Position = UDim2.fromOffset(14, layoutInfo.iconY)
		titleLabel.Text = curTitle
		titleLabel.Position = UDim2.fromOffset(textX, layoutInfo.titleY)
		contentLabel.Text = curContent
		contentLabel.Visible = layoutInfo.ch > 0 and not fanHidden
		contentLabel.Size = UDim2.fromOffset(textWidth, math.max(layoutInfo.ch, 1))
		buttonRow.Visible = #curButtons > 0 and not fanHidden
		buttonRow.Position = UDim2.fromOffset(textX, layoutInfo.btnY or 0)
		fanApply(true)
	end

	if opts.Sound then
		pcall(function()
			local id = opts.Sound
			if type(id) == "number" then
				id = "rbxassetid://" .. tostring(id)
			end
			local sound = create("Sound", {
				SoundId = tostring(id),
				Volume = tonumber(opts.Volume) or 0.5,
				Parent = gui,
			})
			sound:Play()
			Debris:AddItem(sound, 6)
		end)
	end

	local function dismiss()
		if closed then
			return
		end
		closed = true
		if conn then
			conn:Disconnect()
		end
		for _, c in ipairs(inputConns) do
			c:Disconnect()
		end
		local idx = table.find(active, handle)
		if idx then
			table.remove(active, idx)
		end
		if fanCounted then
			fanCounted = false
			fanHover[pos.name] = math.max(0, (fanHover[pos.name] or 0) - 1)
		end
		refreshFan(pos.name)
		if typeof(opts.OnClose) == "function" then
			task.spawn(opts.OnClose)
		end
		TweenService:Create(
			body,
			TweenInfo.new(Config.SlideTime, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Position = offPos }
		):Play()
		task.delay(Config.SlideTime, function()
			if not wrapper.Parent then
				return
			end
			local shrink = TweenService:Create(
				wrapper,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.fromOffset(W, 0) }
			)
			shrink:Play()
			shrink.Completed:Wait()
			wrapper:Destroy()
		end)
		task.defer(processQueue)
	end

	handle.Dismiss = dismiss
	handle.SetFan = function(depth, expanded)
		fanDepth = depth
		fanExpanded = expanded
		fanApply(false)
	end
	handle.IsAlive = function()
		return not closed
	end
	handle.Key = key
	handle.CanMerge = function()
		return not closed
			and opts.Stack ~= false
			and typeof(opts.Callback) ~= "function"
			and #curButtons == 0
	end
	handle.Bump = function()
		if closed then
			return
		end
		count += 1
		badge.Text = "x" .. count
		badge.Visible = true
		badge.TextSize = 14
		TweenService:Create(
			badge,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = 10 }
		):Play()
		elapsed = 0
		setProgress(0)
	end
	handle.Update = function(new)
		if closed or type(new) ~= "table" then
			return
		end

		local retype = false
		if new.Type ~= nil and Types[new.Type] then
			curKind = new.Type
			curAccent = Types[curKind]
			retype = true
		end
		if new.Color ~= nil then
			curAccent = new.Color
			retype = true
		end
		if new.Title ~= nil then
			curTitle = tostring(new.Title)
		end
		if new.Content ~= nil then
			curContent = tostring(new.Content)
		end
		if new.Buttons ~= nil then
			curButtons = normalizeButtons(new.Buttons)
		end

		if retype then
			iconFrame.BackgroundColor3 = curAccent
			for _, stroke in ipairs(strokes) do
				stroke.Color = curAccent
			end
			if not hasCustomIcon then
				for _, child in ipairs(iconFrame:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end
				buildGlyph(iconFrame, curKind, style.GlyphColor, true)
			end
			playIcon(iconFrame, curKind, curAccent)
		end

		if retype or new.Buttons ~= nil then
			buildButtons()
		end

		if new.Duration ~= nil then
			duration = tonumber(new.Duration) or duration
			persistent = duration <= 0 or duration == math.huge
			elapsed = 0
			setProgress(0)
		end

		applyLayout()
		handle.Key = makeKey(curKind, curTitle, curContent, curAccent)
	end

	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local startPos
	local totalMove = 0
	local pull = 0

	hit.InputBegan:Connect(function(input)
		if closed then
			return
		end
		if isPress(input) then
			dragging = true
			startPos = input.Position
			totalMove = 0
			pull = 0
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and Config.RightClickDismiss then
			dismiss()
		end
	end)

	table.insert(
		inputConns,
		UserInputService.InputChanged:Connect(function(input)
			if not dragging or closed then
				return
			end
			if
				input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			local delta = input.Position - startPos
			totalMove = math.max(totalMove, Vector2.new(delta.X, delta.Y).Magnitude)
			if Config.SwipeToDismiss then
				pull = math.max(0, delta.X * swipeDir.X + delta.Y * swipeDir.Y)
				body.Position = UDim2.fromOffset(swipeDir.X * pull, swipeDir.Y * pull)
			end
		end)
	)

	table.insert(
		inputConns,
		UserInputService.InputEnded:Connect(function(input)
			if not dragging or not isPress(input) then
				return
			end
			dragging = false
			if closed then
				return
			end
			local limit = (swipeDir.X ~= 0 and W or H) * 0.35
			if Config.SwipeToDismiss and pull >= limit then
				dismiss()
			elseif totalMove < 6 then
				if typeof(opts.Callback) == "function" then
					task.spawn(opts.Callback, handle)
				end
				dismiss()
			else
				TweenService:Create(
					body,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.fromOffset(0, 0) }
				):Play()
			end
		end)
	)

	local hitInside = false
	hit.MouseEnter:Connect(function()
		if not hitInside then
			hitInside = true
			hoverIn()
			if not fanCounted then
				fanCounted = true
				fanHover[pos.name] = (fanHover[pos.name] or 0) + 1
			end
			refreshFan(pos.name)
		end
	end)
	hit.MouseLeave:Connect(function()
		if hitInside then
			hitInside = false
			hoverOut()
			if fanCounted then
				fanCounted = false
				fanHover[pos.name] = math.max(0, (fanHover[pos.name] or 0) - 1)
			end
			task.delay(0.12, function()
				refreshFan(pos.name)
			end)
		end
	end)

	table.insert(active, handle)
	refreshFan(pos.name)

	TweenService:Create(
		body,
		TweenInfo.new(Config.SlideTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(0, 0) }
	):Play()

	conn = RunService.Heartbeat:Connect(function(dt)
		if persistent or dragging or (hovering and Config.PauseOnHover) then
			return
		end
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		setProgress(alpha)
		if alpha >= 1 then
			dismiss()
		end
	end)

	return handle
end

processQueue = function()
	while #queue > 0 and #active < Config.MaxVisible do
		local entry = table.remove(queue, 1)
		if not entry.cancelled then
			entry.proxy.real = Notify:Send(entry.opts, true)
		end
	end
end

local function shortcut(kind)
	return function(self, title, content, duration)
		return self:Send({
			Type = kind,
			Title = title,
			Content = content,
			Duration = duration,
		})
	end
end

Notify.Info = shortcut("Info")
Notify.Success = shortcut("Success")
Notify.Warning = shortcut("Warning")
Notify.Error = shortcut("Error")

function Notify:SetConfig(newConfig)
	if type(newConfig) ~= "table" then
		return
	end

	if newConfig.Theme ~= nil then
		Notify:SetTheme(newConfig.Theme)
	end

	local customColors = false
	for key, value in pairs(newConfig) do
		if key ~= "Theme" and Config[key] ~= nil then
			if key == "Side" then
				local pos = resolvePosition(value)
				if pos then
					Config.Side = pos.name
				end
			else
				Config[key] = value
				if THEME_KEY_SET[key] then
					customColors = true
				end
			end
		end
	end

	if customColors then
		Config.Theme = "Custom"
	end

	applySide()
	refreshAllFans()
end

function Notify:SetPosition(side)
	local pos = resolvePosition(side)
	if pos then
		Config.Side = pos.name
		applySide()
	end
end

function Notify:SetTheme(name)
	local theme = Themes[name]
	if not theme then
		return
	end
	Config.Theme = name
	for _, key in ipairs(THEME_KEYS) do
		local value = theme[key]
		if value == nil then
			value = Themes.Dark[key]
		end
		Config[key] = value
	end
end

function Notify:AddTheme(name, theme)
	if type(name) ~= "string" or type(theme) ~= "table" then
		return
	end
	local copy = {}
	for _, key in ipairs(THEME_KEYS) do
		copy[key] = theme[key]
	end
	Themes[name] = copy
end

function Notify:AddType(name, color)
	if type(name) == "string" and typeof(color) == "Color3" then
		Types[name] = color
	end
end

function Notify:ClearAll()
	for _, entry in ipairs(queue) do
		entry.cancelled = true
	end
	table.clear(queue)
	for i = #active, 1, -1 do
		local item = active[i]
		if item then
			item.Dismiss()
		end
	end
end

function Notify:Destroy()
	for _, entry in ipairs(queue) do
		entry.cancelled = true
	end
	table.clear(queue)
	for _, item in ipairs(table.clone(active)) do
		item.Dismiss()
	end
	table.clear(active)
	if gui then
		gui:Destroy()
	end
end

env.__DiserNotify = Notify

return Notify
