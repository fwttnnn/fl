local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local warns = {}

RunService.RenderStepped:Connect(function()
    for _, descendant in workspace:GetDescendants() do
        if not descendant:IsA("SurfaceGui") then continue end

        local billboard = descendant.Parent
        if not billboard then continue end
        if not (billboard:IsA("BasePart") or billboard:IsA("Part")) then continue end
        if not billboard:GetAttribute("Billboard") then continue end

        local gui = descendant
        if gui.Face ~= Enum.NormalId.Back and not warns[gui] then
            warns[gui] = true
            warn(gui, "should be attached on the back, otherwise it's not visible.")
        end

        billboard.CanCollide = false
        billboard.Transparency = 1

        local parent = billboard.Parent
        local attached = billboard:GetAttribute("Attached") and parent
        local offset = billboard:GetAttribute("Offset") or Vector3.new(0, 0, 0)

        if attached then
            billboard.CFrame = parent.CFrame + offset
        end

        billboard.CFrame = CFrame.lookAt(billboard.Position, billboard.Position + Camera.CFrame.LookVector, Camera.CFrame.UpVector)
    end
end)
