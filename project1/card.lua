--card file

require "vector"

CardClass = {}

CARD_STATE = {
  IDLE = 0,
  MOUSE_OVER = 1,
  GRABBED = 2
}


-- load the suit images
local suitImages = {
  Hearts = love.graphics.newImage("images/Heart.png"),
  Spades = love.graphics.newImage("images/Spade.png"),
  Clubs = love.graphics.newImage("images/Club.png"),
  Diamonds = love.graphics.newImage("images/Diamond.png")
}

function CardClass:new(xPos, yPos, suit, value, faceUp)
  local card = {}
  local metadata = {__index = CardClass, __tostring = CardClass.__tostring}
  setmetatable(card, metadata)
  
  card.position = Vector(xPos, yPos)
  card.size = Vector(60, 80)
  card.state = CARD_STATE.IDLE
  
  card.suit = suit or "Spades"
  card.rank = CardClass:convertValueToRank(value or 1) -- A, 2...10, J, Q, K
  card.faceUp = faceUp or false
  card.canDrag = false
  
  return card
end

function CardClass:__tostring()
  return string.format("Card(%s %s)", self:getSuitSymbol(), self.rank)
end

function CardClass:convertValueToRank(value)
  local ranks = {
    [1] = "A", [2] = "2", [3] = "3", [4] = "4", [5] = "5",
    [6] = "6", [7] = "7", [8] = "8", [9] = "9", [10] = "10",
    [11] = "J", [12] = "Q", [13] = "K"
  }
  return ranks[value] or tostring(value)
end

function CardClass:update()
  if self.state == CARD_STATE.GRABBED then
    self.position = grabber.currentMousePos - self.size * 0.5
  end
end

function CardClass:draw()
  -- 1. the color of the card
  if self.faceUp then
    love.graphics.setColor(1, 1, 1, 1) -- white
  else
    love.graphics.setColor(0.2, 0.2, 1.0) -- blue
  end
  love.graphics.rectangle("fill", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)

  -- 2. Stroke
  if not self.faceUp then
    love.graphics.setColor(1.0, 0.4, 0.7) -- pink
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)
  end
  
  if self.faceUp then
    love.graphics.setColor(0.969, 0.678, 0.169) -- brown
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)
  end
  

  -- 3. Display the rank in the upper left corner
  if self.faceUp then
    local symbol = self:getSuitSymbol()
    local rank = self.rank

    -- set it to red or black
    if self.suit == "Hearts" or self.suit == "Diamonds" then
      love.graphics.setColor(1, 0, 0) -- 红色
    else
      love.graphics.setColor(0, 0, 0) -- 黑色
    end

    -- the rank in the upper left corner
    love.graphics.print(rank, self.position.x + 5, self.position.y + 5)

    -- Get the  image
    local suitImg = suitImages[self.suit]

    -- upper right corner suit iamge
    if suitImg then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(suitImg, self.position.x + 40, self.position.y + 7, 0, 0.5, 0.5)
    end

    -- center suit image
    if suitImg then
      local imgW = suitImg:getWidth()
      local imgH = suitImg:getHeight()
      local scale = 2
      local centerX = self.position.x + (self.size.x - imgW * scale) / 2
      local centerY = self.position.y + (self.size.y - imgH * scale) / 2 + 10
      love.graphics.draw(suitImg, centerX, centerY, 0, scale, scale)
    end
  end
end



function CardClass:checkForMouseOver(grabber)
  if self.state == CARD_STATE.GRABBED then
    return
  end
  local mousePos = grabber.currentMousePos
  local isMouseOver = 
    mousePos.x > self.position.x and 
    mousePos.x < self.position.x + self.size.x and 
    mousePos.y > self.position.y and
    mousePos.y < self.position.y + self.size.y
  self.state = isMouseOver and CARD_STATE.MOUSE_OVER or CARD_STATE.IDLE
  
end

function CardClass:getSuitSymbol()
  local symbols = {
    Hearts = "Heart",
    Spades = "Spade",
    Clubs = "Club",
    Diamonds = "Diamond"
  }
  return symbols[self.suit] or "ERROR"
end

function CardClass:getColor()
  if self.suit == "Hearts" or self.suit == "Diamonds" then
    return "red"
  else
    return "black"
  end
end

function CardClass.rankToValue(rank)
  local lookup = {
    A = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4,
    ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8,
    ["9"] = 9, ["10"] = 10, J = 11, Q = 12, K = 13
  }
  return lookup[rank] or 0
end
