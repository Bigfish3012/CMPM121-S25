--grabber

require "vector"
local GrabberHelper = require "grabber_helper"
local Helper = require "helper"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)
  
  grabber.currentMousePos = nil
  grabber.grabPos = nil
  grabber.dragOffset = nil
  
  grabber.heldObject = nil
  grabber.heldStack = {}
  grabber.ignoreNextGrab = false
  
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
    if self.ignoreNextGrab then
      self.ignoreNextGrab = false
    end
  end
  -- Release
  if not love.mouse.isDown(1) and self.grabPos ~= nil then
    self:release()
  end
  
  -- Update stack positions if dragging
  if #self.heldStack > 1 and self.heldObject and self.heldObject.state == CARD_STATE.GRABBED then
    local basePos = self.heldObject.position
    for i = 2, #self.heldStack do
      self.heldStack[i].position = Vector(basePos.x, basePos.y + (i-1) * 20)
      -- Move each card to top for rendering order
      GrabberHelper.moveCardToTop(self.heldStack[i])
    end
  end
end

-- Helper function to grab a stack of cards from a tableau pile
function GrabberClass:grabTableauStack(card, pileIndex, cardIndex)
  local pile = tableauPiles[pileIndex]
  self.heldStack = {}
  
  -- Add all cards from cardIndex to the end of the pile to the held stack
  for i = cardIndex, #pile do
    table.insert(self.heldStack, pile[i])
    
    -- Store original positions for all cards in stack
    pile[i].originalPosition = Vector(pile[i].position.x, pile[i].position.y)
    
    -- Move each card to top for rendering order
    GrabberHelper.moveCardToTop(pile[i])
  end
end

function GrabberClass:grab()
  -- If we should ignore this grab, reset the flag and return
  if self.ignoreNextGrab then
    self.ignoreNextGrab = false
    return
  end

  for _, card in ipairs(cardTable) do
    if card.state == CARD_STATE.MOUSE_OVER and card.canDrag then
      self.heldObject = card
      card.state = CARD_STATE.GRABBED
      card.originalPosition = Vector(card.position.x, card.position.y) -- store original
      self.grabPos = self.currentMousePos -- Only set if successfully caught
      
      -- Calculate drag offset as card position minus mouse position to maintain correct relative position
      self.dragOffset = Vector(card.position.x, card.position.y) - self.currentMousePos
      
      -- Find card in tableau
      local cardLocation = GrabberHelper.findCardInTableau(card)
      
      -- If this card is in a tableau pile and face up, grab all cards below it too
      if cardLocation.pileIndex and cardLocation.cardIndexInPile and card.faceUp then
        -- Handle tableau stack
        self:grabTableauStack(card, cardLocation.pileIndex, cardLocation.cardIndexInPile)
      else
        -- Just a single card from draw pile or suit pile
        self.heldStack = {card}
        -- Move grabbed card to top of render order
        GrabberHelper.moveCardToTop(card)
      end
      
      return
    end
  end
end

-- Helper function to find a valid placement for a card or stack
function GrabberClass:findValidPlacement(card, heldStack)
  -- Check suit piles (single card only)
  if #heldStack == 1 then
    for suitIndex, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
      local suitPos = suitPilePositions[suitIndex]
      local w, h = card:getCardDimensions()
      local cardCenterX = card.position.x + w / 2
      local cardCenterY = card.position.y + h / 2
      
      if GrabberHelper.canPlaceOnSuitPilePlaceholder(card, suitPos, cardCenterX, cardCenterY) and
         GrabberHelper.canAddToSuitPile(card, suit) then
         return { type = "suit", suit = suit, position = suitPos }
      end
    end
  end
  
  -- Check tableau piles
  for i, pile in ipairs(tableauPiles) do
    local lastCard = pile[#pile]
    if lastCard and lastCard.faceUp then
      local valid = GrabberHelper.isValidTableauMove(card, lastCard)
      if valid then
        local position = Vector(lastCard.position.x, lastCard.position.y + 20)
        return { type = "tableau", pileIndex = i, position = position, baseCard = lastCard }
      end
    elseif #pile == 0 and card.value == 13 then
      local position = Vector(150 + (i - 1) * 95, 190)
      return { type = "tableau", pileIndex = i, position = position }
    end
  end
  
  -- No valid placement found
  return nil
end

-- Separate the logic of moving cards into a standalone function
function GrabberClass:handleCardMove(placement, sourceInfo)
  if placement.type == "suit" then
    -- Remove card from source
    if sourceInfo.fromDrawPile then
      GrabberHelper.removeCardFromDrawPile(self.heldObject)
    elseif sourceInfo.fromPileIndex then
      GrabberHelper.removeCardsFromTableau(sourceInfo.fromPileIndex, self.heldStack)
    elseif sourceInfo.fromSuitPile then
      GrabberHelper.removeFromSuitPile(self.heldObject)
    end
    
    -- Add to suit pile
    GrabberHelper.addToSuitPile(self.heldObject, placement.suit)
    
    -- If card came from tableau pile, turn over the next card
    if sourceInfo.fromPileIndex then
      GrabberHelper.turnOverTopCard(sourceInfo.fromPileIndex)
    end
  elseif placement.type == "tableau" then
    -- Position the held card
    self.heldObject.position = placement.position
    
    -- Remove card from original position
    if sourceInfo.fromDrawPile then
      GrabberHelper.removeCardFromDrawPile(self.heldObject)
    elseif sourceInfo.fromSuitPile then
      GrabberHelper.removeFromSuitPile(self.heldObject)
    elseif sourceInfo.fromPileIndex then
      GrabberHelper.removeCardsFromTableau(sourceInfo.fromPileIndex, self.heldStack)
    end
    
    -- Add all cards to the target pile
    GrabberHelper.addCardsToTableau(tableauPiles[placement.pileIndex], self.heldStack, placement.position)
  end
end

-- Simplify the release function
function GrabberClass:release()  
  -- Find the source of the card
  local sourceInfo = GrabberHelper.findCardSource(self.heldObject)
  
  -- Find a valid placement for the held object
  local placement = self:findValidPlacement(self.heldObject, self.heldStack)
  
  if placement then
    -- Valid placement found, handle card movement
    self:handleCardMove(placement, sourceInfo)
  else
    -- No valid placement, return cards to original positions
    for _, card in ipairs(self.heldStack) do
      card.position = card.originalPosition
    end
  end
  
  -- Reset state
  self:resetGrabState()
end

-- Reset grabber state
function GrabberClass:resetGrabState()
  if self.heldObject then
    self.heldObject.state = CARD_STATE.IDLE
  end
  self.heldObject = nil
  self.grabPos = nil
  self.dragOffset = nil
  self.heldStack = {}
  self.ignoreNextGrab = false
end
