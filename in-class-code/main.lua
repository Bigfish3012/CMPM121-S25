-- Chengkun Li
-- CMPM 121 - Day 3 Demo
-- 4/4/2025
io.stdout:setvbuf("no") -- prints statements in real time

testObjects = {}

function love.load()
    print("are you here?")
    local aTable = {
        [1] = "A";
        [2] = "B";
        [3] = "C";
    }
    for k,v in ipairs(aTable) do
        print(tostring(k) .. " : " .. tostring(v))
    end

    print(" - noIndex Table -")
    local noIndexTable = {
        "A",
        "B",
        "C",
        "D",
    }
    for k,v in ipairs(noIndexTable) do
        print(tostring(k) .. " : " .. tostring(v))
    end

    print(" - Mess Table -")
    local messTable = {
        [1] = "A",
        ["cheese"] = "B",
        [false] = "C",
        [4.5] = "D",
        [{x, y}] = "E"
    }
    for k,v in pairs(messTable) do
        print(tostring(k) .. " : " .. tostring(v))
    end

end

function love.update()
  if love.keyboard.isDown("w", "s", "a", "d") then
    local testObj = TestClass:new(100, 150, 0)
    table.insert(testObjects, testObj)
  end
end

function love.draw()
  for _, obj in ipairs(testObjects) do
    obj:draw()
  end
end