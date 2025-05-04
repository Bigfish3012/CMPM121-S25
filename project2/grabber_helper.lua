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
      return info
    end
  end
  
  -- Check if card is from a suit pile
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    for _, card in ipairs(suitPiles[suit]) do
      if card == heldObject then
        info.fromSuitPile = true
        return info
      end
    end
  end
  
  -- Check if card is from a tableau pile
  for i, pile in ipairs(tableauPiles) do
    for _, card in ipairs(pile) do
      if card == heldObject then
        info.fromPileIndex = i
        return info
      end
    end
  end
  
  return info
end

-- Check if a card can be placed on a suit pile placeholder
function GrabberHelper.canPlaceOnSuitPilePlaceholder(card, suitPos, cardCenterX, cardCenterY)
  local placeholderCenterX = suitPos.x + 30
  local placeholderCenterY = suitPos.y + 40
  local horizontalTolerance = 40
  local verticalTolerance = 50
  
  return math.abs(cardCenterX - placeholderCenterX) < horizontalTolerance and 
         math.abs(cardCenterY - placeholderCenterY) < verticalTolerance
end

-- Move card to top of render order
function GrabberHelper.moveCardToTop(card)
  for i, c in ipairs(cardTable) do
    if c == card then
      table.remove(cardTable, i)
      table.insert(cardTable, card)
      return
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
        return info
      end
    end
  end
  
  return info
end

-- Check if a move to tableau is valid (diff color and rank one less)
function GrabberHelper.isValidTableauMove(card, targetCard)
  -- Different color, and rank is exactly one less
  if card:getColor() == targetCard:getColor() then return false end
  return card.value + 1 == targetCard.value
end

-- Helper function to remove a stack of cards from a tableau pile
function GrabberHelper.removeCardsFromTableau(pileIndex, cardStack)
  if #cardStack == 0 then return end
  local pile = tableauPiles[pileIndex]
  local firstCard = cardStack[1]
  local cardInfo = GrabberHelper.findCardInTableau(firstCard)
  if cardInfo.cardIndexInPile then
      for i = 1, #cardStack do
          table.remove(pile, cardInfo.cardIndexInPile)
      end
      GrabberHelper.turnOverTopCard(pileIndex)
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
      topCard.state = CARD_STATE.IDLE
      
      GrabberHelper.moveCardToTop(topCard)
    end
  end
end

-- Add cards to a tableau pile with proper positioning
function GrabberHelper.addCardsToTableau(pile, heldStack, basePosition)
  for i, card in ipairs(heldStack) do
    table.insert(pile, card)
    
    -- set the position of the card, ensure proper stacking
    if i == 1 then
      card.position = basePosition
    else
      card.position = Vector(basePosition.x, basePosition.y + (i-1) * 20)
    end
    
    -- ensure all cards are at the top of the rendering order
    GrabberHelper.moveCardToTop(card)
    
    -- ensure all cards state is correct
    card.state = CARD_STATE.IDLE
  end
end

-- Check if a card can be added to a suit pile
function GrabberHelper.canAddToSuitPile(card, suit)
  local pile = suitPiles[suit]
  
  -- Card must match the suit
  if card.suit ~= suit then
    return false
  end
  
  -- If pile is empty, only A can be placed
  if #pile == 0 then
    return card.value == 1
  end
  
  -- Otherwise, card must be one rank higher than the top card
  local topCard = pile[#pile]
  return card.value == topCard.value + 1
end

-- Remove a card from a suit pile
function GrabberHelper.removeFromSuitPile(card)
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pile = suitPiles[suit]
    for i = #pile, 1, -1 do
      if pile[i] == card then
        table.remove(pile, i)
        Helper.updateSuitPilesDraggableCards(suitPiles)
        return
      end
    end
  end
end

-- Add a card to a suit pile
function GrabberHelper.addToSuitPile(card, suit)
  -- Add card to suit pile
  table.insert(suitPiles[suit], card)
  
  -- Update card position
  local suitIndex = 0
  for i, s in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    if s == suit then
      suitIndex = i
      break
    end
  end
  
  card.position = suitPilePositions[suitIndex]
  
  -- Ensure card is face up
  card.faceUp = true
  
  -- Move card to top of render order
  GrabberHelper.moveCardToTop(card)
  
  -- Update draggable state
  Helper.updateSuitPilesDraggableCards(suitPiles)
end

-- Remove specified card from drawPile
function GrabberHelper.removeCardFromDrawPile(card)
  -- Remove from visibleDrawCards
  for i = #visibleDrawCards, 1, -1 do
    if visibleDrawCards[i] == card then
      table.remove(visibleDrawCards, i)
      break
    end
  end
  
  -- Remove from drawPile
  for i = #drawPile, 1, -1 do
    if drawPile[i] == card then
      table.remove(drawPile, i)
      break
    end
  end
  
  -- Update positions using Helper function
  if #visibleDrawCards > 0 then
    local visibleCount = math.min(3, #visibleDrawCards)
    for i = 1, #visibleDrawCards do
      local currentCard = visibleDrawCards[i]
      Helper.positionCardInDrawPile(currentCard, i, #visibleDrawCards, visibleCount, drawPilePositions)
    end
  end
end

return GrabberHelper 