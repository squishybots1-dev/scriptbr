local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local GamestateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GamestateEvent")

-- =======================================================
-- KONFIGURASI KOORDINAT ABSOLUT
-- =======================================================
local AvailableCharacters = Workspace:WaitForChild("AvailableCharacters", 10)
local KOORDINAT_ZONA_SAH = CFrame.new(3198.69, 139.48, 731.83)   
local KOORDINAT_SPAWN_CHARA = CFrame.new(3192.13, 126.40, -2533.21) 
local JARAK_TELEPORT = Vector3.new(0, 3, 0) 

_G.AutoFarmTierActive = false 
local sedangSapuBersih = false 
local noclipConnection = nil
local flyVelocity = nil
local flyGyro = nil
local flyService = nil

-- =======================================================
-- DAFTAR DATA TIER PRIORITY
-- =======================================================
local KONFIGURASI_TIER = {
    ["Ant King"]           = 1,
    ["Rose King"]          = 1,
    ["Phantom Brute"]      = 1,
    ["Pain Phantom"]       = 1,
    ["Adult Hunter"]       = 1,
    ["Card Magician"]      = 2,
    ["Phantom Leader"]     = 2,
    ["Royal Guard"]        = 2,
    ["Chain Warden"]       = 3,
    ["Doctor Hunter"]      = 3,
    ["Whale Island Kid"]   = 4,
    ["Lightning Assassin"] = 4
}

local BATAS_MAKSIMAL = 5
local DELAY_SINKRON_POSISI = 1
local DELAY_SETELAH_CARRY = 1
local DELAY_VALIDASI_ZONA = 1
local JEDA_ANTAR_GELOMBANG = 0.3 -- Dipangkas sedikit agar lebih responsif

if not AvailableCharacters then
    warn("❌ [TIER-ENGINE-V6.2] Folder 'AvailableCharacters' tidak ditemukan!")
    return
end

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
end)

-- =======================================================
-- PEMBUATAN UI BINGKAI & TOMBOL YANG BISA DIGESER
-- =======================================================
local namaGuiSistem = "V6_2_TierFarm_Gui"
local guiLama = CoreGui:FindFirstChild(namaGuiSistem)
if guiLama then guiLama:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = namaGuiSistem
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 160, 0, 45)
MainFrame.Position = UDim2.new(0, 10, 0, 70) 
MainFrame.BackgroundTransparency = 1 
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 1, 0) 
ToggleButton.Position = UDim2.new(0, 0, 0, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
ToggleButton.BorderSizePixel = 2
ToggleButton.BorderColor3 = Color3.fromRGB(255, 0, 0) 
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.Code
ToggleButton.Text = "AUTO FARM: OFF"
ToggleButton.Parent = MainFrame

-- Engine pergeseran UI
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(MainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPosition}):Play()
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- =======================================================
-- LOGIKA FLY MODE & NOCLIP INTEGRATED
-- =======================================================
local function aktifkanFlyDanNoclip()
    if flyService then flyService:Disconnect() end
    
    flyService = RunService.RenderStepped:Connect(function()
        if _G.AutoFarmTierActive and Character then
            local rootPart = Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                -- Memastikan BodyVelocity & BodyGyro selalu ada dan aktif
                if not rootPart:FindFirstChild("AntiGravity_Velocity") then
                    local bv = Instance.new("BodyVelocity", rootPart)
                    bv.Name = "AntiGravity_Velocity"
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                end
                if not rootPart:FindFirstChild("AntiTilt_Gyro") then
                    local bg = Instance.new("BodyGyro", rootPart)
                    bg.Name = "AntiTilt_Gyro"
                    bg.CFrame = rootPart.CFrame
                    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    bg.P = 3000
                end
                
                -- Noclip paksa setiap frame
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)
end

local function matikanFlyDanNoclip()
    if flyService then flyService:Disconnect() flyService = nil end
    -- Hapus BodyVelocity dan BodyGyro dari rootPart
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = Character.HumanoidRootPart
        if rootPart:FindFirstChild("AntiGravity_Velocity") then rootPart.AntiGravity_Velocity:Destroy() end
        if rootPart:FindFirstChild("AntiTilt_Gyro") then rootPart.AntiTilt_Gyro:Destroy() end
        rootPart.CanCollide = true
    end
end

-- =======================================================
-- LOGIKA ENGINE SIKLUS UTAMA
-- =======================================================
local function dapatkanIdTarget(objek)
    if string.find(objek.Name, "-") then return objek.Name end
    local atribut = objek:GetAttributes()
    for namaAtribut, nilaiAtribut in pairs(atribut) do
        if type(nilaiAtribut) == "string" and string.find(nilaiAtribut, "-") and string.len(nilaiAtribut) >= 32 then return nilaiAtribut end
    end
    for _, anak in ipairs(objek:GetChildren()) do
        if anak:IsA("StringValue") and string.find(anak.Value, "-") and string.len(anak.Value) >= 32 then return anak.Value end
    end
    return nil
end

local function dapatkanBobotTier(objek)
    if KONFIGURASI_TIER[objek.Name] then return KONFIGURASI_TIER[objek.Name] end
    return 99 
end

local function apakahKarakterValid(objek)
    return KONFIGURASI_TIER[objek.Name] ~= nil
end

