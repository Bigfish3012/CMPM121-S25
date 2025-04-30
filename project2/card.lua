-- card
require "vector"

CardClass = {}

CARD_STATE = {
  IDLE = 0,
  MOUSE_OVER = 1,
  GRABBED = 2
}

local suitPrefix = {
  Hearts = "H",
  Spades = "S",
  Clubs = "C",
  Diamonds = "D"
}
local suitFolder = {
  Hearts = "hearts",
  Spades = "spades",
  Clubs = "clubs",
  Diamonds = "diamonds"
}

local cardImages = {}
for suit, prefix in pairs(suitPrefix) do
  cardImages[suit] = {}
  for value = 1, 13 do
    local path = string.format("sprites/%s/%s%d.png", suitFolder[suit], prefix, value)
    cardImages[suit][value] = love.graphics.newImage(path)
  end
end
local cardBackImage = love.graphics.newImage("sprites/card_back.png")

function CardClass:new(xPos, yPos, suit, value, faceUp)
  local card = {}
  local metadata = {__index = CardClass, __tostring = CardClass.__tostring}
  setmetatable(card, metadata)
  
  card.position = Vector(xPos, yPos)
  card.size = Vector(60, 80)
  card.state = CARD_STATE.IDLE
  
  card.suit = suit or "Spades"
  card.value = value or 1
  card.rank = CardClass:convertValueToRank(card.value)
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
  if self.faceUp then
    -- 正面：画图片
    local img = cardImages[self.suit][self:getValue()]
    if img then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, self.position.x, self.position.y, 0, self.size.x / img:getWidth(), self.size.y / img:getHeight())
    else
      -- 没有图片时画个红框
      love.graphics.setColor(1, 0, 0)
      love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y)
    end
  else
    -- 背面
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(cardBackImage, self.position.x, self.position.y, 0, self.size.x / cardBackImage:getWidth(), self.size.y / cardBackImage:getHeight())
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

function CardClass:getValue()
  -- 1~13
  if type(self.value) == "number" then return self.value end
  local lookup = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
  return lookup[self.rank] or 1
end

function CardClass.rankToValue(rank)
  local lookup = {
    A = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4,
    ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8,
    ["9"] = 9, ["10"] = 10, J = 11, Q = 12, K = 13
  }
  return lookup[rank] or 0
end
