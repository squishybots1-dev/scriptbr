-- =======================================================
-- AUTO-FARM ENGINE [CLEAN - NO UI - READY FOR GITHUB]
-- =======================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local GamestateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GamestateEvent")

-- Konfigurasi
local AvailableCharacters = Workspace:WaitForChild("AvailableCharacters", 10)
local KOORDINAT_ZONA_SAH = CFrame.new(3198.69, 139.48, 731.83)
local KOORDINAT_SPAWN_CHARA = CFrame.new(3192.13, 126.40, -2533.21)
local JARAK_TELEPORT = Vector3.new(0, 3, 0)

-- Pastikan variabel global ada
_G.AutoFarmTierActive = _G.AutoFarmTierActive or true 
local sedangSapuBersih = false 
local flyService = nil

local KONFIGURASI_TIER = {
    ["Ant King"] = 1, ["Rose King"] = 1, ["Phantom Brute"] = 1, ["Pain Phantom"] = 1, ["Adult Hunter"] = 1,
    ["Card Magician"] = 2, ["Phantom Leader"] = 2, ["Royal Guard"] = 2,
    ["Chain Warden"] = 3, ["Doctor Hunter"] = 3, ["Whale Island Kid"] = 4, ["Lightning Assassin"] = 4
}

local BATAS_MAKSIMAL = 5
local DELAY_SINKRON_POSISI = 0.15
local DELAY_SETELAH_CARRY = 0.15
local DELAY_VALIDASI_ZONA = 0.15
local JEDA_ANTAR_GELOMBANG = 0.3

-- Fungsi Fly & Noclip
local function aktifkanFlyDanNoclip()
    if flyService then flyService:Disconnect() end
    flyService = RunService.RenderStepped:Connect(function()
        if _G.AutoFarmTierActive and Character then
            local rootPart = Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                if not rootPart:FindFirstChild("AntiGravity_Velocity") then
                    local bv = Instance.new("BodyVelocity", rootPart); bv.Name = "AntiGravity_Velocity"; bv.Velocity = Vector3.new(0, 0, 0); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    local bg = Instance.new("BodyGyro", rootPart); bg.Name = "AntiTilt_Gyro"; bg.CFrame = rootPart.CFrame; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 3000
                end
                for _, part in pairs(Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
            end
        end
    end)
end

local function matikanFlyDanNoclip()
    if flyService then flyService:Disconnect() flyService = nil end
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = Character.HumanoidRootPart
        if rootPart:FindFirstChild("AntiGravity_Velocity") then rootPart.AntiGravity_Velocity:Destroy() end
        if rootPart:FindFirstChild("AntiTilt_Gyro") then rootPart.AntiTilt_Gyro:Destroy() end
        rootPart.CanCollide = true
    end
end

-- Engine Utama
local function dapatkanIdTarget(objek)
    if string.find(objek.Name, "-") then return objek.Name end
    local atribut = objek:GetAttributes()
    for _, v in pairs(atribut) do if type(v) == "string" and string.find(v, "-") and string.len(v) >= 32 then return v end end
    for _, anak in ipairs(objek:GetChildren()) do if anak:IsA("StringValue") and string.find(anak.Value, "-") and string.len(anak.Value) >= 32 then return anak.Value end end
    return nil
end

local function eksekusiSapuBersih()
    if sedangSapuBersih then return end
    sedangSapuBersih = true
    aktifkanFlyDanNoclip()
    
    while _G.AutoFarmTierActive do
        local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then task.wait(0.5) continue end
        
        local daftarTarget = {}
        for _, objek in ipairs(AvailableCharacters:GetChildren()) do
            if KONFIGURASI_TIER[objek.Name] then table.insert(daftarTarget, objek) end
        end
        
        if #daftarTarget == 0 then
            rootPart.CFrame = KOORDINAT_SPAWN_CHARA
            task.wait(JEDA_ANTAR_GELOMBANG)
            continue
        end
        
        table.sort(daftarTarget, function(a, b) return KONFIGURASI_TIER[a.Name] < KONFIGURASI_TIER[b.Name] end)
        while #daftarTarget > BATAS_MAKSIMAL do table.remove(daftarTarget) end
        
        for _, objek in ipairs(daftarTarget) do
            if not _G.AutoFarmTierActive then break end -- Exit loop jika dimatikan
            
            local targetPart = objek.PrimaryPart or objek:FindFirstChildWhichIsA("BasePart")
            local idTarget = dapatkanIdTarget(objek)
            if targetPart and idTarget then
                if not string.find(idTarget, "^{") then idTarget = "{" .. idTarget .. "}" end
                rootPart.CFrame = targetPart.CFrame * CFrame.new(JARAK_TELEPORT)
                task.wait(DELAY_SINKRON_POSISI)
                
                local berhasil = false
                local percobaan = 0
                repeat
                    percobaan = percobaan + 1
                    GamestateEvent:FireServer("CarryCharacter", idTarget)
                    task.wait(DELAY_SETELAH_CARRY)
                    if not AvailableCharacters:FindFirstChild(objek.Name) then berhasil = true end
                until berhasil or percobaan >= 3
            end
        end
        
        if _G.AutoFarmTierActive then
            rootPart.CFrame = KOORDINAT_ZONA_SAH
            task.wait(DELAY_VALIDASI_ZONA)
            GamestateEvent:FireServer("FinishCarry")
            task.wait(JEDA_ANTAR_GELOMBANG)
        end
    end
    
    sedangSapuBersih = false
    matikanFlyDanNoclip()
end

_G.AutoFarm_Active = true -- Status awal saat di-load

task.spawn(function()
    while _G.AutoFarm_Active do -- Ini akan berhenti jika controller mengubahnya jadi false
        -- [LOGIKA FARMING KAMU DI SINI]
        task.wait(0.5) 
    end
    print("Skrip AutoFarm telah dihentikan oleh Controller.")
end)

-- Eksekusi otomatis
task.spawn(eksekusiSapuBersih)
