--grabber

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
  for _, card in ipairs(cardTable) do
    if card.state == CARD_STATE.MOUSE_OVER and card.canDrag then
      self.heldObject = card
      card.state = CARD_STATE.GRABBED
      card.originalPosition = Vector(card.position.x, card.position.y) -- store original
      self.grabPos = self.currentMousePos -- Only set if successfully caught
      print("GRAB - ", card)
      -- move the card to the top 
      for i, c in ipairs(cardTable) do
        if c == card then
          table.remove(cardTable, i)
          table.insert(cardTable, card) -- reinsert to the latest
          break
        end
      end
      return
    end
  end
end

function GrabberClass:release()
  --print("RELEASE - ")
  -- NEW: some more logic stubs here
  if self.heldObject == nil then -- we have nothing to release
    return
  end
  
  -- Check if card is from drawPile
  local fromDrawPile = false
  for _, card in ipairs(drawPile) do
    if card == self.heldObject then
      fromDrawPile = true
      break
    end
  end
  
  -- Check if card is from a suit pile
  local fromSuitPile = false
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pile = suitPiles[suit]
    for _, card in ipairs(pile) do
      if card == self.heldObject then
        fromSuitPile = true
        break
      end
    end
    if fromSuitPile then break end
  end
  
  -- Find out which tableauPile heldObject was originally in (in order to turn over the cards later)
  local fromPileIndex = nil
  for i, pile in ipairs(tableauPiles) do
    for j, card in ipairs(pile) do
      if card == self.heldObject then
        fromPileIndex = i
        break
      end
    end
    if fromPileIndex then break end
  end
  
  -- First try to place card on a suit pile
  local placedOnSuitPile = false
  for suitIndex, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local suitPos = suitPilePositions[suitIndex]
    local cardCenterX = self.heldObject.position.x + self.heldObject.size.x / 2
    local cardCenterY = self.heldObject.position.y + self.heldObject.size.y / 2
    
    -- Check if card is over this suit pile placeholder
    if math.abs(cardCenterX - (suitPos.x + 30)) < 40 and 
       math.abs(cardCenterY - (suitPos.y + 40)) < 50 then
      
      -- Check if card can be placed in this suit pile
      if canAddToSuitPile(self.heldObject, suit) then
        -- Remove from source pile if needed
        if fromDrawPile then
          removeCardFromDrawPile(self.heldObject)
        elseif fromPileIndex then
          table.remove(tableauPiles[fromPileIndex], #tableauPiles[fromPileIndex])
        elseif fromSuitPile then
          removeFromSuitPile(self.heldObject)
        end
        
        -- Add to suit pile
        addToSuitPile(self.heldObject, suit)
        placedOnSuitPile = true
        break
      end
    end
  end
  
  -- If card was placed on a suit pile, we're done
  if placedOnSuitPile then
    -- If card came from tableau pile, turn over next card
    if fromPileIndex then
      local fromPile = tableauPiles[fromPileIndex]
      if #fromPile > 0 then
        local topCard = fromPile[#fromPile]
        if not topCard.faceUp then
          topCard.faceUp = true
          topCard.canDrag = true
        end
      end
    end
    
    self.heldObject.state = CARD_STATE.IDLE
    self.heldObject = nil
    self.grabPos = nil
    return
  end
  
  -- Try to find an available tableauPiles to place the cards
  local placed = false
  for i, pile in ipairs(tableauPiles) do
    local lastCard = pile[#pile]
    if lastCard and lastCard.faceUp then
      local valid = self:isValidTableauMove(self.heldObject, lastCard)
      if valid then
        -- Place it at the bottom of this pile
        self.heldObject.position = Vector(lastCard.position.x, lastCard.position.y + 20)
        table.insert(pile, self.heldObject)
        placed = true
        break
      end
    elseif #pile == 0 and self.heldObject.rank == "K" then
      -- If the pile is empty, only K can be placed
      self.heldObject.position = Vector(130 + (i - 1) * 70, 150)
      table.insert(pile, self.heldObject)
      placed = true
      break
    end
  end
  
  -- if no place would put, then return to the original position
  if not placed then
    self.heldObject.position = self.heldObject.originalPosition
  else
    -- If card is from drawPile, remove it after successful placement
    if fromDrawPile then
      removeCardFromDrawPile(self.heldObject)
    -- If card is from a suit pile, remove it
    elseif fromSuitPile then
      removeFromSuitPile(self.heldObject)
    -- If the move is successful, try to remove it from the original pile and turn over the card (but only if it came from the tableau pile)
    elseif fromPileIndex then
      local fromPile = tableauPiles[fromPileIndex]
      for j = #fromPile, 1, -1 do
        if fromPile[j] == self.heldObject then
          table.remove(fromPile, j)
          -- If there are still cards and the top is the back, turn it over
          local topCard = fromPile[#fromPile]
          if topCard and not topCard.faceUp then
            topCard.faceUp = true
            topCard.canDrag = true
          end
          break
        end
      end
    end
  end

  self.heldObject.state = CARD_STATE.IDLE -- it's no longer grabbed
  self.heldObject = nil
  self.grabPos = nil
end

function GrabberClass:checkValidDrop(card)
  local x, y = card.position.x, card.position.y
  return x > 50 and x < 900 and y > 50 and y < 600
end

function GrabberClass:isValidTableauMove(movingCard, targetCard)
  -- Different color
  if movingCard:getColor() == targetCard:getColor() then
    return false
  end

  -- Compare number's value
  local rankValue = CardClass.rankToValue(movingCard.rank)
  local targetValue = CardClass.rankToValue(targetCard.rank)

  return rankValue == targetValue - 1
end
