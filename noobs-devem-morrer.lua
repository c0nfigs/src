-- Carrega a lib
local Tekscripts = loadstring(game:HttpGet("https://raw.githubusercontent.com/c0nfigs/LibUix/refs/heads/main/init.lua"))()

-- Interface principal
local gui = Tekscripts.new({
	Name = "TekScripts | The Maze",
	FloatText = "Abrir Interface"
})

-- Cria a aba principal
local tabAura = gui:CreateTab({ Title = "Aura" })

-- Serviços
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local hurtRemote = ReplicatedStorage:WaitForChild("HurtEnemy")
local killRemote = ReplicatedStorage:WaitForChild("PlrMan"):WaitForChild("IncrementIndexKillCount")
local enemiesFolder = Workspace:WaitForChild("Enemies")

-- Configurações base
local ATTACK_INTERVAL = 0.05
local HITBOX_SIZE = Vector3.new(10, 20, 10)
local HITBOX_DISTANCE = 7
local HITBOX_OFFSET_Y = -8

-- Estados
local damagedEnemies = {}
local maxHealths = {}
local lastAttack = 0
local ORIGINAL_SIZES = {}
local ORIGINAL_CAN_COLLIDE = {}

----------------------------------------------------------
-- SECTION 1: Kill Aura e Interações de Inimigos
----------------------------------------------------------

local sectionAura = gui:CreateSection(tabAura, {
	Title = "Kill Aura e Combate",
	Open = true,
	Fixed = false
})

local toggleAura = Tekscripts:CreateToggle(tabAura, {
	Text = "Instant Kill",
	Desc = "Elimina instantaneamente NPCs ao receberem dano",
	Callback = function(state)
		print("Modo Aura:", state and "ATIVADO" or "DESATIVADO")
	end
})

local toggleHitboxFront = Tekscripts:CreateToggle(tabAura, {
	Text = "Hitbox na Frente",
	Desc = "Mantém os inimigos fixos à frente e abaixo do jogador",
	Callback = function(state)
		print("Hitbox Frontal:", state and "ON" or "OFF")
	end
})

sectionAura:AddComponent(toggleAura)
sectionAura:AddComponent(toggleHitboxFront)

----------------------------------------------------------
-- SECTION 2: Itens e Utilidades
----------------------------------------------------------

local sectionItens = gui:CreateSection(tabAura, {
	Title = "Itens e Utilidades",
	Open = true,
	Fixed = false
})

local toggleItems = Tekscripts:CreateToggle(tabAura, {
	Text = "Auto Get Itens",
	Desc = "Atrai todos os itens do mapa até você",
	Callback = function(state)
		print("Auto Itens:", state and "ON" or "OFF")
	end
})

sectionItens:AddComponent(toggleItems)

----------------------------------------------------------
-- SECTION 3: Lançar Partes (Força)
----------------------------------------------------------

local sectionForce = gui:CreateSection(tabAura, {
	Title = "Manipulação de Partes",
	Open = true,
	Fixed = false
})

local toggleLaunch = Tekscripts:CreateToggle(tabAura, {
	Text = "Lançar Partes",
	Desc = "Empurra todas as partes de 'Bullets' para longe (exceto Windforce)",
	Callback = function(state)
		print("Lançar Partes:", state and "ON" or "OFF")
	end
})

sectionForce:AddComponent(toggleLaunch)

----------------------------------------------------------
-- FUNÇÕES AUXILIARES
----------------------------------------------------------

local function getHumanoid(npc)
	return npc:FindFirstChildOfClass("Humanoid")
end

local function getHealth(npc)
	local humanoid = getHumanoid(npc)
	return humanoid and humanoid.Health or nil
end

local function getMaxHealth(npc)
	local humanoid = getHumanoid(npc)
	return humanoid and humanoid.MaxHealth or nil
end

local function getHRP()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart")
end

local function getAllItems(parent)
	local items = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Model") or child:IsA("Folder") then
			for _, sub in ipairs(getAllItems(child)) do
				table.insert(items, sub)
			end
		elseif child:IsA("BasePart") then
			table.insert(items, child)
		end
	end
	return items
end

