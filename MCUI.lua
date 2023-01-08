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

function table.forEach(l, f)
    for i, v in ipairs(l) do
        f(v, i);
    end
end

function table.forKey(d, f)
    for k, v in pairs(d) do
        f(v, k);
    end
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

function processUnitString(str)
    local number = str:match("%d+")
    local unit = str:match("%%")

    if number then
        number = tonumber(number)
    end
    if not unit then
        unit = "px"
    end

    return number, unit
end

function newUnit(value, unit)
    return {
        ["value"] = value;
        ["unit"] = unit;
    }
end

function round(value)
    return math.floor(value + 0.5)
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
    
    newInstance.units = {
        ["x"] = newUnit(0, "px"),
        ["y"] = newUnit(0, "px"),
        ["width"] = newUnit(0, "px"),
        ["height"] = newUnit(0, "px")
    }

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

function Instance:processUnits()
    local unitRelatives = {
        ["x"] = "width",
        ["y"] = "height",
        ["width"] = "width",
        ["height"] = "height"
    }

    -- Find any new units that have been changed and update the instances unit data, then recalculate all the values based on the data
    table.forKey(unitRelatives, function(relative, unit) 
        if (type(self[unit]) == "string") then
            local value, new = processUnitString(self[unit]);
            
            self.units[unit] = newUnit(value, new)
        end
        
        local unitData = self.units[unit];
        local value = unitData.value;
        local currUnit = unitData.unit;

        if (currUnit == "%") then
            self[unit] = round(self.parent[relative] * (value / 100));
        else
            self[unit] = value;
        end
    end)
end

function Instance:processChildrenUnits()
    if (#self.children > 0) then
        for _,child in ipairs(self.children) do
            child:processUnits();
        end
    end
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

function Instance:renderChildren()
    if (#self.children > 0) then
        for _, child in ipairs(self.children) do
            child:render()
        end
    end
end

-------------
--- FRAME ---
-------------

-- 3 display types. normal, grid, and flex

-- grid uses columns and rows

local Frame = newClass({
    ["backgroundColor"] = colors.white,
    ["visible"] = true,
    ["transparent"] = false,
    ["display"] = "normal"
})
Frame.__index = Frame

function Frame:render()
    local parent = self.parent

    self:processChildrenUnits();
    self:orderChildren();

    if (self.transparent) then
        self:renderChildren();
        return
    end
    
    local maxX = parent.x + parent.width
    local maxY = parent.y + parent.height
    
    local x = parent.x + self.x + 1
    local dx = math.min(x + self.width - 1, maxX)
    
    local y = parent.y + self.y + 1
    local dy = math.min(y + self.height - 1, maxY)
    
    local periph = self:findDevice();
    periph.setBackgroundColor(self.backgroundColor);
    
    for i = x, dx do
        for j = y, dy do
            periph.setCursorPos(i, j)
            periph.write(" ")
        end
    end
    
    self:renderChildren();
end

function Frame:orderChildren()
    if (self.display == "grid") then
        local width = self.width;
        local height = self.height;

        local columnUnits = self.columns or 12;
        local rowUnits = self.rows or 12;

        local children = self.children;

        local count = 0;
        local currentColumn = {}

        table.sort(children, function(a, b)
            if (not a.column and b.column) then return false end
            if (not b.column and a.column) then return true end
            if (not a.column and not b.column) then return false end

            return a.column < b.column
        end)
        
        local j = 1
        local i = 1;

        -- Keep looping until every child has been accounted for
        repeat
            -- Loop until a full column has been used
            repeat
                local child = children[i];
    
                table.insert(currentColumn, child)
                if (child.cw) then
                    count = count + child.cw
                end

                i = i + 1;
            until count == rowUnits or i > #children

            j = j + i;
    
            -- remaining width;
            -- current x
            local rWidth = width;
            local cX = self.x
            
            -- First, get all of the fixed width items and subtract their sizes from the total width
            table.forEach(currentColumn, function(child)
                if (not child.cw) then
                    rWidth = rWidth - child.width;
                end
            end)
    
            -- Use the remaining width to calculate the sizes for every child in the column
            -- Then give the children those values
            table.forEach(currentColumn, function(child, i)
                
                if (child.cw) then
                    child.width = round(rWidth * (child.cw / columnUnits))
                    child.units.x = newUnit(cX, "px")
                    child.units.width = newUnit(child.width, "px")
                end
                
                child.x = cX
                
                cX = cX + child.width
            end)
        until j > #children
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
    ["framerate"] = 20,
    ["width"] = 51,
    ["height"] = 19
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

function Device:rerender()
    self:processChildrenUnits();
    self:renderChildren();
end

instanceTypes = {
    ["device"] = Device,
    ["frame"] = Frame,
    ["textlabel"] = TextLabel
}

local device = Instance.new("device", "testDevice");

local testFrame = Instance.new("frame", "testFrame", device);
testFrame.height = "100%";
testFrame.transparent = false;
testFrame.backgroundColor = colors.gray;
testFrame.display = "grid";

local two = Instance.new("frame", "two", testFrame);
two.width = "5px";
two.height = "100%";
two.backgroundColor = colors.white

local three = Instance.new("frame", "three", testFrame);
three.backgroundColor = colors.green
three.height = "100%"

local four = Instance.new("frame", "four", testFrame)
four.backgroundColor = colors.red;
four.height = "100%";

-- two.display = "grid";
-- two.columns = 1;

-- local five = Instance.new("frame", "five", two);
-- five.width = "5px";
-- five.height = "100%";
-- five.backgroundColor = colors.pink;
-- five.column = 2;

-- local six = Instance.new("frame", "six", two);
-- six.cw = 1;
-- six.height = "100%";
-- six.backgroundColor = colors.purple;
-- six.column = 1;

testFrame.columns = 3

two.column = 0;
two.cw = 1;

three.column = 1;
three.cw = 1;

four.column = 2;
four.cw = 1;

local i = 0;
while true do
    os.sleep(0.05)
    i = i + 0.1;
    testFrame.width = (math.sin(i) * 100) + 1 .. "%";
    
    device.peripheral.setBackgroundColor(colors.black)
    device.peripheral.clear()       
    device:rerender()
end