local function eksekusiSapuBersih()
    if sedangSapuBersih then return end
    sedangSapuBersih = true
    
    while _G.AutoFarmTierActive do
        local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then task.wait(0.5) continue end
        
        local daftarTarget = {}
        for _, objek in ipairs(AvailableCharacters:GetChildren()) do
            if apakahKarakterValid(objek) then
                table.insert(daftarTarget, objek)
            end
        end
        
        -- KONDISI STRATEGIS BARU: Jika folder musuh kosong, bawa karakter pulang ke spawn untuk standby aman
        if #daftarTarget == 0 then
            if (rootPart.Position - KOORDINAT_SPAWN_CHARA.Position).Magnitude > 20 then
                rootPart.CFrame = KOORDINAT_SPAWN_CHARA
                if flyGyro then flyGyro.CFrame = rootPart.CFrame end
            end
            task.wait(JEDA_ANTAR_GELOMBANG)
            continue
        end
        
        table.sort(daftarTarget, function(a, b)
            return dapatkanBobotTier(a) < dapatkanBobotTier(b)
        end)
        
        while #daftarTarget > BATAS_MAKSIMAL do
            table.remove(daftarTarget)
        end
        
        --- =======================================================
-- PROSES ANGKUT TARGET DENGAN CHECKER & RETRY
-- =======================================================
for indeks, objek in ipairs(daftarTarget) do
    local targetPart = objek:IsA("Model") and (objek.PrimaryPart or objek:FindFirstChildWhichIsA("BasePart"))
    local idTarget = dapatkanIdTarget(objek)
    
    if targetPart and idTarget then
        if not string.find(idTarget, "^{") then idTarget = "{" .. idTarget .. "}" end
        
        if not rootPart:FindFirstChild("AntiGravity_Velocity") then
            task.spawn(aktifkanFlyDanNoclip)
        end

        rootPart.CFrame = targetPart.CFrame * CFrame.new(JARAK_TELEPORT)
        if flyGyro then flyGyro.CFrame = rootPart.CFrame end
        task.wait(DELAY_SINKRON_POSISI) 
        
        -- Checker & Retry System
        local berhasil = false
        local percobaan = 0
        local MAX_RETRY = 3
        
        repeat
            percobaan = percobaan + 1
            GamestateEvent:FireServer("CarryCharacter", idTarget)
            task.wait(DELAY_SETELAH_CARRY)
            
            -- Pengecekan: Apakah target masih ada di folder? 
            -- Jika hilang (tidak ditemukan), berarti carry BERHASIL.
            if not AvailableCharacters:FindFirstChild(objek.Name) then
                berhasil = true
            else
                print("🔄 [CHECKER] Gagal carry " .. objek.Name .. ", mencoba ulang (" .. percobaan .. "/" .. MAX_RETRY .. ")")
            end
        until berhasil or percobaan >= MAX_RETRY
        
        if not berhasil then
            warn("❌ [CHECKER] Gagal mengambil " .. objek.Name .. " setelah " .. MAX_RETRY .. " kali percobaan. Melewati...")
        end
    end
end
        
        -- Teleportasi ke Zona Klaim
        rootPart.CFrame = KOORDINAT_ZONA_SAH
        if flyGyro then flyGyro.CFrame = rootPart.CFrame end
        task.wait(DELAY_VALIDASI_ZONA)
        
        GamestateEvent:FireServer("FinishCarry")
        task.wait(0.5) 
        
        -- STEP TELEPORT KE SPAWN DI SINI TELAH DIHAPUS TOTAL! 
        -- Karakter akan langsung melompat ke target berikutnya di loop atas jika daftarTarget > 0.
        
        task.wait(JEDA_ANTAR_GELOMBANG)
    end
    
    -- Pembersihan posisi jika di-OFF kan secara manual oleh user
    sedangSapuBersih = false
    
    -- Pastikan saat skrip dimatikan, karakter dikembalikan ke spawn area agar aman
    local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if rootPart then 
        rootPart.CFrame = KOORDINAT_ZONA_SAH 
    end
    
    print("🛑 [TIER-ENGINE-V6.2] Siklus selesai & Pulang ke Spawn. Skrip Non-aktif.")
    matikanFlyDanNoclip()
end

-- =======================================================
-- INTERAKSI SAKELAR BUTTON ON/OFF
-- =======================================================
ToggleButton.MouseButton1Click:Connect(function()
    _G.AutoFarmTierActive = not _G.AutoFarmTierActive
    
    if _G.AutoFarmTierActive then
        ToggleButton.Text = "AUTO FARM: ON"
        ToggleButton.BorderColor3 = Color3.fromRGB(0, 255, 0) 
        print("✅ [TIER-ENGINE-V6.2] Dinyalakan dengan Optimasi Rute Terpangkas!")
        
        aktifkanFlyDanNoclip()
        
        local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        if rootPart then 
            rootPart.CFrame = KOORDINAT_SPAWN_CHARA 
            if flyGyro then flyGyro.CFrame = rootPart.CFrame end
        end
        
        task.spawn(eksekusiSapuBersih)
    else
        ToggleButton.Text = "AUTO FARM: OFF"
        ToggleButton.BorderColor3 = Color3.fromRGB(255, 0, 0) 
        print("⏳ [TIER-ENGINE-V6.2] Menghentikan antrean... Menuju pembersihan rute aman...")
    end
end)

AvailableCharacters.ChildAdded:Connect(function(anak)
    if _G.AutoFarmTierActive and apakahKarakterValid(anak) and not sedangSapuBersih then
        task.spawn(eksekusiSapuBersih)
    end
end)
