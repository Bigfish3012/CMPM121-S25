-- gameBoard: Handles only game board rendering
local GameLogic = require "game"
local DeckManager = require "deckManager"
local CardPositioning = require "cardPositioning"
local UIManager = require "uiManager"
local CardAnimation = require "cardAnimation"
local Renderer = require "renderer"
local ResourceManager = require "resourceManager"
require "card"

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
    gameBoard.playerDiscardPile = {}
    gameBoard.opponentDiscardPile = {}
    gameBoard.cards = {}
    
    -- Initialize 3 game locations, each with 4 slots
    gameBoard.locations = {}
    for i = 1, 3 do
        gameBoard.locations[i] = {
            playerSlots = {nil, nil, nil, nil},
            opponentSlots = {nil, nil, nil, nil}
        }
    end
    
    -- Initialize mana animation objects (only for player, AI uses text display)
    gameBoard.playerManaAnimations = {}
    for i = 1, 10 do
        -- Create animation objects for each player mana crystal
        gameBoard.playerManaAnimations[i] = {position = {x = 0, y = 0}}
        
        -- Initialize animation properties
        CardAnimation:initCard(gameBoard.playerManaAnimations[i])
        
        -- Set initial alpha: first crystal is active (for starting mana of 1), rest are semi-transparent
        if i == 1 then
            CardAnimation:setCurrentAlpha(gameBoard.playerManaAnimations[i], 1.0)
        else
            CardAnimation:setCurrentAlpha(gameBoard.playerManaAnimations[i], 0.3)
        end
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
    self.uiManager:drawEndTurnButton(self)
    self.uiManager:drawSettingsButton()
    
    -- Draw card descriptions on top of everything else to prevent them from being blocked
    CardClass.drawDescriptions()
end

-- Draw 3 game locations and card slots
function GameBoard:drawGameLocations()
    local dims = self.cardPositioning:getLocationDimensions(self.screenWidth, self.screenHeight)
    
    -- Draw each location using renderer
    for i = 1, 3 do
        Renderer:drawGameLocation(i, dims, self)
    end
end

-- Draw discard pile
function GameBoard:drawDiscardPile()
    Renderer:drawPileArea("playerDiscard", self.screenWidth, self.screenHeight, self)
    Renderer:drawPileArea("opponentDiscard", self.screenWidth, self.screenHeight, self)
end

-- Draw deck pile
function GameBoard:drawDeckPile()
    Renderer:drawPileArea("playerDeck", self.screenWidth, self.screenHeight, self)
    Renderer:drawPileArea("opponentDeck", self.screenWidth, self.screenHeight, self)
end

-- Draw mana pool with animations
function GameBoard:drawManaPool()
    Renderer:drawManaPool(self, GameLogic)
end

-- Draw hands
function GameBoard:drawHands()
    -- Draw player hand
    for _, card in ipairs(self.playerHand) do
        card:draw()
    end
    
    -- Draw opponent hand
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
            card.faceUp = false  -- Player cards start face down in slots
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

-- Get deck positions for animation
function GameBoard:getDeckPositions()
    local cardBackImage = ResourceManager:getCardBackImage()
    if not cardBackImage then
        return {
            player = {x = 20, y = self.screenHeight - 160},
            opponent = {x = self.screenWidth - 120, y = 20}
        }
    end
    
    local cardWidth = cardBackImage:getWidth()
    local cardHeight = cardBackImage:getHeight()
    
    local positions = Renderer:getPilePositions(self.screenWidth, self.screenHeight, cardWidth, cardHeight)
    
    -- Map the new structure to the expected structure
    return {
        player = positions.playerDeck,
        opponent = positions.opponentDeck
    }
end

-- Trigger mana gain animation for player only (AI has no visual mana crystals)
function GameBoard:animateManaGain(isPlayer, manaAmount)
    if not isPlayer then
        return -- AI has no mana crystal animations
    end
    
    local animations = self.playerManaAnimations
    
    -- Animate mana crystals that should be gaining mana
    for i = 1, math.min(manaAmount, 10) do
        CardAnimation:startManaGainAnimation(animations[i], 0.8)
    end
end

-- Trigger mana use animation for player only (AI has no visual mana crystals)
function GameBoard:animateManaUse(isPlayer, previousMana, newMana)
    if not isPlayer then
        return -- AI has no mana crystal animations
    end
    
    local animations = self.playerManaAnimations
    
    -- Animate mana crystals that were used (from previousMana down to newMana)
    for i = newMana + 1, math.min(previousMana, 10) do
        CardAnimation:startManaUseAnimation(animations[i], 0.6)
    end
end

-- Update mana display states (call this when mana changes without animation)
function GameBoard:updateManaDisplay()
    local playerMana = GameLogic.player and GameLogic.player.mana or 1
    
    -- Update player mana display only (AI has no mana crystals)
    for i = 1, 10 do
        if not CardAnimation:isManaAnimating(self.playerManaAnimations[i]) then
            if i <= playerMana then
                CardAnimation:setCurrentAlpha(self.playerManaAnimations[i], 1.0)
            else
                CardAnimation:setCurrentAlpha(self.playerManaAnimations[i], 0.3)
            end
        end
    end
end

-- Check if AI has any cards animating
function GameBoard:hasAIAnimationsInProgress()
    -- Check opponent hand cards
    for _, card in ipairs(self.opponentHand) do
        if card:isAnimating() then
            return true
        end
    end
    
    -- Check opponent cards in slots
    for locationIndex = 1, 3 do
        for slotIndex = 1, 4 do
            local card = self.locations[locationIndex].opponentSlots[slotIndex]
            if card and card:isAnimating() then
                return true
            end
        end
    end
    
    return false
end
