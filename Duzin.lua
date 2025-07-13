-- Duzin Auto Pet Hub v1.0

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local WALK_SPEED = 40
local DISTANCE_TO_COIN = 20
local COIN_COLLECT_RANGE = 10

local badPets = {
    "PetRuim1",
    "PetRuim2"
}

local petFolder = workspace:WaitForChild("Pets")
local coinsFolder = workspace:WaitForChild("Coins")

local petControllerEnabled = false
local coinCollectorEnabled = false
local autoBuyerEnabled = false

local petControllerConnection
local coinCollectorConnection
local autoBuyerConnection

local function movePetsToClosestCoin()
    for _, pet in pairs(petFolder:GetChildren()) do
        if pet:IsA("Model") and pet.PrimaryPart then
            local closestCoin, closestDist = nil, math.huge
            for _, coin in pairs(coinsFolder:GetChildren()) do
                if coin:IsA("BasePart") then
                    local dist = (coin.Position - pet.PrimaryPart.Position).Magnitude
                    if dist < closestDist and dist <= DISTANCE_TO_COIN then
                        closestCoin = coin
                        closestDist = dist
                    end
                end
            end
            if closestCoin then
                local direction = (closestCoin.Position - pet.PrimaryPart.Position).Unit
                local dt = RunService.Heartbeat:Wait()
                local newPos = pet.PrimaryPart.Position + direction * WALK_SPEED * dt
                pet:SetPrimaryPartCFrame(CFrame.new(newPos))
            end
        end
    end
end

local function startPetController()
    if petControllerConnection then return end
    petControllerEnabled = true
    petControllerConnection = RunService.Heartbeat:Connect(function()
        if petControllerEnabled then
            movePetsToClosestCoin()
        end
    end)
end

local function stopPetController()
    petControllerEnabled = false
    if petControllerConnection then
        petControllerConnection:Disconnect()
        petControllerConnection = nil
    end
end

local function collectCoins()
    for _, coin in pairs(coinsFolder:GetChildren()) do
        if coin:IsA("BasePart") then
            local dist = (coin.Position - character.HumanoidRootPart.Position).Magnitude
            if dist < COIN_COLLECT_RANGE then
                coin:Destroy()
            end
        end
    end
end

local function startCoinCollector()
    if coinCollectorConnection then return end
    coinCollectorEnabled = true
    coinCollectorConnection = RunService.Heartbeat:Connect(function()
        if coinCollectorEnabled then
            collectCoins()
        end
    end)
end

local function stopCoinCollector()
    coinCollectorEnabled = false
    if coinCollectorConnection then
        coinCollectorConnection:Disconnect()
        coinCollectorConnection = nil
    end
end

local function buyBestPets()
    local buyEvent = game.ReplicatedStorage:FindFirstChild("BuyPetEvent")
    if buyEvent then
        buyEvent:FireServer("BestPetName")
    end
end

local function deleteBadPets()
    for _, pet in pairs(petFolder:GetChildren()) do
        if pet:IsA("Model") then
            for _, badName in pairs(badPets) do
                if pet.Name == badName then
                    pet:Destroy()
                end
            end
        end
    end
end

local function startAutoBuyer()
    if autoBuyerConnection then return end
    autoBuyerEnabled = true
    autoBuyerConnection = RunService.Heartbeat:Connect(function()
        if autoBuyerEnabled then
            buyBestPets()
            deleteBadPets()
        end
    end)
end

local function stopAutoBuyer()
    autoBuyerEnabled = false
    if autoBuyerConnection then
        autoBuyerConnection:Disconnect()
        autoBuyerConnection = nil
    end
end

local PlayerGui = player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DuzinTesteHub"
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Parent = ScreenGui

local function createToggle(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = Frame

    local enabled = false

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = text .. (enabled and ": ON" or ": OFF")
        callback(enabled)
    end)
end

createToggle("Pets Andando", 10, function(enabled)
    if enabled then
        startPetController()
    else
        stopPetController()
    end
end)

createToggle("Coletar Moedas", 50, function(enabled)
    if enabled then
        startCoinCollector()
    else
        stopCoinCollector()
    end
end)

createToggle("Auto Comprar Pets", 90, function(enabled)
    if enabled then
        startAutoBuyer()
    else
        stopAutoBuyer()
    end
end)
