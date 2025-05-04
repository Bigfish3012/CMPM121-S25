-- helper.lua, helper functions for the game 

local Helper = {}

-- check if player has won the game
function Helper.checkForWin(gameState, cardTable, suitPiles)
  if gameState.hasWon then return end
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
      if #suitPiles[suit] < 13 then
          return
      end
  end
  gameState.hasWon = true
  print("Game Won!")
end

-- draw game win screen
function Helper.drawWinScreen(gameState)
  -- Store original font to restore it later
  local originalFont = love.graphics.getFont()
  
  -- Semi-transparent black background
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  
  -- Pulsing effect
  local scale = 1.0
  
  -- Large text "YOU WIN!!!"
  love.graphics.setColor(1, 1, 0) -- Yellow
  love.graphics.push()
  love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
  love.graphics.scale(scale, scale)
  
  -- Use large font
  local font = love.graphics.newFont(72)
  love.graphics.setFont(font)
  love.graphics.printf("YOU WIN!!!", -300, -36, 600, "center")
  
  -- Restore default settings
  love.graphics.pop()
  
  -- Restore original font
  love.graphics.setFont(originalFont)
end

-- update draw pile draggable cards
function Helper.updateDrawPileDraggableCards(drawPile, visibleDrawCards)
  -- Reset all cards in drawPile to not draggable
  for _, card in ipairs(drawPile) do
    card.canDrag = false
  end
  
  -- Only the rightmost visible card can be dragged (top card)
  if #visibleDrawCards > 0 then
    -- Maximum of 3 visible cards, the last one is draggable
    visibleDrawCards[#visibleDrawCards].canDrag = true
  end
end

-- update suit piles draggable cards
function Helper.updateSuitPilesDraggableCards(suitPiles)
  -- For each suit pile, only the top card can be dragged
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pile = suitPiles[suit]
    for i, card in ipairs(pile) do
      card.canDrag = (i == #pile)  -- Only the top card can be dragged
    end
  end
end

-- Position a card in the draw pile based on its index
function Helper.positionCardInDrawPile(card, index, totalCards, visibleCount, drawPilePositions)
  -- Last cards are placed at the visible positions
  if index > totalCards - visibleCount then
    local posIndex = visibleCount - (totalCards - index)
    card.position = drawPilePositions[posIndex]
    card.canDrag = (index == totalCards) -- Only the last card is draggable
  else
    -- Earlier cards are stacked at position 1
    card.position = drawPilePositions[1]
    card.canDrag = false
  end
  
  -- Ensure correct state
  if card.state ~= CARD_STATE.GRABBED then
    card.state = CARD_STATE.IDLE
  end
end

-- Reorganize visible cards in the draw pile
function Helper.reorganizeVisibleDrawCards(drawPile, visibleDrawCards, drawPilePositions)
  -- If there are no visible cards, no need to process
  if #visibleDrawCards == 0 then
    return
  end
  
  -- Calculate number of cards to show
  local cardsToShow = math.min(3, #visibleDrawCards)
  
  -- Set correct position and draggable state for each card
  for i = 1, #visibleDrawCards do
    local card = visibleDrawCards[i]
    Helper.positionCardInDrawPile(card, i, #visibleDrawCards, cardsToShow, drawPilePositions)
    -- Move card to top of render order
    GrabberHelper.moveCardToTop(card)
  end
end

-- Draw suit pile placeholders
function Helper.drawSuitPilePlaceholders(suitPilePositions, suitImages, cardDimensions)
  -- Use cached card dimensions
  local cardWidth, cardHeight = cardDimensions.width, cardDimensions.height
  
  -- Draw placeholders for each suit pile
  for i, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pos = suitPilePositions[i]
    
    -- Semi-transparent white background
    love.graphics.setColor(1, 1, 1, 0.4)  -- Semi-transparent white
    love.graphics.rectangle("fill", pos.x, pos.y, cardWidth, cardHeight, 6, 6)
    
    -- Border
    if suit == "Hearts" or suit == "Diamonds" then
      love.graphics.setColor(1, 0, 0, 0.7)  -- Red border for red suits
    else
      love.graphics.setColor(0, 0, 0, 0.7)  -- Black border for black suits
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", pos.x, pos.y, cardWidth, cardHeight, 6, 6)
    
    -- Draw suit image instead of text label
    love.graphics.setColor(1, 1, 1, 1)
    local image = suitImages[suit]
    local scale = 3
    local imgWidth, imgHeight = image:getDimensions()
    love.graphics.draw(
      image, 
      pos.x + cardWidth/2 - (imgWidth*scale)/2, 
      pos.y + cardHeight/2 - (imgHeight*scale)/2,
      0,  -- rotation
      scale, scale  -- scale x, y
    )
  end
end

-- Handle click on deck pile
function Helper.handleDeckPileClick(deckPile, drawPile, visibleDrawCards, drawPilePositions, GrabberHelper)
  if #deckPile > 0 then
    -- Calculate number of new cards to show
    local cardsToShow = math.min(3, #deckPile)
    
    -- Move all currently visible cards to position 1 and set them non-draggable
    for _, card in ipairs(visibleDrawCards) do
      card.position = drawPilePositions[1]
      card.canDrag = false
      card.state = CARD_STATE.IDLE
    end
    
    -- Draw new cards
    for i = 1, cardsToShow do
      local card = table.remove(deckPile)
      card.faceUp = true
      card.state = CARD_STATE.IDLE
      
      -- Ensure new cards are on top of render order
      GrabberHelper.moveCardToTop(card)
      
      table.insert(drawPile, card)
      table.insert(visibleDrawCards, card)
    end
    
    -- Update positions and draggable state using Helper function
    local visibleCount = math.min(3, #visibleDrawCards)
    for i = 1, #visibleDrawCards do
      local card = visibleDrawCards[i]
      Helper.positionCardInDrawPile(card, i, #visibleDrawCards, visibleCount, drawPilePositions)
    end
    
  elseif #drawPile > 0 then
    -- No cards in deck pile, recycle draw pile
    visibleDrawCards = {}
    while #drawPile > 0 do
      local card = table.remove(drawPile)
      card.faceUp = false
      card.canDrag = false
      card.state = CARD_STATE.IDLE
      card.position = Vector(50, 50) -- Return to deck pile position
      table.insert(deckPile, card)
    end
  end
  
  return deckPile, drawPile, visibleDrawCards
end

return Helper
