local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

;(function()
local NS, CS, LS, LS2 = 60, 30, 15, 24.5
local laggerPhase = 0 -- 0=off, 1=lagger, 2=lagger carry

local State = {
	speedToggled = false, laggerToggled = false, autoBatToggled = false,
	hittingCooldown = false, infJumpEnabled = false,
	antiRagdollEnabled = false, fpsBoostEnabled = false,
	antiLagEnabled = false,
	guiVisible = true,
	introEnabled = true, selectedIntroMusic = 1,
	isStealing = false, stealStartTime = nil, lastStealTick = 0,
	lastKnownHealth = 100,
	dropActive = false,
	dropBrainrotActive = false,
	autoLeftEnabled = false, autoRightEnabled = false,
	unwalkEnabled = false,
	desyncEnabled = false,
	stretchRezEnabled = false, removeAccessoriesEnabled = false,
}

local _anyKeyListening, uiLocked = false, false
local setLockUIVisual, MobilePanel, rebuildMobileButtons, resetMobileButtons
local autoSavePositions = function() end  -- no-op

-- ==========================================
-- CUSTOM THEME CONFIGURATION (BLACK & GOLD)
-- ==========================================
local THEME_TITLE = "OG HUB"
local THEME_BG_COLOR = Color3.fromRGB(15, 15, 15)       -- Sleek Deep Black
local THEME_ACCENT_COLOR = Color3.fromRGB(212, 175, 55)  -- Luxury Gold
local THEME_TEXT_COLOR = Color3.fromRGB(255, 255, 255)    -- Crisp White
local THEME_SECONDARY_BG = Color3.fromRGB(25, 25, 25)    -- Lighter Black for buttons

-- Core UI setup container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OGHub_Mobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Protect UI if execution environment supports it
if syn and syn.protect_gui then
	syn.protect_gui(ScreenGui)
	ScreenGui.Parent = game:GetService("CoreGui")
elseif gethui then
	ScreenGui.Parent = gethui()
else
	ScreenGui.Parent = game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
end

-- Base Mobile Panel Setup
MobilePanel = Instance.new("Frame")
MobilePanel.Name = "MainPanel"
MobilePanel.Size = UDim2.new(0, 320, 0, 400)
MobilePanel.Position = UDim2.new(0.5, -160, 0.5, -200)
MobilePanel.BackgroundColor3 = THEME_BG_COLOR
MobilePanel.BorderSizePixel = 2
MobilePanel.BorderColor3 = THEME_ACCENT_COLOR
MobilePanel.Active = true
MobilePanel.Draggable = true
MobilePanel.Visible = State.guiVisible
MobilePanel.Parent = ScreenGui

-- Corner smoothing
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MobilePanel

-- Header Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "HubTitle"
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = THEME_TITLE
TitleLabel.TextColor3 = THEME_ACCENT_COLOR
TitleLabel.TextSize = 22
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = MobilePanel

-- Content Scrolling Frame
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = THEME_ACCENT_COLOR
ContentFrame.Parent = MobilePanel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ContentFrame

-- Helper function to generate standardized stylized feature buttons
local function createFeatureButton(name, layoutOrder, callback)
	local Button = Instance.new("TextButton")
	Button.Name = name .. "_Btn"
	Button.Size = UDim2.new(1, 0, 0, 40)
	Button.BackgroundColor3 = THEME_SECONDARY_BG
	Button.BorderSizePixel = 1
	Button.BorderColor3 = Color3.fromRGB(50, 50, 50)
	Button.Text = "  " .. name
	Button.TextColor3 = THEME_TEXT_COLOR
	Button.TextSize = 16
	Button.Font = Enum.Font.SourceSans
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.LayoutOrder = layoutOrder
	Button.Parent = ContentFrame

	local BtnCorner = Instance.new("UICorner")
	BtnCorner.CornerRadius = UDim.new(0, 6)
	BtnCorner.Parent = Button

	local StatusIndicator = Instance.new("Frame")
	StatusIndicator.Name = "Status"
	StatusIndicator.Size = UDim2.new(0, 12, 0, 12)
	StatusIndicator.Position = UDim2.new(1, -22, 0.5, -6)
	StatusIndicator.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	StatusIndicator.BorderSizePixel = 0
	StatusIndicator.Parent = Button

	local IndicatorCorner = Instance.new("UICorner")
	IndicatorCorner.CornerRadius = UDim.new(1, 0)
	IndicatorCorner.Parent = StatusIndicator

	local toggled = false
	Button.MouseButton1Click:Connect(function()
		toggled = not toggled
		StatusIndicator.BackgroundColor3 = toggled and THEME_ACCENT_COLOR or Color3.fromRGB(150, 0, 0)
		callback(toggled)
	end)
	return Button
end

-- Populate Interactive Toggles
createFeatureButton("Speed Boost", 1, function(val)
	State.speedToggled = val
	if val then
		task.spawn(function()
			while State.speedToggled and task.wait() do
				pcall(function()
					local char = LP.Character
					if char and char:FindFirstChild("Humanoid") then
						char.Humanoid.WalkSpeed = NS
					end
				end)
			end
		end)
	end
end)

createFeatureButton("Infinite Jump", 2, function(val)
	State.infJumpEnabled = val
end)

UIS.JumpRequest:Connect(function()
	if State.infJumpEnabled then
		pcall(function()
			local char = LP.Character
			if char and char:FindFirstChildOfClass("Humanoid") then
				char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end)

createFeatureButton("Anti-Ragdoll", 3, function(val)
	State.antiRagdollEnabled = val
end)

createFeatureButton("Desync Mode", 4, function(val)
	State.desyncEnabled = val
end)

createFeatureButton("Auto Bat", 5, function(val)
	State.autoBatToggled = val
end)

createFeatureButton("Server Lagger", 6, function(val)
	State.laggerToggled = val
end)

-- Minimal Toggle/Close Utility Key bind (Mobile Compatibility)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "OGHub_Toggle"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.BackgroundColor3 = THEME_BG_COLOR
ToggleButton.BorderColor3 = THEME_ACCENT_COLOR
ToggleButton.BorderSizePixel = 2
ToggleButton.Text = "OG"
ToggleButton.TextColor3 = THEME_ACCENT_COLOR
ToggleButton.TextSize = 18
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
	State.guiVisible = not State.guiVisible
	MobilePanel.Visible = State.guiVisible
end)

-- Handle script wrapping safely
local soulLabel = Instance.new("TextLabel")
soulLabel.Size = UDim2.new(1, 0, 0, 20)
soulLabel.Position = UDim2.new(0, 0, 1, -25)
soulLabel.BackgroundTransparency = 1
soulLabel.Text = "Status: Authenticated Successfully"
soulLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
soulLabel.TextSize = 12
soulLabel.Font = Enum.Font.SourceSansItalic
soulLabel.Parent = MobilePanel

local fadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear)
local _introTween = TweenService:Create(soulLabel, fadeInfo, {TextTransparency = 0})
_introTween:Play()

end)()
