-- ═══════════════════════════════════════════════════════════
--  TekScripts - Painel para Ninja Parkour
--  Desenvolvido por: KAUAM
--  Equipe: TekScripts
--  TikTok: @TekScriptss
-- ═══════════════════════════════════════════════════════════

-- Carrega a biblioteca UIManager
local TekScripts = loadstring(game:HttpGet("https://raw.githubusercontent.com/c0nfigs/LibUix/refs/heads/main/init.lua"))()

-- ═══════════════════════════════════════════════════════════
--  SERVIÇOS DO ROBLOX
-- ═══════════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ═══════════════════════════════════════════════════════════
--  VARIÁVEIS GLOBAIS E CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════
local localPlayer = Players.LocalPlayer

-- Configurações de Crash
local crashConfig = {
    enabled = false,
    position = Vector3.new(-191.31, 29.3, 23.5),
    task = nil,
    remote = ReplicatedStorage:WaitForChild("RemoteTriggers"):WaitForChild("CreateFlash")
}

-- Configurações de Auto Aura
local auraConfig = {
    enabled = false,
    radius = 50,
    fireRate = 0.5,
    maxTargets = 2,
    task = nil,
    showArea = false,
    sphere = nil,
    updateConnection = nil,
    weapon = "Kunai", -- Pode ser "Kunai" ou "Katana"
    targetMode = "All", -- "All" ou "Custom"
    targets = {} -- Tabela para armazenar jogadores selecionados
}

-- Configurações de Hitbox
local hitboxConfig = {
    enabled = false,
    size = 15,
    partName = "HumanoidRootPart",
    chamsEnabled = false,
    originalSizes = {} -- Armazena os tamanhos originais dos jogadores
}

-- Configurações de Player
local playerConfig = {
    infiniteJumpEnabled = false,
    speedEnabled = false,
    currentSpeed = 16,
    originalWalkSpeed = 16,
    speedConnection = nil,
    jumpConnection = nil
}

-- Configurações do Servidor
local serverStats = {
    startTime = os.time(),
    playersJoined = 0,
    playersLeft = 0
}

-- ═══════════════════════════════════════════════════════════
--  FUNÇÕES DE CRASH
-- ═══════════════════════════════════════════════════════════
local function startCrashLoop()
    if not crashConfig.task then
        crashConfig.task = task.spawn(function()
            while crashConfig.enabled do
                pcall(function()
                    crashConfig.remote:FireServer(crashConfig.position, 5000)
                end)
                task.wait(0.01)
            end
        end)
    end
end

local function stopCrashLoop()
    if crashConfig.task then
        task.cancel(crashConfig.task)
        crashConfig.task = nil
    end
end

