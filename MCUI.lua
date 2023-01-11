-- MCUI vb0.1.1
-- MINOR FUNCTIONS
function table.findIndx(f, l)-- find the first elemnt that satisfies f(v) and return its index
    for i, v in ipairs(l) do
        if f(v) then
            return i
        end
    end
    return nil
end

function table.find(l, f)-- find the first element that satisfies f(v) and return it, and then its index
    for i, v in ipairs(l) do
        if f(v) then
            return v, i;
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
-- 3 display types. Normal, grid, and flex
-- Grid uses columns and rows
local Frame = newClass({
    ["backgroundColor"] = colors.white,
    ["visible"] = true,
    ["transparent"] = false,
    ["display"] = "normal"
})
Frame.__index = Frame

function Frame:render()
    local parent = self.parent
    
    self:orderChildren();
    
    if (self.transparent) then
        self:renderChildren();
        return
    end
    
    local maxX = parent.x + parent.width - 1
    local maxY = parent.y + parent.height - 1
    
    local x = self.x;
    local dx = x + self.width - 1;
    
    local y = self.y;
    local dy = y + self.height - 1;
    
    if (parent.overflow == "hidden") then
        x = math.max(parent.x, x);
        dx = math.min(maxX, dx);

        y = math.max(parent.y, y);
        dy = math.min(maxY, dy);
    end
    
    local periph = self:findDevice();
    periph.setBackgroundColor(self.backgroundColor);
    
    paintutils.drawFilledBox(x, y, dx, dy, self.backgroundColor)
    
    self:renderChildren();
end

function Frame:orderChildren()
    if (self.display == "grid") then
        -- The default height of a row if none of its items have a set height.
        local rowHeight = 1;

        -- Current Y. Keeps track of the current rows starting Y.
        local cY = 0;
        
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
            if (not a.order and b.order) then return false end
            if (not b.order and a.order) then return true end
            if (not a.order and not b.order) then return false end
            
            return a.order < b.order
        end)
        
        local j = 1
        local i = 0;
        
        -- Keep looping until every child has been accounted for
        repeat
            currentColumn = {};
            rowHeight = 2;
            count = 0;
            
            -- Loop until a full column has been used (based on cw)
            repeat
                i = i + 1;
                
                local child = children[i];
                
                -- Means the end of the list has been reached
                if (child == nil) then break end
                
                if (not child.order) then
                    child.order = i;
                end

                if (child.cw) then
                    if (count + child.cw > columnUnits) then
                        i = i - 1;
                        break
                    end
                    
                    count = count + child.cw
                end
                
                table.insert(currentColumn, child)
                
                if (child.ch) then
                    child.height = round((child.ch / rowUnits) * height);
                end

                if (child.height) then
                    rowHeight = math.max(rowHeight, child.height)
                end
            until i > #children
            
            j = j + i;
            
            -- remaining width;
            -- current x
            -- usedWidth
            local rWidth = self.width - (columnGap * (#currentColumn - 1));
            local cX = self.x + 1;
            local usedWidth = 0;
            
            -- First, get all of the fixed width items and subtract their sizes from the total width
            table.forEach(currentColumn, function(child)
                if (not child.cw) then
                    rWidth = rWidth - child.width;
                end
            end)
            
            -- Use the remaining width to calculate the sizes for every child in the column
            table.forEach(currentColumn, function(child, i)
                if (child.cw) then
                    child.width = math.floor(rWidth * (child.cw / columnUnits))
                end
                
                if (not child.height or child.height == 0) then
                    child.height = rowHeight
                end
                
                child.x = cX - 1
                child.y = cY
                
                cX = cX + child.width + columnGap
                usedWidth = usedWidth + child.width;
            end)
            
            cY = cY + rowHeight
            
            -- Quick filter to make sure that rows always fill the entire space
            if (count == columnUnits and usedWidth < rWidth) then
                local difference = rWidth - usedWidth;
                
                -- Get the first child that is sized using cw;
                local child, indx = table.find(currentColumn, function(v)
                    return v.cw
                end)
                
                -- Tack on the extra unused space
                child.width = child.width + difference
                
                -- Move over all following items accordingly
                for i = indx + 1, #currentColumn do
                    currentColumn[i].x = currentColumn[i].x + difference
                end
            end
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
testFrame.transparent = false;
testFrame.backgroundColor = colors.white;
testFrame.display = "grid";
testFrame.overflow = "hidden";
testFrame.width = 51;
testFrame.height = 10;

testFrame.columns = 12;
testFrame.columnGap = 1;

local one = Instance.new("frame", "one", testFrame);
one.backgroundColor = colors.red;
one.cw = 6;
one.ch = 12;

local secondGrid = Instance.new("frame", "second", testFrame);
secondGrid.display = "grid";
secondGrid.transparent = true;
secondGrid.cw = 6;
secondGrid.ch = 12;
secondGrid.overflow = "hidden";

local two = Instance.new("frame", "two", secondGrid);
two.cw = 12;
two.ch = 6;
two.backgroundColor = colors.green;

local three = Instance.new("frame", "three", secondGrid);
three.cw = 12;
three.ch = 6;
three.backgroundColor = colors.pink;

device.peripheral.setBackgroundColor(colors.black)
device.peripheral.clear()
device:rerender()

local i = 0;
local width = 10;

function listenForScroll()
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if (event == "mouse_drag") then
            local x = p2;
            local y = p3;
            
            testFrame.width = x;
            testFrame.height = y;
        end
    end
end

function rerender()
    while true do
        os.sleep(0.05);
        
        device.peripheral.setBackgroundColor(colors.black)
        device.peripheral.clear()
        device:rerender()
    end
end

parallel.waitForAll(listenForScroll, rerender)
