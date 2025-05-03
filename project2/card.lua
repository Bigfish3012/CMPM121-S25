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
local returnBackImage = love.graphics.newImage("sprites/return_back.png")

function CardClass:new(xPos, yPos, suit, value, faceUp)
  local card = {}
  local metadata = {__index = CardClass}
  setmetatable(card, metadata)
  
  card.position = Vector(xPos, yPos)
  card.state = CARD_STATE.IDLE
  
  card.suit = suit or "Spades"
  card.value = value or 1
  card.faceUp = faceUp or false
  card.canDrag = false
  card.isDeckPile = false  -- Flag to identify if card is in deck pile
  
  return card
end

function CardClass:update()
  if self.state == CARD_STATE.GRABBED then
    self.position = grabber.currentMousePos + grabber.dragOffset
  end
end

function CardClass:draw()
  if self.faceUp then
    -- face up: draw image, original size
    local img = cardImages[self.suit][self.value]
    love.graphics.draw(img, self.position.x, self.position.y)
  else
    -- back side: draw image, original size
    -- Use return image if deck pile is empty and this is the deck pile placeholder
    if #deckPile == 0 and self.isDeckPile then
      love.graphics.draw(returnBackImage, self.position.x, self.position.y)
    else
      love.graphics.draw(cardBackImage, self.position.x, self.position.y)
    end
  end
end

-- Check if mouse is over the card
function CardClass:checkForMouseOver(grabber)
  if self.state == CARD_STATE.GRABBED then
    return
  end
  local mousePos = grabber.currentMousePos
  local img
  
  if self.faceUp then
    img = cardImages[self.suit][self.value]
  else
    -- Use appropriate back image based on deck state
    if #deckPile == 0 and self.isDeckPile then
      img = returnBackImage
    else
      img = cardBackImage
    end
  end
  
  local w, h = img:getWidth(), img:getHeight()
  
  -- Check if this card is in a tableau pile, and is not the top card
  local isInTableauPile = false
  local isTopCard = true
  local visibleHeight = h  -- Default whole card visible
  
  for pileIndex, pile in ipairs(tableauPiles) do
    for cardIndex, card in ipairs(pile) do
      if card == self then
        isInTableauPile = true
        -- if not the top card on the pile
        if cardIndex < #pile then
          isTopCard = false
          visibleHeight = 20
        end
        break
      end
    end
    if isInTableauPile then break end
  end
  
  -- check if mouse is over the card
  local isMouseOver = false
  
  if isInTableauPile and not isTopCard then
    -- if in tableau pile and not the top card, only check the top visible area of the card
    isMouseOver = 
      mousePos.x > self.position.x and 
      mousePos.x < self.position.x + w and 
      mousePos.y > self.position.y and
      mousePos.y < self.position.y + visibleHeight
  else
    -- other cases (single card or top card on pile), check the whole card area
    isMouseOver = 
      mousePos.x > self.position.x and 
      mousePos.x < self.position.x + w and 
      mousePos.y > self.position.y and
      mousePos.y < self.position.y + h
  end
  
  if isMouseOver then
    self.state = CARD_STATE.MOUSE_OVER
  else
    self.state = CARD_STATE.IDLE
  end
end

-- Get card color
function CardClass:getColor()
  if self.suit == "Hearts" or self.suit == "Diamonds" then
    return "red"
  else
    return "black"
  end
end

-- Get card dimensions
function CardClass:getCardDimensions()
  local img
  
  if self.faceUp then
    img = cardImages[self.suit][self.value]
  else
    -- Use appropriate back image based on deck state
    if #deckPile == 0 and self.isDeckPile then
      img = returnBackImage
    else
      img = cardBackImage
    end
  end
  
  return img:getWidth(), img:getHeight()
end
