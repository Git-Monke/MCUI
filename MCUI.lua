-- MCUI vb0.1

-- Classes

--------------
--- DEVICE ---
--------------

local Device = {
    ["peripheral"] = "",
    ["framerate"] = 20
}
Device.__index = Device

----------------
--- INSTANCE ---
----------------

local instanceTypes = {
    ["device"] = Device
}

-- Although not shown here, this class 4 properties listed in the README
local Instance = {}
Instance.__index = Instance

for _, inst in pairs(instanceTypes) do
    setmetatable(inst, Instance)
end

function isInstance(obj)
    if type(obj) ~= "table" then return false end
    if not obj.className or not instanceTypes[obj.className] then return false end

    return true
end

function Instance.new(instanceType, name, parent)
    -- Check if the instanceType is valid
    if not instanceTypes[instanceType] then error("Invalid instance type") end

    -- Check if the parent is valid
    if parent and not isInstance(parent) then error("Invalid parent argument") end

    -- Check for a valid name
    if (not name) then error("Name is required when creating a new instance") end

    -- Check to make sure the name is a string
    if (type(name) ~= "string") then error("Name must be a string") end

    local newInstance = {};
    local selectedType = instanceTypes[instanceType]

    setmetatable(newInstance, selectedType)

    -- Initialize a new table of its own to store the children because that isn't included in the properties.
    newInstance.children = {};

    newInstance.className = instanceType

    newInstance.name = name

    if (parent) then
        newInstance.parent = parent
        parent.children[name] = newInstance
    end

    return newInstance;
end

function Instance:setParent(parent)
    if not isInstance(parent) then error("Cannot set parent to a non-instance") end

    if (self.parent) then
        self.parent.children[self.name] = nil;
    end

    parent[self.name] = self;
    self.parent = parent;
end

local newDevice = Instance.new("device", "newDevice")
local testDevice = Instance.new("device", "testDevice")