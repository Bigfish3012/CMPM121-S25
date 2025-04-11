
require "vector"

CardClass = {}

CARD_STATE = {
  idle = 0,
  mouse_over = 1,
  grabbed = 2
}


function CardClass:new(xPos, yPos)
  local card = {}
  local metadata = {__index = CardClass}
  setmetatable(card, metadata)
  
  card.position = Vector(xPos, yPos)
  card.size = Vector(50, 70)
  card.state = CARD_STATE.idle
  
  return card
end

function CardClass:update()
  
end

function CardClass:draw()
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)
  
  love.graphics.print(tostring(self, state), self.position.x + 20, self.position.y - 20)
end

function CardClass:checkForMouseOver()
  if self.state == CARD_STATE.grabbed then
    return
  end
    
  local mousePos = grabber.currentMousePos
  local isMouseOver = 
    mousePos.x > self.position.x and 
    mousePos.x < self.position.x + self.size.x and 
    mousePos.y > self.position.y and
    mousePos.y < self.position.y + self.size.y
  
  self.state = isMouseOver and CARD_STATE.mouse_over or CARD_STATE.idle
  
end