-- ═══════════════════════════════════════════════════════════
--  FUNÇÕES DE AUTO AURA
-- ═══════════════════════════════════════════════════════════
-- Função para obter jogadores dentro do raio da aura
local function getPlayersInAura()
    local validTargets = {}
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        return validTargets 
    end
    
    local playerPos = localPlayer.Character.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                -- Verifica se o jogador é um alvo válido com base no modo selecionado
                local isTarget = false
                if auraConfig.targetMode == "All" then
                    isTarget = true
                elseif auraConfig.targetMode == "Custom" and auraConfig.targets[player.Name] then
                    isTarget = true
                end

                if isTarget then
                    local dist = (hrp.Position - playerPos).Magnitude
                    if dist <= auraConfig.radius then
                        table.insert(validTargets, {player = player, dist = dist})
                    end
                end
            end
        end
    end

    table.sort(validTargets, function(a, b) return a.dist < b.dist end)
    
    local limitedTargets = {}
    for i = 1, math.min(#validTargets, auraConfig.maxTargets) do
        table.insert(limitedTargets, validTargets[i].player)
    end
    
    return limitedTargets
end

-- Função para iniciar o loop da aura
local function startAuraLoop()
    if not auraConfig.task then
        auraConfig.task = task.spawn(function()
            while auraConfig.enabled do
                task.wait(auraConfig.fireRate)
                
                if not localPlayer.Character then continue end

                local weapon = localPlayer.Character:FindFirstChild(auraConfig.weapon)
                if not weapon then continue end

                local targets = getPlayersInAura()
                for _, target in ipairs(targets) do
                    if target.Character and target.Character:FindFirstChild("Humanoid") and target.Character:FindFirstChild("HumanoidRootPart") then
                        local humanoid = target.Character.Humanoid
                        if humanoid.Health > 0 then
                            pcall(function()
                                local args = {
                                    humanoid, 
                                    weapon, 
                                    1, 
                                    target.Character.HumanoidRootPart.Position
                                }
                                ReplicatedStorage:WaitForChild("RemoteTriggers"):WaitForChild("Bolster"):FireServer(unpack(args))
                            end)
                        end
                    end
                end
            end
        end)
    end
end

-- Função para parar o loop da aura
local function stopAuraLoop()
    if auraConfig.task then
        task.cancel(auraConfig.task)
        auraConfig.task = nil
    end
end

-- Função para atualizar a esfera visual da aura
local function updateAuraSphere()
    if auraConfig.showArea then
        if not auraConfig.sphere or not auraConfig.sphere.Parent then
            auraConfig.sphere = Instance.new("Part")
            auraConfig.sphere.Name = "AuraDisplaySphere"
            auraConfig.sphere.Shape = Enum.PartType.Ball
            auraConfig.sphere.Material = Enum.Material.Neon
            auraConfig.sphere.Color = Color3.fromRGB(0, 255, 255)
            auraConfig.sphere.Transparency = 0.8
            auraConfig.sphere.CanCollide = false
            auraConfig.sphere.Anchored = true
            auraConfig.sphere.CastShadow = false
            auraConfig.sphere.Parent = workspace
        end

        local sphereSize = auraConfig.radius * 2
        auraConfig.sphere.Size = Vector3.new(sphereSize, sphereSize, sphereSize)

        if not auraConfig.updateConnection then
            auraConfig.updateConnection = RunService.RenderStepped:Connect(function()
                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and auraConfig.sphere and auraConfig.sphere.Parent then
                    auraConfig.sphere.Position = localPlayer.Character.HumanoidRootPart.Position
                elseif auraConfig.sphere and auraConfig.sphere.Parent then
                    auraConfig.sphere:Destroy()
                    auraConfig.sphere = nil
                    if auraConfig.updateConnection then
                        auraConfig.updateConnection:Disconnect()
                        auraConfig.updateConnection = nil
                    end
                end
            end)
        end
    else
        if auraConfig.updateConnection then 
            auraConfig.updateConnection:Disconnect()
            auraConfig.updateConnection = nil 
        end
        if auraConfig.sphere and auraConfig.sphere.Parent then 
            auraConfig.sphere:Destroy()
            auraConfig.sphere = nil 
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  FUNÇÕES DE HITBOX E CHAMS (CORRIGIDAS E OTIMIZADAS)
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local activeDistanceLabels = {}

-- Cria marcador de distância + vida apenas uma vez
local function createDistanceLabel(char)
    if activeDistanceLabels[char] then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DistanceLabelGui"
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0.2
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.TextWrapped = true
    text.Parent = billboard

    activeDistanceLabels[char] = text
end

local function removeDistanceLabel(char)
    local text = activeDistanceLabels[char]
    if text and text.Parent then
        text.Parent:Destroy()
    end
    activeDistanceLabels[char] = nil
end

-- Loop global atualizando distância e vida
task.spawn(function()
    while true do
        task.wait(0.1)
        local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        for char, text in pairs(activeDistanceLabels) do
            if char.Parent and text.Parent then
                local root = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChild("Humanoid")
                if root and humanoid then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    local health = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
                    text.Text = string.format("Dist: %.0f studs\nHP: %.0f/%.0f", dist, health, humanoid.MaxHealth)
                    text.TextColor3 = Color3.fromHSV(math.clamp(dist / 100, 0, 1), 1, 1)
                end
            else
                activeDistanceLabels[char] = nil
            end
        end
    end
end)

-- Aplica hitbox + chams
local function applyHitbox(char)
    local part = char:FindFirstChild(hitboxConfig.partName)
    if part then
        part.Size = Vector3.new(hitboxConfig.size, hitboxConfig.size, hitboxConfig.size)
        part.CanCollide = false
        part.Transparency = 0.7
        part.Color = Color3.fromRGB(255, 0, 0)
        part.Material = Enum.Material.Neon

        if hitboxConfig.chamsEnabled then
            local highlight = char:FindFirstChild("ChamsHighlight") or Instance.new("Highlight")
            highlight.Name = "ChamsHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0.3
            highlight.Parent = char

            createDistanceLabel(char)
        else
            local oldHighlight = char:FindFirstChild("ChamsHighlight")
            if oldHighlight then oldHighlight:Destroy() end
            removeDistanceLabel(char)
        end
    end
end

local function resetHitbox(char)
    local oldHighlight = char:FindFirstChild("ChamsHighlight")
    if oldHighlight then oldHighlight:Destroy() end

    removeDistanceLabel(char)

    local part = char:FindFirstChild(hitboxConfig.partName)
    if part then
        part.Size = Vector3.new(2, 2, 1)
        part.Transparency = 0
        part.Color = Color3.fromRGB(255, 255, 255)
        part.Material = Enum.Material.Plastic
        part.CanCollide = true
    end
end

local function updateAllHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            if hitboxConfig.enabled then
                applyHitbox(player.Character)
            else
                resetHitbox(player.Character)
            end
        end
    end
end

local function trackPlayer(player)
    if player == localPlayer then return end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if hitboxConfig.enabled then
            applyHitbox(char)
            local humanoid = char:WaitForChild("Humanoid")
            humanoid.Died:Connect(function() resetHitbox(char) end)
        end
    end)

    if player.Character and hitboxConfig.enabled then
        applyHitbox(player.Character)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    trackPlayer(plr)
