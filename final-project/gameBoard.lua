-- gameBoard: Handles only game board rendering
local GameLogic = require "game"
local DeckManager = require "deckManager"
local CardPositioning = require "cardPositioning"
local UIManager = require "uiManager"

GameBoard = {}

function GameBoard:new(width, height)
    local gameBoard = {}
    local metadata = {__index = GameBoard}
    setmetatable(gameBoard, metadata)
    
    gameBoard.screenWidth = width or 1400
    gameBoard.screenHeight = height or 800

    gameBoard.cardWidth = 100
    gameBoard.cardHeight = 120
    
    gameBoard.playerDeck = {}
    gameBoard.opponentDeck = {}
    gameBoard.playerHand = {}
    gameBoard.opponentHand = {}
    gameBoard.cards = {}
    
    -- Initialize 3 game locations, each with 4 slots
    gameBoard.locations = {}
    for i = 1, 3 do
        gameBoard.locations[i] = {
            playerSlots = {nil, nil, nil, nil},
            opponentSlots = {nil, nil, nil, nil}
        }
    end
    
    -- Create managers
    gameBoard.deckManager = DeckManager
    gameBoard.cardPositioning = CardPositioning
    gameBoard.uiManager = UIManager:new(gameBoard.screenWidth, gameBoard.screenHeight)
    
    gameBoard:initializeGame()
    return gameBoard
end

function GameBoard:initializeGame()
    local playerDeck, opponentDeck = self.deckManager:initializeDecks()
    self.playerDeck = playerDeck
    self.opponentDeck = opponentDeck
    
    -- Add all cards to cards array
    for _, card in ipairs(playerDeck) do
        table.insert(self.cards, card)
    end
    for _, card in ipairs(opponentDeck) do
        table.insert(self.cards, card)
    end
    
    -- Draw starting hands
    self.playerHand, self.opponentHand = self.deckManager:drawStartingHands(self.playerDeck, self.opponentDeck)
    
    -- Position hands
    self:positionHandCards()
end

-- Main draw function
function GameBoard:draw()
    love.graphics.setColor(0, 0.7, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    self:drawGameLocations()
    self:drawDiscardPile()
    self:drawDeckPile()
    self:drawManaPool()
    self:drawHands()
    self.uiManager:drawEndTurnButton()
    self.uiManager:drawSettingsButton()
end

-- Draw 3 game locations and card slots
function GameBoard:drawGameLocations()
    local dims = self.cardPositioning:getLocationDimensions(self.screenWidth, self.screenHeight)
    
    -- Draw each location
    for i = 1, 3 do
        local locationX = dims.startX + (i - 1) * (dims.locationWidth + dims.spacing)
        local locationY = dims.centerY - dims.locationHeight / 2
        
        -- Draw location background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", locationX, locationY, dims.locationWidth, dims.locationHeight, 10, 10)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", locationX, locationY, dims.locationWidth, dims.locationHeight, 10, 10)
        
        -- Draw location label
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        local labelText = "location " .. i
        local textWidth = love.graphics.getFont():getWidth(labelText)
        love.graphics.print(labelText, locationX + (dims.locationWidth - textWidth) / 2, locationY + 10)
        
        -- Draw opponent's 4 card slots (top)
        self:drawLocationSlots(locationX, locationY + 50, dims.locationWidth, true, i)
        
        -- Draw player's 4 card slots (bottom)
        self:drawLocationSlots(locationX, locationY + dims.locationHeight - 150, dims.locationWidth, false, i)
    end
end

-- Draw 4 card slots for a location
function GameBoard:drawLocationSlots(locationX, locationY, locationWidth, isOpponent, locationIndex)
    local slotSpacing = 10
    local slotsPerRow = 4
    local slotWidth = (locationWidth - (slotsPerRow + 1) * slotSpacing) / slotsPerRow
    local slotHeight = self.cardHeight + 10
    
    for slot = 1, 4 do
        local slotX = locationX + slotSpacing + (slot - 1) * (slotWidth + slotSpacing)
        local slotY = locationY
        
        -- Draw slot background
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.rectangle("fill", slotX, slotY, slotWidth, slotHeight, 5, 5)
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", slotX, slotY, slotWidth, slotHeight, 5, 5)
        
        -- Draw card in slot
        local card = nil
        if isOpponent then
            card = self.locations[locationIndex].opponentSlots[slot]
        else
            card = self.locations[locationIndex].playerSlots[slot]
        end
        
        if card then
            -- Position card at center of slot
            card.position = Vector(slotX + (slotWidth - self.cardWidth) / 2, 
                                slotY + (slotHeight - self.cardHeight) / 2)
            card:draw()
        end
    end
end

