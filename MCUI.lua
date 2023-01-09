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

function math.clamp(min, max, value)
    if (value < min) then return min end
    if (value > max) then return max end
    return value;
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

        if (unit == "x" or unit == "y") then
            self[unit] = self[unit] + self.parent[unit]
        end
    end)
end

function Instance:processChildUnits()
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

    self:processChildUnits();
    self:orderChildren();

    if (self.transparent) then
        self:renderChildren();
        return
    end
    
    local maxX = parent.x + parent.width
    local maxY = parent.y + parent.height
    
    local x = self.x + 1
    local dx = x + self.width - 1
    
    local y = self.y + 1
    local dy = y + self.height - 1

    if (parent.overflow == "hidden") then
        x = math.clamp(parent.x + 1, maxX, x);
        dx = math.clamp(parent.x, maxX, dx);
        y = math.clamp(parent.y, maxY, y);
        dy = math.clamp(parent.y, maxY, dy);
    end
    
    local periph = self:findDevice();
    periph.setBackgroundColor(self.backgroundColor);

    paintutils.drawFilledBox(x, y, dx, dy, self.backgroundColor)
    
    self:renderChildren();
end

function Frame:orderChildren()
    if (self.display == "grid") then
        local cY = 0;
        local rowHeight = 1;

        local columnGap = self.columnGap or 0;
        local rowGap = self.rowGap or 0;

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
        local i = 0;

        -- Keep looping until every child has been accounted for
        repeat
            currentColumn = {};
            rowHeight = 2;
            count = 0;

            -- Loop until a full column has been used
            repeat
                i = i + 1;
                
                local child = children[i];

                -- Means the end of the list has been reached
                if (child == nil) then break end

                if (child.cw) then
                    if (count + child.cw > columnUnits) then break end

                    count = count + child.cw
                end
                
                table.insert(currentColumn, child)

                if (child.height) then
                    rowHeight = math.max(rowHeight, child.height)
                end
            until i > #children or count == columnUnits
            
            j = j + i;

            -- remaining width;
            -- current x
            local rWidth = self.width - (columnGap * (#currentColumn + 1));
            local cX = self.x + columnGap + 1;
            
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
                    child.width = math.floor(rWidth * (child.cw / columnUnits))  
                end
                
                child.y = cY
                child.units.y = newUnit(cY, "px")
                
                if (child.height < 1) then
                    child.height = rowHeight
                    child.units.height = newUnit(child.height, "px")
                end
                
                child.x = cX - 1
                
                cX = cX + child.width + columnGap
            end)

            cY = cY + rowHeight
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
    if (self.peripheral ~= term) then
        term.redirect(self.peripheral)
    end

    self:processChildUnits();
    self:renderChildren();

    term.native()
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
testFrame.width = "100%";

local two = Instance.new("frame", "two", testFrame);
two.width = "5px";
two.backgroundColor = colors.white

local three = Instance.new("frame", "three", testFrame);
three.backgroundColor = colors.green

local four = Instance.new("frame", "four", testFrame)
four.backgroundColor = colors.red;
four.height = "30%";
four.transparent = false

two.display = "grid";
two.columns = 4;

local five = Instance.new("frame", "five", two);
five.width = "5px";
five.height = "100%";
five.backgroundColor = colors.pink;
five.column = 2;
five.cw = 3;

local six = Instance.new("frame", "six", two);
six.cw = 1;
six.height = "100%";
six.backgroundColor = colors.purple;
six.column = 1;

local eight = Instance.new("frame", "eight", testFrame);
eight.width = "10px";
eight.backgroundColor = colors.lime
eight.column = 5;

local seven = Instance.new("frame", "seven", testFrame);
seven.cw = 4;
seven.backgroundColor = colors.brown
seven.column = 6;
seven.height = "30%"

testFrame.columns = 4
testFrame.width = "90%"
testFrame.x = "0px";
testFrame.overflow = "hidden";
testFrame.columnGap = 1;

two.column = 0;
two.cw = 2;

three.column = 1;
three.cw = 1;

four.column = 2;
four.cw = 1;

device.peripheral.setBackgroundColor(colors.black)
device.peripheral.clear()   
device:rerender()

local i = 0;
while true do
    os.sleep(0.05)
    i = i + 0.05;
    testFrame.width = (math.sin(i) * 100) + 1 .. "%";
    
    device.peripheral.setBackgroundColor(colors.black)
    device.peripheral.clear()       
    device:rerender()
end