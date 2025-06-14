-- renderer.lua: Centralized game rendering logic
local ResourceManager = require "resourceManager"

local Renderer = {}

-- Helper function to draw card with temporary state changes
local function drawCardTemporarily(card, x, y, faceUp)
    local originalPos = card.position
    local originalFaceUp = card.faceUp
    
    card.position = Vector(x, y)
    card.faceUp = faceUp
    card:draw()
    
    -- Restore original values
    card.position = originalPos
    card.faceUp = originalFaceUp
end

-- Helper function to draw centered text
local function drawCenteredText(text, x, y, width, height, font)
    love.graphics.setFont(font)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, x + (width - textWidth) / 2, y + (height - textHeight) / 2)
end

-- Helper function to draw discard count
local function drawDiscardCount(discardPile, x, y, width, height)
    if #discardPile <= 1 then return end
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(ResourceManager:getGameFont(14))
    local countText = "(" .. #discardPile .. ")"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(countText)
    love.graphics.print(countText, x + width - textWidth - 5, y + height - 20)
end

-- Helper function to draw empty discard placeholder
local function drawEmptyDiscardPlaceholder(x, y, width, height)
    -- Draw semi-transparent background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.6)
    love.graphics.rectangle("fill", x, y, width, height, 8, 8)
    
    -- Draw dashed border
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.setLineStyle("rough")
    love.graphics.rectangle("line", x, y, width, height, 8, 8)
    love.graphics.setLineStyle("smooth")
    
    -- Draw "DISCARD" text
    love.graphics.setColor(1, 1, 1, 0.7)
    drawCenteredText("DISCARD", x, y, width, height, ResourceManager:getGameFont(12))
end

-- Helper function to get appropriate discard pile
local function getDiscardPile(gameBoard, pileType)
    if pileType == "playerDiscard" then
        return gameBoard and gameBoard.playerDiscardPile or {}
    elseif pileType == "opponentDiscard" then
        return gameBoard and gameBoard.opponentDiscardPile or {}
    end
    return {}
end

-- Helper function to draw slot card
local function drawSlotCard(card, slotX, slotY, slotWidth, slotHeight, gameBoard)
    if not card then return end
    
    local cardOffsetX = (slotWidth - gameBoard.cardWidth) / 2 + 5
    local cardOffsetY = (slotHeight - gameBoard.cardHeight) / 2
    card.position = Vector(slotX + cardOffsetX, slotY + cardOffsetY)
    card:draw()
end

-- Helper function to calculate mana crystal position
local function calculateManaPosition(i, startX, startY, manaWidth, manaHeight, spacing)
    local col = ((i - 1) % 5) + 1
    local row = math.ceil(i / 5)
    local x = startX + (col - 1) * (manaWidth + spacing)
    local y = startY + (row - 1) * (manaHeight + spacing)
    return x, y
end

-- Draw card area (generic function)
function Renderer:drawCardArea(x, y, width, height, fillColor, borderColor, cornerRadius)
    fillColor = fillColor or {1, 1, 1, 0.3}
    borderColor = borderColor or {0.9, 0.9, 0.9, 0.5}
    cornerRadius = cornerRadius or 10
    
    -- Draw fill
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)
    
    -- Draw border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)
end

-- Draw card back stacking effect
function Renderer:drawCardStack(x, y, layers)
    layers = layers or 3
    local cardBackImage = ResourceManager:getCardBackImage()
    if not cardBackImage then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    for i = layers, 1, -1 do
        love.graphics.draw(cardBackImage, x - (i-1)*3, y - (i-1)*3, 0, 1, 1)
    end
end

-- Draw pile area (player/opponent)
function Renderer:drawPileArea(pileType, screenWidth, screenHeight, gameBoard)
    local cardBackImage = ResourceManager:getCardBackImage()
    if not cardBackImage then return end
    
    local cardWidth = cardBackImage:getWidth()
    local cardHeight = cardBackImage:getHeight()
    
    -- Calculate position
    local positions = self:getPilePositions(screenWidth, screenHeight, cardWidth, cardHeight)
    local pos = positions[pileType]
    
    if not pos then return end
    
    -- Check if this is a discard pile
    if pileType == "playerDiscard" or pileType == "opponentDiscard" then
        self:drawDiscardPileHolder(pos.x, pos.y, cardWidth, cardHeight, gameBoard, pileType)
    else
        -- Draw deck pile as card stack
        self:drawCardArea(pos.x, pos.y, cardWidth, cardHeight)
        self:drawCardStack(pos.x, pos.y)
    end
end