-- Draw discard pile
function GameBoard:drawDiscardPile()
    if not self.cardBackImage then
        self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
    end
    
    local cardWidth = self.cardBackImage:getWidth()
    local cardHeight = self.cardBackImage:getHeight()
    
    local playerDiscardX = self.screenWidth - cardWidth - 20
    local playerDiscardY = self.screenHeight - cardHeight - 20
    local opponentDiscardX = 20
    local opponentDiscardY = 20
    
    -- Draw semi-transparent discard pile slots
    love.graphics.setColor(1, 1, 1, 0.3)
    
    -- Player discard pile
    love.graphics.rectangle("fill", playerDiscardX, playerDiscardY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", playerDiscardX, playerDiscardY, cardWidth, cardHeight, 10, 10)
    
    -- Opponent discard pile
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", opponentDiscardX, opponentDiscardY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.rectangle("line", opponentDiscardX, opponentDiscardY, cardWidth, cardHeight, 10, 10)
end

-- Draw deck pile
function GameBoard:drawDeckPile()
    if not self.cardBackImage then
        self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
    end
    
    local cardWidth = self.cardBackImage:getWidth()
    local cardHeight = self.cardBackImage:getHeight()
    
    -- Player deck
    local playerDeckX = 20
    local playerDeckY = self.screenHeight - 160
    
    -- Opponent deck
    local opponentDeckX = self.screenWidth - 120
    local opponentDeckY = 20
    
    -- Player deck
    love.graphics.rectangle("fill", playerDeckX, playerDeckY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", playerDeckX, playerDeckY, cardWidth, cardHeight, 10, 10)
    
    -- Opponent deck
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", opponentDeckX, opponentDeckY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.rectangle("line", opponentDeckX, opponentDeckY, cardWidth, cardHeight, 10, 10)
    
    -- Draw card back images
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw player deck card backs
    for i = 3, 1, -1 do
        love.graphics.draw(self.cardBackImage, playerDeckX - (i-1)*3, playerDeckY - (i-1)*3, 0, 1, 1)
    end
    
    -- Draw opponent deck card backs
    for i = 3, 1, -1 do
        love.graphics.draw(self.cardBackImage, opponentDeckX - (i-1)*3, opponentDeckY - (i-1)*3, 0, 1, 1)
    end
end

-- Draw mana pool
function GameBoard:drawManaPool()
    if not self.manaImage then
        self.manaImage = love.graphics.newImage("asset/img/Mana.png")
        self.emptyManaImage = love.graphics.newImage("asset/img/emptyMana.png")
    end
    
    -- Get mana values from the new system
    local playerMana = GameLogic.player and GameLogic.player.mana or 1
    local opponentMana = GameLogic.ai and GameLogic.ai.mana or 1
    
    local manaWidth = self.manaImage:getWidth()
    local manaHeight = self.manaImage:getHeight()
    local spacing = 5
    
    -- Player mana position
    local playerManaStartX = self.screenWidth - 270
    local playerManaY = self.screenHeight - 160
    
    -- Opponent mana position
    local opponentManaStartX = 150
    local opponentManaY = 20
    
    -- Draw player mana (max 10)
    for i = 1, 10 do
        local col = ((i - 1) % 5) + 1  -- 5 mana per row
        local row = math.ceil(i / 5)    -- Row number
        
        local x = playerManaStartX + (col - 1) * (manaWidth + spacing)
        local y = playerManaY + (row - 1) * (manaHeight + spacing)
        
        -- Draw filled or empty mana
        local image = (i <= playerMana) and self.manaImage or self.emptyManaImage
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x, y)
    end
    
    -- Draw opponent mana (max 10)
    for i = 1, 10 do
        local col = ((i - 1) % 5) + 1
        local row = math.ceil(i / 5)
        
        local x = opponentManaStartX + (col - 1) * (manaWidth + spacing)
        local y = opponentManaY + (row - 1) * (manaHeight + spacing)
        
        -- Draw filled or empty mana
        local image = (i <= opponentMana) and self.manaImage or self.emptyManaImage
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x, y)
    end
    
    -- Draw scores
    self:drawScores(playerManaStartX, playerManaY, opponentManaStartX, opponentManaY, manaHeight)
end

-- Draw scores
function GameBoard:drawScores(playerManaX, playerManaY, opponentManaX, opponentManaY, manaHeight)
    -- Get scores from the new system
    local playerScore = GameLogic.player and GameLogic.player.score or 0
    local opponentScore = GameLogic.ai and GameLogic.ai.score or 0
    local targetScore = GameLogic.targetScore or 20
    
    -- Score text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    
    -- Player score
    local playerScoreText = "Score: " .. playerScore .. "/" .. targetScore
    local playerScoreY = playerManaY + manaHeight * 2 + 20
    love.graphics.print(playerScoreText, playerManaX, playerScoreY)
    
    -- Opponent score
    local opponentScoreText = "Score: " .. opponentScore .. "/" .. targetScore
    local opponentScoreY = opponentManaY + manaHeight * 2 + 20
    love.graphics.print(opponentScoreText, opponentManaX, opponentScoreY)
    
    -- Reset font
    love.graphics.setFont(love.graphics.getFont())
end

-- Draw hands
function GameBoard:drawHands()
    -- Draw player hand
    for _, card in ipairs(self.playerHand) do
        card:draw()
    end
    
    -- Draw opponent hand
    if not self.cardBackImage then
        self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
    end
    
    for _, card in ipairs(self.opponentHand) do
        card:draw()
    end
end

-- Position hands
function GameBoard:positionHandCards()
    self.cardPositioning:positionHandCards(self.playerHand, self.opponentHand, 
        self.screenWidth, self.screenHeight, self.cardHeight)
end

-- Check card drop zones
function GameBoard:checkCardDropZones(card)
    return self.cardPositioning:checkCardDropZones(card, self.screenWidth, self.screenHeight, 
        self.cardWidth, self.cardHeight)
end

-- Place card in slot
function GameBoard:placeCardInSlot(card, locationIndex, slotIndex, isPlayer)
    if isPlayer then
        -- Check if slot is empty
        if self.locations[locationIndex].playerSlots[slotIndex] == nil then
            self.locations[locationIndex].playerSlots[slotIndex] = card
            -- Remove card from hand
            for i, handCard in ipairs(self.playerHand) do
                if handCard == card then
                    table.remove(self.playerHand, i)
                    break
                end
            end
            -- Reposition remaining hand cards
            self:positionHandCards()
            return true
        end
    end
    return false
end

-- Check if point is in end turn button
function GameBoard:isPointInEndTurnButton(x, y)
    return self.uiManager:isPointInEndTurnButton(x, y)
end

-- Check if point is in settings button
function GameBoard:isPointInSettingsButton(x, y)
    return self.uiManager:isPointInSettingsButton(x, y)
end
