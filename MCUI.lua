-- MCUI vb0.1.1
-- MINOR FUNCTIONS
function table.findIndx(f, l)-- find element v of l satisfying f(v)
    for i, v in ipairs(l) do
        if f(v) then
            return i
        end
    end
    return nil
end

function printChildNames(instance)
    for _, child in ipairs(instance.children) do
        print(child.name)
    end
end

function printDictKeys(dict)
    for key, _ in pairs(dict) do
        print(key)
    end
end

-- CLASSES
----------------
--- INSTANCE ---
----------------
-- Although not shown here, this class 4 properties listed in the README
local Instance = {
    ["x"] = 0,
    ["y"] = 0,
    ["z"] = 0,
    ["width"] = 0,
    ["height"] = 0
}
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
        function(table, key)
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

function Instance:addChild(instance)
    if not isInstance(instance) then error("Cannot add non-instance child to " .. self.name) end
    
    instance.parent = self
    table.insert(self.children, instance)
end

function Instance:addChildren(instances)
    for _, instance in ipairs(instances) do
        self:addChild(instance)
    end
end

function Instance:contains(x, y)
    if (x < self.x or x > self.x + self.width) then
        return false
    end
    
    if (y < self.y or y > self.y + self.height) then
        return false
    end
    
    return true
end

function Instance:findDevice()
    local current = self.parent
    local periph = nil;
    
    if (current.peripheral) then return current.peripheral end
    
    repeat
        current = current.parent
        periph = current.peripheral
    until current.peripheral or current.parent == nil

    return periph
end

-------------
--- FRAME ---
-------------
local Frame = newClass({
    ["backgroundColor"] = colors.white,
    ["visible"] = true,
    ["units"] = {}
})
Frame.__index = Frame

function Frame:render()
    local parent = self.parent
    
    local maxX = parent.x + parent.width - 1
    local maxY = parent.y + parent.height - 1
    
    local x = parent.x + self.x
    local dx = math.min(x + self.width - 1, maxX)
    
    local y = parent.y + self.y
    local dy = math.min(y + self.height - 1, maxY)
    
    local periph = self:findDevice();
    periph.setBackgroundColor(self.backgroundColor);
    
    for i = x, dx do
        for j = y, dy do
            periph.setCursorPos(i, j)
            periph.write(" ")
        end
    end
    
    if (#self.children > 0) then
        for _, child in ipairs(self.children) do
            child:render()
        end
    end
end

-----------------------
--- VISUAL INSTANCE ---
-----------------------
local VisualInstance = newClass({
    ["backgroundColor"] = colors.white,
    ["textColor"] = colors.black,
    ["text"] = "text",
    ["visible"] = true,
    ["alignText"] = "center",
    ["justifyText"] = "center",
    ["units"] = {}
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

-- Will give an ArrayIndexOutOfBoundsException if the face is invalid or there isn't a peripheral connected to it.
-- I cannot figure out why. Nothing stops it. However, that is what the error is.
function Device:connect(face)
    if (peripheral.isPresent(face)) then
        self.peripheral = peripheral.wrap(face)

        local width, height = self.peripheral.getSize();
        self.width = width;
        self.height = height;
    else
        error("Peripheral expected on the " .. face .. " side.")
    end
end

function Device:find(periphType)
    for _, face in ipairs(faces) do
        if peripheral.isPresent(face) and peripheral.getType(face) == periphType then
            self.peripheral = peripheral.wrap(face)

            local width, height = self.peripheral.getSize();
            
            self.width = width;
            self.height = height;

            return
        end
    end
    
    error("Peripheral of type '" .. periphType .. "' not found")
end

instanceTypes = {
    ["device"] = Device,
    ["frame"] = Frame,
    ["textlabel"] = TextLabel
}

device.peripheral.setBackgroundColor(colors.black)
device.peripheral.clear()