-- Draw discard pile holder (semi-transparent container)
function Renderer:drawDiscardPileHolder(x, y, width, height, gameBoard, pileType)
    local discardPile = getDiscardPile(gameBoard, pileType)
    
    if #discardPile > 0 then
        -- Draw the top card
        local topCard = discardPile[#discardPile]
        drawCardTemporarily(topCard, x, y, true)
        drawDiscardCount(discardPile, x, y, width, height)
    else
        -- Draw empty placeholder
        drawEmptyDiscardPlaceholder(x, y, width, height)
    end
end

-- Get pile positions
function Renderer:getPilePositions(screenWidth, screenHeight, cardWidth, cardHeight)
    return {
        playerDeck = {x = 20, y = screenHeight - 160},
        opponentDeck = {x = screenWidth - 120, y = 20},
        playerDiscard = {x = screenWidth - cardWidth - 20, y = screenHeight - cardHeight - 20},
        opponentDiscard = {x = 20, y = 20}
    }
end

-- Draw game location area
function Renderer:drawGameLocation(locationIndex, dims, gameBoard)
    local locationX = dims.startX + (locationIndex - 1) * (dims.locationWidth + dims.spacing)
    local locationY = dims.centerY - dims.locationHeight / 2
    
    -- Draw location background
    self:drawCardArea(locationX, locationY, dims.locationWidth, dims.locationHeight, 
                     {0.2, 0.2, 0.2, 0.3}, {0.8, 0.8, 0.8, 0.8})
    
    -- Draw location label
    love.graphics.setColor(1, 1, 1, 1)
    local labelText = "location " .. locationIndex
    drawCenteredText(labelText, locationX, locationY + 10, dims.locationWidth, 0, ResourceManager:getGameFont(16))
    
    -- Draw card slots
    self:drawLocationSlots(locationX, locationY + 50, dims.locationWidth, true, locationIndex, gameBoard)
    self:drawLocationSlots(locationX, locationY + dims.locationHeight - 150, dims.locationWidth, false, locationIndex, gameBoard)
end

-- Draw location slots
function Renderer:drawLocationSlots(locationX, locationY, locationWidth, isOpponent, locationIndex, gameBoard)
    local slotSpacing = 10
    local slotsPerRow = 4
    local slotWidth = (locationWidth - (slotsPerRow + 1) * slotSpacing) / slotsPerRow
    local slotHeight = gameBoard.cardHeight + 10
    
    for slot = 1, 4 do
        local slotX = locationX + slotSpacing + (slot - 1) * (slotWidth + slotSpacing)
        local slotY = locationY
        
        -- Draw slot background
        self:drawCardArea(slotX, slotY, slotWidth, slotHeight, 
                         {1, 1, 1, 0.4}, {0.7, 0.7, 0.7, 0.8}, 5)
        
        -- Get and draw card in the slot
        local slots = isOpponent and gameBoard.locations[locationIndex].opponentSlots 
                                  or gameBoard.locations[locationIndex].playerSlots
        local card = slots[slot]
        
        drawSlotCard(card, slotX, slotY, slotWidth, slotHeight, gameBoard)
    end
end

-- Draw mana text and scores
function Renderer:drawManaTextAndScores(playerManaX, playerManaY, opponentManaX, opponentManaY, 
                                       manaHeight, playerMana, opponentMana, playerScore, opponentScore, targetScore)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Player info
    love.graphics.setFont(ResourceManager:getGameFont(16))
    local playerManaText = "Mana  : " .. playerMana .. "/10"
    local playerManaTextY = playerManaY + manaHeight * 2 + 20
    love.graphics.print(playerManaText, playerManaX, playerManaTextY)
    
    local playerScoreText = "SCORE: " .. playerScore .. "/" .. targetScore
    love.graphics.print(playerScoreText, playerManaX, playerManaTextY + 25)
    
    -- Opponent info
    love.graphics.setFont(ResourceManager:getGameFont(20))
    local opponentManaText = "Mana  : " .. opponentMana .. "/10"
    local opponentManaTextY = opponentManaY + 20
    love.graphics.print(opponentManaText, opponentManaX, opponentManaTextY)
    
    local opponentScoreText = "SCORE: " .. opponentScore .. "/" .. targetScore
    love.graphics.print(opponentScoreText, opponentManaX, opponentManaTextY + 25)
end

-- Draw mana crystals
function Renderer:drawManaPool(gameBoard, GameLogic)
    local manaImages = ResourceManager:getManaImages()
    if not manaImages.mana or not manaImages.emptyMana then return end
    
    local playerMana = GameLogic.player and GameLogic.player.mana or 1
    local opponentMana = GameLogic.ai and GameLogic.ai.mana or 1
    local playerScore = GameLogic.player and GameLogic.player.score or 0
    local opponentScore = GameLogic.ai and GameLogic.ai.score or 0
    local targetScore = GameLogic.targetScore or 20
    
    local manaWidth = manaImages.mana:getWidth()
    local manaHeight = manaImages.mana:getHeight()
    local spacing = 5
    
    -- Player mana position
    local playerManaStartX = gameBoard.screenWidth - 270
    local playerManaY = gameBoard.screenHeight - 160
    
    -- Opponent mana position
    local opponentManaStartX = 150
    local opponentManaY = 20
    
    -- Draw player mana crystals (max 10)
    for i = 1, 10 do
        local x, y = calculateManaPosition(i, playerManaStartX, playerManaY, manaWidth, manaHeight, spacing)
        
        -- Update animation object position
        local manaAnim = gameBoard.playerManaAnimations[i]
        if manaAnim then
            manaAnim.position.x = x
            manaAnim.position.y = y
            
            local CardAnimation = require "cardAnimation"
            CardAnimation:updateAnimation(manaAnim)
            
            local alpha = CardAnimation:getCurrentAlpha(manaAnim)
            local image = (i <= playerMana) and manaImages.mana or manaImages.emptyMana
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(image, x, y)
        end
    end
    
    -- Draw mana text and scores
    self:drawManaTextAndScores(playerManaStartX, playerManaY, opponentManaStartX, opponentManaY, 
                              manaHeight, playerMana, opponentMana, playerScore, opponentScore, targetScore)
end

return Renderer 