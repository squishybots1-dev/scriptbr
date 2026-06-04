local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RemoteFolder = ReplicatedStorage:WaitForChild("ConsPackages"):WaitForChild("Link"):WaitForChild("RemoteEvents")
local ClaimEvent = RemoteFolder:WaitForChild("Claim2xBoost")

if PlayerGui:FindFirstChild("BoostHookMadium") then
    PlayerGui.BoostHookMadium:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BoostHookMadium"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Position = UDim2.new(0.85, -80, 0.1, 0) -- Kanan atas layar
ToggleButton.Text = "AUTO BOOST: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 16

local Corner = Instance.new("UICorner")
Corner.Parent = ToggleButton

_G.AutoBoostHook = false

local connection

local function mulaiMataMatai()
    for _, remote in pairs(RemoteFolder:GetChildren()) do
        if remote:IsA("RemoteEvent") and remote.Name ~= "Claim2xBoost" then
            connection = remote.OnClientEvent:Connect(function(...)
                if not _G.AutoBoostHook then return end
                
                local args = {...}
                for _, v in pairs(args) do
                    if type(v) == "number" then
                        ClaimEvent:FireServer(v)
                        ToggleButton.Text = "CLAIMED ID: " .. tostring(v)
                        task.wait(0.5)
                        ToggleButton.Text = "BOOST MONITORING"
                        break
                    end
                end
            end)
        end
    end
end

local guiConnection = LocalPlayer.PlayerGui.DescendantAdded:Connect(function(descendant)
    if not _G.AutoBoostHook then return end
    
    if descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
        if descendant.Name:lower():find("id") or descendant.Name:lower():find("boost") then
            ClaimEvent:FireServer(descendant.Value)
            ToggleButton.Text = "CLAIMED"
        end
    end
end)

ToggleButton.MouseButton1Down:Connect(function()
    _G.AutoBoostHook = not _G.AutoBoostHook
    
    if _G.AutoBoostHook then
        ToggleButton.Text = "BOOST MONITORING..."
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        mulaiMataMatai()
    else
        ToggleButton.Text = "AUTO BOOST: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        if connection then connection:Disconnect() end
    end
end)
