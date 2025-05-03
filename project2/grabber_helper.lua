-- grabber_helper.lua
-- Helper functions for grabber, to reduce the size of grabber.lua

local GrabberHelper = {}

-- Find which pile a card belongs to
function GrabberHelper.findCardSource(heldObject)
  local info = {
    fromDrawPile = false,
    fromSuitPile = false,
    fromPileIndex = nil
  }
  
  -- Check if card is from drawPile
  for _, card in ipairs(drawPile) do
    if card == heldObject then
      info.fromDrawPile = true
      break
    end
  end
  
  -- Check if card is from a suit pile
  if not info.fromDrawPile then
    for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
      local pile = suitPiles[suit]
      for _, card in ipairs(pile) do
        if card == heldObject then
          info.fromSuitPile = true
          break
        end
      end
      if info.fromSuitPile then break end
    end
  end
  
  -- Check if card is from a tableau pile
  if not info.fromDrawPile and not info.fromSuitPile then
    for i, pile in ipairs(tableauPiles) do
      for _, card in ipairs(pile) do
        if card == heldObject then
          info.fromPileIndex = i
          break
        end
      end
      if info.fromPileIndex then break end
    end
  end
  
  return info
end

-- Check if a card can be placed on a suit pile placeholder
function GrabberHelper.canPlaceOnSuitPilePlaceholder(card, suitPos, cardCenterX, cardCenterY)
  return math.abs(cardCenterX - (suitPos.x + 30)) < 40 and 
         math.abs(cardCenterY - (suitPos.y + 40)) < 50
end

-- Move card to top of render order
function GrabberHelper.moveCardToTop(card)
  for i, c in ipairs(cardTable) do
    if c == card then
      table.remove(cardTable, i)
      table.insert(cardTable, card) -- reinsert at the end (top)
      break
    end
  end
end

-- Find which tableau pile and position a card is in
function GrabberHelper.findCardInTableau(card)
  local info = {
    pileIndex = nil,
    cardIndexInPile = nil
  }
  
  for i, pile in ipairs(tableauPiles) do
    for j, c in ipairs(pile) do
      if c == card then
        info.pileIndex = i
        info.cardIndexInPile = j
        return info -- Found, return immediately
      end
    end
  end
  
  return info -- Not found in any tableau
end

-- Check if a move to tableau is valid (diff color and rank one less)
function GrabberHelper.isValidTableauMove(card, targetCard)
  -- Different color, and rank is exactly one less
  if card:getColor() == targetCard:getColor() then return false end
  return card.value + 1 == targetCard.value
end

-- Helper function to remove a stack of cards from a tableau pile
function GrabberHelper.removeCardsFromTableau(pileIndex, cardStack)
  -- if the stack is empty, return
  if #cardStack == 0 then return end
  
  local firstCard = cardStack[1]
  local pile = tableauPiles[pileIndex]
  
  -- Find the index of the first card in the stack
  local startIndex = nil
  for i, card in ipairs(pile) do
    if card == firstCard then
      startIndex = i
      break
    end
  end
  
  if startIndex then
    -- Remove all cards from startIndex to the end
    for i = #pile, startIndex, -1 do
      table.remove(pile, i)
    end
    
    -- If there are still cards and the top is face down, turn it over
    if #pile > 0 then
      local topCard = pile[#pile]
      if not topCard.faceUp then
        topCard.faceUp = true
        topCard.canDrag = true
      end
    end
  end
end

-- Turn over top card in a tableau pile
function GrabberHelper.turnOverTopCard(pileIndex)
  local pile = tableauPiles[pileIndex]
  if #pile > 0 then
    local topCard = pile[#pile]
    if not topCard.faceUp then
      topCard.faceUp = true
      topCard.canDrag = true
    end
  end
end

-- Add cards to a tableau pile with proper positioning
function GrabberHelper.addCardsToTableau(pile, heldStack, basePosition)
  for i, card in ipairs(heldStack) do
    table.insert(pile, card)
    -- Set position for each card in the stack to ensure proper offset stacking
    if i > 1 then
      card.position = Vector(basePosition.x, basePosition.y + (i-1) * 20)
    end
  end
end

return GrabberHelper 