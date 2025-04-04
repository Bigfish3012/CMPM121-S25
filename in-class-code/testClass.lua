
TestClass = {}

function TestClass: new(xPos, yPos, rot)
  local testClass = {}
  setmetatable(testClass, {__index = TestClass})
  testClass.postion = {x = xPos, y = yPos}
  testClass.rotation = rot
  return  testClass
end

function TestClass:draw()
  -- TODO: drow it
  
  
end