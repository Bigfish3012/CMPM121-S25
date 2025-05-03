--grabber

require "vector"
local GrabberHelper = require "grabber_helper"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)
  
  grabber.currentMousePos = nil
  grabber.grabPos = nil
  grabber.dragOffset = nil
  
  -- Track the object (card) we're holding
  grabber.heldObject = nil
  -- Track the stack of cards being moved together
  grabber.heldStack = {}
  -- Flag to indicate if we should ignore the next grab attempt
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
    -- 确保ignoreNextGrab标志在第一帧后被重置
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
      
      -- Clear previous held stack
      self.heldStack = {}
      
      -- Find card in tableau
      local cardLocation = GrabberHelper.findCardInTableau(card)
      
      -- If this card is in a tableau pile and face up, grab all cards below it too
      if cardLocation.pileIndex and cardLocation.cardIndexInPile then
        local pile = tableauPiles[cardLocation.pileIndex]
        if card.faceUp then
          -- Add card to stack, and keep correct rendering order
          for i = cardLocation.cardIndexInPile, #pile do
            table.insert(self.heldStack, pile[i])
            
            -- Store original positions for all cards in stack
            if i > cardLocation.cardIndexInPile then
              pile[i].originalPosition = Vector(pile[i].position.x, pile[i].position.y)
            end
            
            -- Move each card to top for rendering order
            GrabberHelper.moveCardToTop(pile[i])
          end
          
          return
        end
      else
        -- Just a single card from draw pile or suit pile
        table.insert(self.heldStack, card)
      end
      
      -- Move grabbed card to top of render order
      GrabberHelper.moveCardToTop(card)
      
      return
    end
  end
end

function GrabberClass:release()
  if self.heldObject == nil then -- we have nothing to release
    return
  end
  
  -- Find the source of the card
  local sourceInfo = GrabberHelper.findCardSource(self.heldObject)
  
  -- First try to place card on a suit pile (only single cards can go to suit piles)
  local placedOnSuitPile = false
  if #self.heldStack == 1 then
    for suitIndex, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
      local suitPos = suitPilePositions[suitIndex]
      local w, h = self.heldObject:getCardDimensions()
      local cardCenterX = self.heldObject.position.x + w / 2
      local cardCenterY = self.heldObject.position.y + h / 2
      
      -- Check if card is over this suit pile placeholder
      if GrabberHelper.canPlaceOnSuitPilePlaceholder(self.heldObject, suitPos, cardCenterX, cardCenterY) then
        
        -- Check if card can be placed in this suit pile
        if canAddToSuitPile(self.heldObject, suit) then
          -- Remove from source pile if needed
          if sourceInfo.fromDrawPile then
            removeCardFromDrawPile(self.heldObject)
          elseif sourceInfo.fromPileIndex then
            GrabberHelper.removeCardsFromTableau(sourceInfo.fromPileIndex, self.heldStack)
          elseif sourceInfo.fromSuitPile then
            removeFromSuitPile(self.heldObject)
          end
          
          -- Add to suit pile
          addToSuitPile(self.heldObject, suit)
          placedOnSuitPile = true
          break
        end
      end
    end
  end
  
  -- If card was placed on a suit pile, we're done
  if placedOnSuitPile then
    -- If card came from tableau pile, turn over next card
    if sourceInfo.fromPileIndex then
      GrabberHelper.turnOverTopCard(sourceInfo.fromPileIndex)
    end
    -- Reset state
    self:resetGrabState()
    return
  end
  
  -- Try to find an available tableauPile to place the cards
  local placed = false
  for i, pile in ipairs(tableauPiles) do
    local lastCard = pile[#pile]
    if lastCard and lastCard.faceUp then
      local valid = GrabberHelper.isValidTableauMove(self.heldObject, lastCard)
      if valid then
        -- Place the stack at this pile
        local yOffset = lastCard.position.y + 20
        self.heldObject.position = Vector(lastCard.position.x, yOffset)
        
        -- First remove cards from their original pile
        if sourceInfo.fromDrawPile then
          removeCardFromDrawPile(self.heldObject)
        elseif sourceInfo.fromSuitPile then
          removeFromSuitPile(self.heldObject)
        elseif sourceInfo.fromPileIndex then
          GrabberHelper.removeCardsFromTableau(sourceInfo.fromPileIndex, self.heldStack)
        end
        
        -- Add all cards to target pile
        GrabberHelper.addCardsToTableau(pile, self.heldStack, Vector(lastCard.position.x, yOffset))
        
        placed = true
        break
      end
    elseif #pile == 0 and self.heldObject.value == 13 then
      -- If the pile is empty, only K can be placed
      local basePosition = Vector(150 + (i - 1) * 95, 190)
      self.heldObject.position = basePosition
      
      -- First remove cards from their original pile
      if sourceInfo.fromDrawPile then
        removeCardFromDrawPile(self.heldObject)
      elseif sourceInfo.fromSuitPile then
        removeFromSuitPile(self.heldObject)
      elseif sourceInfo.fromPileIndex then
        GrabberHelper.removeCardsFromTableau(sourceInfo.fromPileIndex, self.heldStack)
      end
      
      -- Add all cards to target pile
      GrabberHelper.addCardsToTableau(pile, self.heldStack, basePosition)
      
      placed = true
      break
    end
  end
  
  -- If no place to put, return all cards to original positions
  if not placed then
    for _, card in ipairs(self.heldStack) do
      card.position = card.originalPosition
    end
  end
  
  -- Reset state
  self:resetGrabState()
end

-- Reset grabber state
function GrabberClass:resetGrabState()
  self.heldObject.state = CARD_STATE.IDLE
  self.heldObject = nil
  self.grabPos = nil
  self.dragOffset = nil
  self.heldStack = {}
  self.ignoreNextGrab = false
end
