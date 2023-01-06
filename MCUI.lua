-- MCUI vb0.1.1

-- MINOR FUNCTIONS

function table.findIndx(f, l) -- find element v of l satisfying f(v)
    for i, v in ipairs(l) do
        if f(v) then
            return i
        end
    end
    return nil
end

-- CLASSES

----------------
--- INSTANCE ---
----------------

-- Although not shown here, this class 4 properties listed in the README
local Instance = {}
Instance.__index = Instance

local instanceTypes = {}

local function newClass(obj)
    obj = obj or {}
    setmetatable(obj, Instance)
    return obj
end

local function isInstance(obj)
    if type(obj) ~= "table" then return false end
    if not obj.className or not instanceTypes[obj.className] then return false end

    return true
end

function Instance.new(instanceType, name, parent)
    -- Check if the instanceType is valid
    if not instanceTypes[instanceType] then error("Invalid instance type") end

    -- Check if the parent is valid
    if parent and not isInstance(parent) then error("Invalid parent argument") end

    -- Check to make sure the name is a string
    if name and (type(name) ~= "string") then error("Name must be a string") end

    local newInstance = {};
    local selectedType = instanceTypes[instanceType]
    
    setmetatable(newInstance, selectedType)
    
    -- Initialize a new table of its own to store the children because that isn't included in the properties.
    newInstance.children = {};

    -- This metamethod allows for non-unique name identifiers AND retrieving children with the dot operator
    setmetatable(newInstance.children, {
        __index =   
            function ( table, key )
                for _, item in ipairs(table) do
                    if (item.name == key) then
                        return item
                    end
                end

                return nil
            end
    })

    newInstance.className = instanceType

    newInstance.name = name

    if (parent) then
        newInstance.parent = parent
        table.insert(parent.children, newInstance)
    end

    return newInstance;
end

function Instance:setParent(parent)
    if not isInstance(parent) then error("Cannot set parent to a non-instance") end

    if (self.parent) then
        local siblings = self.parent.children
        table.remove(siblings, table.findIndx(function (v) return v == self end, siblings))
    end

    table.insert(parent.children, self)
    self.parent = parent;
end

-----------------------
--- VISUAL INSTANCE ---
-----------------------

local VisualInstance = newClass({
    ["x"] = 0,
    ["y"] = 0,
    ["z"] = 0,
    ["width"] = 6,
    ["height"] = 3,
    ["backgroundColor"] = colors.white,
    ["textColor"] = colors.black,
    ["text"] = "text",
    ["visible"] = true,
    ["alignText"] = "center",
    ["justifyText"] = "center"
})
VisualInstance.__index = VisualInstance

function VisualInstance.new(obj)
    obj = obj or {}
    setmetatable(obj, VisualInstance);
    return obj
end

-----------------
--- TEXTLABEL ---
-----------------

local TextLabel = VisualInstance.new();
TextLabel.__index = TextLabel

--------------
--- DEVICE ---
--------------

local Device = newClass({
    ["peripheral"] = term,
    ["framerate"] = 20
})
Device.__index = Device

local faces = {
    "left",
    "right",
    "top",
    "bottom",
    "front",
    "back"
}

function Device:wrap(face)
    if (peripheral.isPresent(face)) then
        self.peripheral = peripheral.wrap(face)
    end
end

function Device:find(periphType)
    for _, face in ipairs(faces) do
        if peripheral.isPresent(face) and peripheral.getType(face) == periphType then
            self.peripheral = peripheral.wrap(face)
            return
        end
    end

    error("Peripheral of type '" .. periphType .. "' not found")
end

instanceTypes = {
    ["device"] = Device,
    ["textlabel"] = TextLabel
}

local parent1 = Instance.new("device", "parent1")
local parent2 = Instance.new("device", "parent2")
local newLabel = Instance.new("textlabel", "newLabel")