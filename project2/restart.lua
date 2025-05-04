-- restart.lua
-- Define restart button properties (to be initialized in init function)
local RestartModule = {
    button = nil,
    gameState = nil
}

-- Initialize the restart module with required references
function RestartModule.init(gameState)
    RestartModule.gameState = gameState
    RestartModule.button = {
        x = 50,
        y = 570,
        width = 100,
        height = 30,
        text = "Restart"
    }
end

-- Draw the restart button
function RestartModule.drawButton()
    -- Draw Restart button
    love.graphics.setColor(0.8, 0.2, 0.2) -- Red background
    love.graphics.rectangle("fill", RestartModule.button.x, RestartModule.button.y, 
                           RestartModule.button.width, RestartModule.button.height, 4, 4)
    love.graphics.setColor(1, 1, 1) -- White border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", RestartModule.button.x, RestartModule.button.y, 
                           RestartModule.button.width, RestartModule.button.height, 4, 4)
    love.graphics.setColor(1, 1, 1) -- White text
    love.graphics.printf(RestartModule.button.text, RestartModule.button.x, 
                        RestartModule.button.y + 8, RestartModule.button.width, "center")
end

-- Draw the restart confirmation dialog
function RestartModule.drawConfirmDialog()
    -- Semi-transparent black background for dialog
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Dialog box
    local dialogWidth = 300
    local dialogHeight = 150
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    
    -- Dialog background
    love.graphics.setColor(0.9, 0.9, 0.9, 1) -- Light gray
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight, 10, 10)
    love.graphics.setColor(0.3, 0.3, 0.3, 1) -- Dark gray border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight, 10, 10)
    
    -- Dialog title and text
    love.graphics.setColor(0, 0, 0, 1) -- Black text
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("Restart Game?", dialogX, dialogY + 20, dialogWidth, "center")
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("Do you want to restart the game?", dialogX + 20, dialogY + 50, dialogWidth - 40, "center")
    
    -- Yes button
    local yesButtonX = dialogX + 60
    local yesButtonY = dialogY + 90
    local buttonWidth = 70
    local buttonHeight = 30
    
    love.graphics.setColor(0.2, 0.7, 0.2, 1) -- Green
    love.graphics.rectangle("fill", yesButtonX, yesButtonY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.printf("YES", yesButtonX, yesButtonY + 6, buttonWidth, "center")
    
    -- No button
    local noButtonX = dialogX + 170
    local noButtonY = dialogY + 90
    
    love.graphics.setColor(0.7, 0.2, 0.2, 1) -- Red
    love.graphics.rectangle("fill", noButtonX, noButtonY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.printf("NO", noButtonX, noButtonY + 6, buttonWidth, "center")

    -- Reset font
    love.graphics.setFont(love.graphics.newFont(12))
end

-- Restart the game
function RestartModule.restartGame()
  -- Clear existing game state
  cardTable = {}
  deckPile = {}
  drawPile = {}
  visibleDrawCards = {}
  tableauPiles = {}
  
  -- Reset game state
  RestartModule.gameState.hasWon = false
  
  -- Create the suit piles
  local suitOrder = {"Spades", "Hearts", "Clubs", "Diamonds"}
  for i, suit in ipairs(suitOrder) do
    suitPiles[suit] = {}
  end

  -- Create a new deck and set up the game
  fullDeck = createDeck()

  -- Put the entire deck into deckPile (top left)
  for i, card in ipairs(fullDeck) do
    card.position = Vector(50, 50)
    card.canDrag = false
    card.faceUp = false
    card.state = CARD_STATE.IDLE
    
    -- Mark the first card as the deck pile indicator
    if i == 1 then
      card.isDeckPile = true
    end
    
    table.insert(deckPile, card)
    table.insert(cardTable, card) -- Add all cards to cardTable for draw and update
  end

  -- Create 7 tableau piles, each with i cards
  local startX = 150
  
  for i = 1, 7 do
    tableauPiles[i] = {}
    for j = 1, i do
      local card = table.remove(deckPile)
      card.position = Vector(startX + (i - 1) * 95, 190 + (j - 1) * 20)
      card.faceUp = (j == i) -- Only the top card is face up
      card.canDrag = (j == i)
      card.state = CARD_STATE.IDLE
      table.insert(tableauPiles[i], card)
      table.insert(cardTable, card) -- add the card to cardTable
    end
  end
  
  -- reset grabber state
  if grabber then
    grabber.heldObject = nil
    grabber.grabPos = nil
    grabber.dragOffset = nil
    grabber.heldStack = {}
    grabber.ignoreNextGrab = false
  end
end

-- Check if the restart button was clicked
function RestartModule.checkButtonClick(x, y)
    if x > RestartModule.button.x and x < RestartModule.button.x + RestartModule.button.width and
       y > RestartModule.button.y and y < RestartModule.button.y + RestartModule.button.height then
       -- Show restart confirmation dialog
       RestartModule.gameState.showRestartConfirm = true
       return true
    end
    return false
end

-- Handle clicks in the confirmation dialog
function RestartModule.handleConfirmClick(x, y, restartCallback)
    local dialogWidth = 300
    local dialogHeight = 150
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    
    -- Yes button coordinates
    local yesButtonX = dialogX + 60
    local yesButtonY = dialogY + 90
    local buttonWidth = 70
    local buttonHeight = 30
    
    -- Check if Yes was clicked
    if x > yesButtonX and x < yesButtonX + buttonWidth and
       y > yesButtonY and y < yesButtonY + buttonHeight then
        -- Restart the game
        restartCallback()
        RestartModule.gameState.showRestartConfirm = false
        return true
    end
    
    -- No button coordinates
    local noButtonX = dialogX + 170
    local noButtonY = dialogY + 90
    
    -- Check if No was clicked
    if x > noButtonX and x < noButtonX + buttonWidth and
       y > noButtonY and y < noButtonY + buttonHeight then
        -- Just close the dialog
        RestartModule.gameState.showRestartConfirm = false
        return true
    end
    
    return false
end

return RestartModule 