local function moveItemsToPlayer()
	local hrp = getHRP()
	local itemsFolder = workspace:FindFirstChild("Items")
	if not itemsFolder then return end
	for _, part in ipairs(getAllItems(itemsFolder)) do
		if (part.Position - hrp.Position).Magnitude > 0.5 then
			part.Anchored = true
			part.CFrame = CFrame.new(hrp.Position)
		end
	end
end

----------------------------------------------------------
-- LOOPS PRINCIPAIS
----------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	local hrpPlayer = getHRP()
	lastAttack += dt

	for _, npc in ipairs(enemiesFolder:GetChildren()) do
		if npc:IsA("Model") then
			if not maxHealths[npc] then
				local maxH = getMaxHealth(npc)
				if maxH then
					maxHealths[npc] = maxH
					damagedEnemies[npc] = getHealth(npc)
				end
			end

			-- Kill Aura (Hitkill)
			if toggleAura.GetState and toggleAura.GetState() and lastAttack >= ATTACK_INTERVAL then
				local health = getHealth(npc)
				local maxH = maxHealths[npc]
				if health and maxH and health < (damagedEnemies[npc] or health) then
					local finalDamage = maxH * 10
					hurtRemote:FireServer(npc, finalDamage)
					killRemote:FireServer(npc.Name)
				end
				damagedEnemies[npc] = health
			end

			-- Hitbox Frontal
			if toggleHitboxFront.GetState and toggleHitboxFront.GetState() then
				local hrp = npc:FindFirstChild("HumanoidRootPart")
				if hrp then
					if not ORIGINAL_SIZES[npc] then
						ORIGINAL_SIZES[npc] = hrp.Size
						ORIGINAL_CAN_COLLIDE[npc] = {}
						for _, part in ipairs(npc:GetDescendants()) do
							if part:IsA("BasePart") then
								ORIGINAL_CAN_COLLIDE[npc][part] = part.CanCollide
							end
						end
					end

					hrp.Size = HITBOX_SIZE
					hrp.Anchored = true
					hrp.Massless = true
					for _, part in ipairs(npc:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end

					local targetPos = hrpPlayer.Position
						+ (hrpPlayer.CFrame.LookVector * HITBOX_DISTANCE)
						+ Vector3.new(0, HITBOX_OFFSET_Y, 0)
					hrp.CFrame = CFrame.new(targetPos)
				end
			elseif ORIGINAL_SIZES[npc] then
				local hrp = npc:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.Size = ORIGINAL_SIZES[npc]
					if ORIGINAL_CAN_COLLIDE[npc] then
						for part, collide in pairs(ORIGINAL_CAN_COLLIDE[npc]) do
							if part then part.CanCollide = collide end
						end
					end
					hrp.Anchored = false
					hrp.Massless = false
				end
				ORIGINAL_SIZES[npc] = nil
				ORIGINAL_CAN_COLLIDE[npc] = nil
			end
		end
	end

	if lastAttack >= ATTACK_INTERVAL then
		lastAttack = 0
	end

	if toggleItems.GetState and toggleItems.GetState() then
		moveItemsToPlayer()
	end
end)

----------------------------------------------------------
-- LOOP DE FORÇA (Lançar Partes)
----------------------------------------------------------

local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	or LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

local forceDistance = 20

RunService.Heartbeat:Connect(function()
	if not toggleLaunch.GetState or not toggleLaunch.GetState() then return end

	for _, obj in ipairs(workspace.Bullets:GetChildren()) do
		if not obj or obj.Name == "Windforce" then continue end

		for _, part in ipairs(obj:GetDescendants()) do
			if part:IsA("BasePart") then
				if part.Name == "Windforce" or (obj:FindFirstChild("Windforce") and part:IsDescendantOf(obj.Windforce)) then
					continue
				end
				local dir = (part.Position - HRP.Position).Unit
				part.CFrame = CFrame.new(part.Position + dir * forceDistance)
			end
		end

		if obj:IsA("BasePart") then
			local dir = (obj.Position - HRP.Position).Unit
			obj.CFrame = CFrame.new(obj.Position + dir * forceDistance)
		end
	end
end)