-- =======================================================
-- KONFIGURASI TARGET
-- =======================================================
local Workspace = game:GetService("Workspace")
local PREFIX_TARGET = "SpawnedGrass_" -- Menyasar semua yang berawalan ini

-- =======================================================
-- FUNGSI PENYAPU BERSIH MASAL (BULK CLEANER)
-- =======================================================
local function sapuBersihSemuaGrass()
    local jumlahTerhapus = 0
    
    -- Memeriksa seluruh objek yang saat ini sudah ada di Workspace
    for _, objek in ipairs(Workspace:GetChildren()) do
        -- Mengecek apakah nama objek berawalan "SpawnedGrass_"
        if string.sub(objek.Name, 1, string.len(PREFIX_TARGET)) == PREFIX_TARGET then
            local sukses, _ = pcall(function()
                objek:Destroy()
            end)
            if sukses then
                jumlahTerhapus = jumlahTerhapus + 1
            end
        end
    end
    
    if jumlahTerhapus > 0 then
        print("🧹 [BULK-CLEANER] Berhasil menyapu " .. tostring(jumlahTerhapus) .. " objek berawalan " .. PREFIX_TARGET)
    end
end

-- Eksekusi pembersihan massal pertama kali saat skrip dijalankan
sapuBersihSemuaGrass()

-- =======================================================
-- SENSOR OTOMATIS BERBASIS PREFIX MATCHING
-- =======================================================
-- Mengunci Workspace agar tidak ada variasi SpawnedGrass baru yang bisa hidup
Workspace.ChildAdded:Connect(function(anakBaru)
    -- Deteksi instan apakah objek baru yang lahir berawalan "SpawnedGrass_"
    if string.sub(anakBaru.Name, 1, string.len(PREFIX_TARGET)) == PREFIX_TARGET then
        task.wait(0.05) -- Jeda sangat minimal untuk stabilitas engine
        
        local sukses, _ = pcall(function()
            anakBaru:Destroy()
        end)
        
        if sukses then
            print("⚡ [BULK-CLEANER] Menghancurkan objek baru: " .. anakBaru.Name)
        end
    end
end)

_G.AutoFarm_Active = true 

task.spawn(function()
    while _G.AutoFarm_Active do -- Ini yang bikin script bisa berhenti!
        -- [LOGIKA FARMING KAMU DI SINI]
        task.wait(1)
    end
end)