end
Players.PlayerAdded:Connect(trackPlayer)
-- ═══════════════════════════════════════════════════════════
--  FUNÇÕES DE PLAYER
-- ═══════════════════════════════════════════════════════════
local function setWalkSpeed(speed)
    playerConfig.currentSpeed = speed

    if playerConfig.speedConnection then
        playerConfig.speedConnection:Disconnect()
        playerConfig.speedConnection = nil
    end

    local char = localPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if playerConfig.speedEnabled then
            playerConfig.speedConnection = RunService.RenderStepped:Connect(function()
                if humanoid and humanoid.Parent then
                    humanoid.WalkSpeed = playerConfig.currentSpeed
                end
            end)
        else
            humanoid.WalkSpeed = playerConfig.originalWalkSpeed
        end
    end
end

local function startInfiniteJump()
    if playerConfig.jumpConnection then return end
    playerConfig.jumpConnection = UserInputService.JumpRequest:Connect(function()
        local char = localPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and playerConfig.infiniteJumpEnabled then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopInfiniteJump()
    if playerConfig.jumpConnection then
        playerConfig.jumpConnection:Disconnect()
        playerConfig.jumpConnection = nil
    end
end

local function handleCharacter(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        playerConfig.originalWalkSpeed = humanoid.WalkSpeed
        if playerConfig.speedEnabled then
            setWalkSpeed(playerConfig.currentSpeed)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  CRIAÇÃO DA INTERFACE
-- ═══════════════════════════════════════════════════════════
local gui = TekScripts.new({
    Name = "TekScripts | Ninja Parkour", 
    FloatText = "Abrir Painel"
})

-- Função para obter valores do dropdown de alvos
local function getDropdownValues()
    local values = { { Name = "All" } }
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(values, {
                Name = player.Name,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
            })
        end
    end
    return values
end

-- ═══════════════════════════════════════════════════════════
--  ABA 2: AUTO AURA (INTERFACE ATUALIZADA)
-- ═══════════════════════════════════════════════════════════
local tabAura = gui:CreateTab({Title = "🎯 Auto Aura"})

-- Label inicial
gui:CreateLabel(tabAura, {
    Title = "🎯 Kill Aura Automática", 
    Desc = "Ataque automaticamente inimigos próximos"
})

-- Toggle para ativar/desativar a aura
gui:CreateToggle(tabAura, {
    Text = "Ativar Auto Aura", 
    Callback = function(estado)
        auraConfig.enabled = estado
        if estado then 
            startAuraLoop()
            gui:Notify({Title = "✅ Auto Aura Ativado!", Desc = "Mirando em inimigos próximos com " .. auraConfig.weapon .. ".", Duration = 3})
        else 
            stopAuraLoop()
            gui:Notify({Title = "🛑 Auto Aura Desativado", Desc = "Mira automática parada.", Duration = 3})
        end
    end
})

-- Toggle para mostrar área da aura
gui:CreateToggle(tabAura, {
    Text = "👁️ Mostrar Área da Aura", 
    Callback = function(estado)
        auraConfig.showArea = estado
        updateAuraSphere()
        if estado then
            gui:Notify({Title = "👁️ Visualização Ativada", Desc = "Esfera de aura visível.", Duration = 2})
        end
    end
})

-- Label para configurações de alvo
gui:CreateLabel(tabAura, {
    Title = "⚙️ Configurações de Alvo", 
    Desc = "Escolha quem será atacado pelo Kill Aura"
})

-- Label para mostrar os alvos selecionados
local targetDisplayLabel = gui:CreateLabel(tabAura, {
    Title = "Alvos Selecionados:",
    Desc = auraConfig.targetMode == "All" and "Todos os players poderão morrer agora." or "Nenhum jogador selecionado."
})

-- Dropdown de jogadores
local playerDropdown
local isUpdatingSelection = false

playerDropdown = TekScripts:CreateDropdown(tabAura, {
    Title = "Selecionar Alvos",
    Values = getDropdownValues(),
    Callback = function(selected)
        if isUpdatingSelection then return end
        isUpdatingSelection = true

        if type(selected) == "table" and table.find(selected, "All") then
            -- Modo "All" selecionado
            auraConfig.targetMode = "All"
            auraConfig.targets = {}
            playerDropdown:SetSelected({"All"})
        else
            -- Modo "Custom" com jogadores específicos
            auraConfig.targetMode = "Custom"
            auraConfig.targets = {}
            for _, name in ipairs(selected or {}) do
                if name ~= "All" then
                    auraConfig.targets[name] = true
                end
            end
        end

        -- Atualiza o label de alvos
        local formatted = playerDropdown:GetSelectedFormatted() or ""
        local desc = (auraConfig.targetMode == "All" and "Todos os players poderão morrer agora." or (formatted ~= "" and formatted or "Nenhum jogador selecionado."))
        targetDisplayLabel.Update({ Desc = desc })

        isUpdatingSelection = false
    end,
    MultiSelect = true,
    MaxVisibleItems = 5,
    InitialValues = auraConfig.targetMode == "All" and {"All"} or (function()
        local initial = {}
        for name, _ in pairs(auraConfig.targets) do
            table.insert(initial, name)
        end
        return initial
    end)()
})

-- Conecta eventos para atualização em tempo real
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        playerDropdown:AddItem({
            Name = player.Name,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
        })
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= localPlayer then
        playerDropdown:RemoveItem(player.Name)
        if auraConfig.targets[player.Name] then
            auraConfig.targets[player.Name] = nil
            local formatted = playerDropdown:GetSelectedFormatted() or ""
            local desc = (auraConfig.targetMode == "All" and "Todos os players poderão morrer agora." or (formatted ~= "" and formatted or "Nenhum jogador selecionado."))
            targetDisplayLabel.Update({ Desc = desc })
        end
    end
end)

-- Dropdown para escolher a arma
local weaponDropdown = TekScripts:CreateDropdown(tabAura, {
    Title = "Arma para Kill Aura",
    Values = { { Name = "Kunai" }, { Name = "Katana" } },
    Callback = function(selected)
        auraConfig.weapon = selected
        gui:Notify({Title = "✅ Arma Selecionada", Desc = "Kill Aura agora usa: " .. selected, Duration = 2})
    end,
    InitialValues = {auraConfig.weapon}
})

-- Configurações de performance
gui:CreateLabel(tabAura, {
    Title = "⚙️ Ajustes de Performance", 
    Desc = "Cuidado! Configurações extremas podem causar kick"
})

local auraRadiusLabel = gui:CreateLabel(tabAura, {Title = "📏 Raio da Aura: " .. auraConfig.radius .. "m"})
gui:CreateSlider(tabAura, {
    Text = "📏 Raio da Aura (metros)", 
    Min = 10, Max = 55, Step = 5, Value = auraConfig.radius,
    Callback = function(val)
        auraConfig.radius = val
        updateAuraSphere()
        auraRadiusLabel.Update({Title = "📏 Raio da Aura: " .. val .. "m"})
    end
})

local auraFireRateLabel = gui:CreateLabel(tabAura, {Title = "⚡ Taxa de Disparo: " .. string.format("%.2f", auraConfig.fireRate) .. "s"})
gui:CreateSlider(tabAura, {
    Text = "⚡ Taxa de Disparo (segundos)", 
    Min = 0.1, Max = 2, Step = 0.05, Value = auraConfig.fireRate,
    Callback = function(val) 
        auraConfig.fireRate = val
        auraFireRateLabel.Update({Title = "⚡ Taxa de Disparo: " .. string.format("%.2f", val) .. "s"})
    end
})

-- ═══════════════════════════════════════════════════════════
--  RESTANTE DAS ABAS (CRASH, HITBOX, PLAYER, CRÉDITOS)
-- ═══════════════════════════════════════════════════════════

-- ABA 1: CRASH
local tabCrash = gui:CreateTab({Title = "💣 Crash"})
gui:CreateLabel(tabCrash, {Title = "⚠️ Aviso Importante", Desc = "Esta função pode travar os players. Use com responsabilidade!"})
gui:CreateToggle(tabCrash, {Text = "Ativar Crash dos players", Callback = function(estado)
    crashConfig.enabled = estado
    if estado then startCrashLoop() gui:Notify({Title = "✅ Crash Ativado!", Desc = "Os players podem começar a travar.", Duration = 3})
    else stopCrashLoop() gui:Notify({Title = "🛑 Crash Desativado", Desc = "O crash foi parado com sucesso.", Duration = 3}) end
end})
gui:CreateLabel(tabCrash, {Title = "📍 Configurar Posição", Desc = "Defina onde o crash será aplicado"})
local crashInput = gui:CreateInput(tabCrash, {Text = "Posição (x, y, z)", Placeholder = string.format("%.2f, %.2f, %.2f", crashConfig.position.X, crashConfig.position.Y, crashConfig.position.Z), Callback = function(text)
    local parts = string.split(text, ",")
    if #parts == 3 then
        local newX, newY, newZ = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
        if newX and newY and newZ then crashConfig.position = Vector3.new(newX, newY, newZ) gui:Notify({Title = "✅ Posição Atualizada", Desc = "Nova posição: " .. text, Duration = 2})
        else gui:Notify({Title = "❌ Erro", Desc = "Formato inválido. Use: x, y, z", Duration = 3}) end
    end
end})
gui:CreateButton(tabCrash, {Text = "📍 Capturar Posição Atual", Callback = function()
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        crashConfig.position = localPlayer.Character.HumanoidRootPart.Position
        crashInput.Update({Placeholder = string.format("%.2f, %.2f, %.2f", crashConfig.position.X, crashConfig.position.Y, crashConfig.position.Z)})
        gui:Notify({Title = "✅ Posição Capturada!", Desc = "O crash agora acontecerá aqui.", Duration = 3})
    else gui:Notify({Title = "❌ Erro", Desc = "Personagem não encontrado.", Duration = 3}) end
end})

-- ABA 3: HITBOX EXPANDER (CORRIGIDA)
local tabHitbox = gui:CreateTab({Title = "🛡️ Hitbox"})

gui:CreateLabel(tabHitbox, {
    Title = "🛡️ Expansor de Hitbox", 
    Desc = "Aumente a área de acerto dos inimigos"
})

gui:CreateToggle(tabHitbox, {
    Text = "Ativar Hitbox Expander", 
    Callback = function(estado)
        hitboxConfig.enabled = estado
        updateAllHitboxes()
        if estado then 
            gui:Notify({
                Title = "Hitbox Ativado!", 
                Desc = "Todos os inimigos têm hitbox expandido.", 
                Duration = 3
            })
        else 
            gui:Notify({
                Title = "Hitbox Desativado", 
                Desc = "Hitbox voltou ao normal.", 
                Duration = 3
            })
        end
    end
})

gui:CreateToggle(tabHitbox, {
    Text = " Ver Através de Paredes (Chams ESP)", 
    Callback = function(estado)
        hitboxConfig.chamsEnabled = estado
        if hitboxConfig.enabled then 
            updateAllHitboxes() 
        end
        if estado then 
            gui:Notify({
                Title = "Chams ESP Ativado!", 
                Desc = "Veja inimigos através das paredes.", 
                Duration = 3
            })
        else 
            gui:Notify({
                Title = "Chams ESP Desativado", 
                Desc = "Visão normalizada.", 
                Duration = 3
            })
        end
    end
})

gui:CreateSlider(tabHitbox, {
    Text = "📐 Tamanho do Hitbox", 
    Min = 2, 
    Max = 25, 
    Step = 1, 
    Value = hitboxConfig.size,
    Callback = function(val)
        hitboxConfig.size = val
        if hitboxConfig.enabled then 
            updateAllHitboxes() 
        end
    end
})


-- ABA 4: PLAYER
local tabPlayer = gui:CreateTab({Title = "🏃‍♂️ Player"})
gui:CreateLabel(tabPlayer, {Title = "🕹️ Ações do Jogador", Desc = "Hmmm"})
gui:CreateToggle(tabPlayer, {Text = "Pulo Infinito", Callback = function(estado)
    playerConfig.infiniteJumpEnabled = estado
    if estado then startInfiniteJump() else stopInfiniteJump() end
end})
local serverInfoLabel = gui:CreateLabel(tabPlayer, {Title = "🌍 Informações do Servidor", Desc = "Carregando..."})

-- ABA 5: CRÉDITOS
local tabCredits = gui:CreateTab({Title = "ℹ️ Créditos"})
gui:CreateLabel(tabCredits, {Title = "🎮 TekScripts", Desc = "Painel profissional para Ninja Parkour"})
gui:CreateLabel(tabCredits, {Title = "Dev :", Desc = "Kauam"})
gui:CreateLabel(tabCredits, {Title = "Equipe :", Desc = "TekScripts"})
gui:CreateLabel(tabCredits, {Title = "TikTok", Desc = "Dá uma força lá!\n@TekScriptss"})
gui:CreateLabel(tabCredits, {Title = "Labory UIX Própria", Desc = "Deseja usar? Entre em contato no TikTok da equipe!"})
gui:CreateButton(tabCredits, {Text = "💜 Obrigado por Usar!", Callback = function() gui:Notify({Title = "💜 TekScripts", Desc = "Siga nossa equipe no Tiktok : TekScriptss", Duration = 4}) end})
gui:CreateLabel(tabCredits, {Title = "⚠️ Aviso Legal", Desc = "Use este painel por sua conta e risco. Não nos responsabilizamos por bans ou problemas no jogo."})

-- ═══════════════════════════════════════════════════════════
--  INICIALIZAÇÃO E CONEXÕES DE EVENTOS
-- ═══════════════════════════════════════════════════════════
for _, plr in ipairs(Players:GetPlayers()) do trackPlayer(plr) end
Players.PlayerAdded:Connect(trackPlayer)

Players.PlayerAdded:Connect(function(player)
    serverStats.playersJoined = serverStats.playersJoined + 1
end)

Players.PlayerRemoving:Connect(function(player)
    serverStats.playersLeft = serverStats.playersLeft + 1
end)

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02i:%02i:%02i", hours, minutes, secs)
end

local serverInfoConnection = RunService.Heartbeat:Connect(function()
    local elapsedTime = os.time() - serverStats.startTime
    local playerCount = #Players:GetPlayers()
    serverInfoLabel.Update({
        Title = "🌍 Informações do Servidor",
        Desc = string.format("Tempo de atividade: %s\nJogadores no servidor: %d\nEntraram: %d | Saíram: %d", 
            formatTime(elapsedTime), 
            playerCount, 
            serverStats.playersJoined,
            serverStats.playersLeft
        )
    })
end)

local function cleanupOnLeave()
    -- Limpa conexões e objetos ao sair
    if auraConfig.updateConnection then
        auraConfig.updateConnection:Disconnect()
    end
    if playerConfig.speedConnection then
        playerConfig.speedConnection:Disconnect()
    end
    if playerConfig.jumpConnection then
        playerConfig.jumpConnection:Disconnect()
    end
    if serverInfoConnection then
        serverInfoConnection:Disconnect()
    end
    stopAuraLoop()
    stopCrashLoop()
    if auraConfig.sphere then
        auraConfig.sphere:Destroy()
    end
    
    -- Reseta hitboxes de todos os jogadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            resetHitbox(player)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        cleanupOnLeave()
    end
end)

if localPlayer.Character then
    handleCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(handleCharacter)

gui:Notify({
    Title = "TekScripts Carregado!", 
    Desc = "Painel iniciado com sucesso. Desenvolvido por TekScripts.", 
    Duration = 5
})
