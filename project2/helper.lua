-- helper.lua, helper functions for the game 

local Helper = {}

-- check if player has won the game
function Helper.checkForWin(gameState, cardTable, suitPiles)
  -- If already won, stop checking
  if gameState.hasWon then return end
  
  -- Check condition 1: All cards are face up
  local allFaceUp = true
  for _, card in ipairs(cardTable) do
    if not card.faceUp then
      allFaceUp = false
      break
    end
  end
  
  -- Check condition 2: All suit piles are full (13 cards each)
  local allSuitsFull = true
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    if #suitPiles[suit] < 13 then
      allSuitsFull = false
      break
    end
  end
  
  -- If either condition is met, player wins
  if allFaceUp or allSuitsFull then
    gameState.hasWon = true
    print("Game Won!")
  end
end

-- draw game win screen
function Helper.drawWinScreen(gameState)
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
  love.graphics.setFont(love.graphics.newFont(12)) -- Reset to default font
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

-- Reorganize visible cards in the draw pile
function Helper.reorganizeVisibleDrawCards(drawPile, visibleDrawCards, drawPilePositions)
  -- If no visible cards, no need to process
  if #visibleDrawCards == 0 then
    return
  end
  
  -- If there are fewer than 3 visible cards, but more in the draw pile
  -- We need to pull cards from the stacked pile to fill the display
  if #visibleDrawCards < 3 and #drawPile > #visibleDrawCards then
    -- Calculate how many stacked cards are available
    local stackedCards = #drawPile - #visibleDrawCards
    
    -- Calculate how many cards needed to reach 3 visible cards
    local cardsNeeded = math.min(3 - #visibleDrawCards, stackedCards)
    
    -- Take the required number of cards from the stacked pile
    for i = 1, cardsNeeded do
      -- Find the first card in the draw pile that isn't already visible
      local cardToShow = nil
      for _, card in ipairs(drawPile) do
        local isVisible = false
        for _, visibleCard in ipairs(visibleDrawCards) do
          if card == visibleCard then
            isVisible = true
            break
          end
        end
        
        if not isVisible then
          cardToShow = card
          cardToShow.faceUp = true
          table.insert(visibleDrawCards, 1, cardToShow)
          break
        end
      end
    end
  end
  
  -- Update positions for all visible cards
  for i = 1, #visibleDrawCards do
    -- Ensure a maximum of 3 visible cards
    local positionIndex = math.min(i, 3)
    if i > #visibleDrawCards - 3 then
      -- The last 3 cards should be positioned at the 3 locations
      positionIndex = 3 - (#visibleDrawCards - i)
      visibleDrawCards[i].position = drawPilePositions[positionIndex]
    else
      -- Other cards are stacked at the first position
      visibleDrawCards[i].position = drawPilePositions[1]
      visibleDrawCards[i].canDrag = false
    end
  end
  
  -- Update draggable status
  Helper.updateDrawPileDraggableCards(drawPile, visibleDrawCards)
end

return Helper
