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
  
  card.suit = suit
  card.value = value
  card.faceUp = faceUp or false
  card.canDrag = false
  card.isDeckPile = false
  
  return card
end

function CardClass:update()
  if self.state == CARD_STATE.GRABBED then
    self.position = grabber.currentMousePos + grabber.dragOffset
  end
end

function CardClass:draw()
  if self.faceUp then
    local img = cardImages[self.suit][self.value]
    love.graphics.draw(img, self.position.x, self.position.y)
  else
    -- Use return image if deck pile is empty
    if #deckPile == 0 and self.isDeckPile then
      love.graphics.draw(returnBackImage, self.position.x, self.position.y)
    else
      love.graphics.draw(cardBackImage, self.position.x, self.position.y)
    end
  end
end

-- Check if mouse is over the card
function CardClass:checkForMouseOver(grabber)
  -- Skip check if card is already grabbed
  if self.state == CARD_STATE.GRABBED then
    return
  end
  
  local mousePos = grabber.currentMousePos
  local w, h = self:getCardDimensions()
  
  -- Check card position in tableau piles
  local isInTableauPile, visibleHeight = self:getTableauPileInfo()
  
  -- Determine if mouse is over this card
  local isMouseOver = self:isPointOverCard(mousePos.x, mousePos.y, w, h, isInTableauPile, visibleHeight)
  
  -- Update card state based on mouse position
  self.state = isMouseOver and CARD_STATE.MOUSE_OVER or CARD_STATE.IDLE
end

-- Helper function to check card position in tableau piles
function CardClass:getTableauPileInfo()
  local isInTableauPile = false
  local isTopCard = true
  local visibleHeight = nil  -- Will be set to card height or 20 for stacked cards
  
  -- Check each tableau pile
  for _, pile in ipairs(tableauPiles) do
    for cardIndex, card in ipairs(pile) do
      if card == self then
        isInTableauPile = true
        -- If not the top card, only a portion is visible
        if cardIndex < #pile then
          isTopCard = false
          visibleHeight = 20  -- Only 20 pixels visible for stacked cards
        end
        break
      end
    end
    if isInTableauPile then break end
  end
  
  -- If not set yet, use full card height
  if not visibleHeight then
    visibleHeight = self:getCardDimensions()
  end
  
  return isInTableauPile, visibleHeight
end

-- Helper function to check if a point is over the card
function CardClass:isPointOverCard(x, y, width, height, isInTableauPile, visibleHeight)
  -- For tableau cards that are not on top, only check the visible portion
  if isInTableauPile and visibleHeight == 20 then
    return x > self.position.x and 
           x < self.position.x + width and 
           y > self.position.y and
           y < self.position.y + visibleHeight
  else
    -- For other cards, check the whole area
    return x > self.position.x and 
           x < self.position.x + width and 
           y > self.position.y and
           y < self.position.y + height
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
