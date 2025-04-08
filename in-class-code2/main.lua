--Chengkun Li
-- CMPM 121 Update
--date: 4/7/2025
io.stdout:setvbuf("no")


require "entity"

function love.load()
  screenWidth = 640
  screenHeight = 480
  love.window.setMode(screenWidth, screenHeight)
  love.graphics.setBackgroundColor(0.2, 0.7, 0.2, 1)
  
  entityTable = {}
  
  table.insert(entityTable,
    EntityClass:new(100, 100, 50, 50)
  )
end

function love.update()
  for _, entity in ipairs(entityTable) do
    entity:update()
  end
  if love.keyboard.isDown("f") then
    print("keyboard_down")
  end
  
end

function love.draw()
  for _, entity in ipairs(entityTable) do
    entity:draw()
  end
end
