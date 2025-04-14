
require "vector"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)
  
  grabber.previousMousePos = nil
  grabber.currentMousePos = nil
  
  grabber.grabPos = nil
  
  -- NEW: we'll want to keep track of the object (ie. card) we're holding
  grabber.heldObject = nil
  
  return grabber
end

function GrabberClass:update()
  self.currentMousePos = Vector(
    love.mouse.getX(),
    love.mouse.getY()
  )
  
  -- Click (just the first frame)
  if love.mouse.isDown(1) and self.grabPos == nil then
    self:grab()
  end
  -- Release
  if not love.mouse.isDown(1) and self.grabPos ~= nil then
    self:release()
  end  
end

function GrabberClass:grab()
  self.grabPos = self.currentMousePos
  print("GRAB - " .. tostring(self.grabPos))
  for _, card in ipairs(cardTable) do
    if card.state == CARD_STATE.MOUSE_OVER then
      self.heldObject = card
      card.state = CARD_STATE.GRABBED
      card.originalPosition = Vector(card.position.x, card.position.y) -- store original
      break
    end
  end
end
function GrabberClass:release()
  --print("RELEASE - ")
  -- NEW: some more logic stubs here
  if self.heldObject == nil then -- we have nothing to release
    return
  end
  
  -- TODO: eventually check if release position is invalid and if it is
  -- return the heldObject to the grabPosition
  local isValidReleasePosition = self:checkValidDrop(self.heldObject) -- *insert actual check instead of "true"*
  if isValidReleasePosition then
    self.heldObject.position = self.heldObject.originalPosition
  end
  
  self.heldObject.state = CARD_STATE.IDLE -- it's no longer grabbed
  
  self.heldObject = nil
  self.grabPos = nil
end

function GrabberClass:checkValidDrop(card)
  -- Example: you could make sure it's dropped inside a region
  local x, y = card.position.x, card.position.y
  return x > 50 and x < 900 and y > 50 and y < 600
end



