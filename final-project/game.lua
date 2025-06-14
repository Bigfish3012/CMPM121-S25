-- game file: for the game logic

require "card"
local CardEffects = require "cards_eff"
local Player = require "player"
local AI = require "ai"
local TurnManager = require "turns"
local GameStateManager = require "gameStateManager"

GameLogic = {}

-- Game state tracking
GameLogic.currentPlayer = "player"
GameLogic.turnNumber = 1 
GameLogic.gameBoard = nil
GameLogic.onGameEnd = nil
-- Player and AI instances
GameLogic.player = nil
GameLogic.ai = nil

-- Turn manager
GameLogic.turnManager = TurnManager

-- Game settings
GameLogic.targetScore = 20
GameLogic.gamePhase = "staging"

-- Track card placement order for revealing stage
GameLogic.placedCardList = {}
GameLogic.allCardRevealed = true

-- Initialize game logic with reference to game board
function GameLogic.init(gameBoard)
    GameLogic.gameBoard = gameBoard
    CardEffects.init(GameLogic)
    
    -- Create player and AI instances
    GameLogic.player = Player:new()
    GameLogic.ai = AI:new()
    
    -- Initialize turn manager
    GameLogic.turnManager:init()
    
    -- Reset game state
    GameLogic.turnNumber = 1
    GameLogic.gamePhase = "staging"
    GameLogic.placedCardList = {}
    GameLogic.currentRevealIndex = nil
    GameLogic.nextRevealTimer = nil
    GameLogic.allCardRevealed = true
    
    -- Start first turn animation
    GameLogic.turnManager:startPlayerTurn()
end

-- Helper function to find card in collections
local function findCardInCollection(card, collection)
    for i, item in ipairs(collection) do
        if item == card then
            return i
        end
    end
    return nil
end

-- Helper function to remove card from collection
local function removeCardFromCollection(card, collection)
    local index = findCardInCollection(card, collection)
    if index then
        table.remove(collection, index)
        return true
    end
    return false
end

-- Helper function to remove card from slots
local function removeCardFromSlots(card, gameBoard)
    for locationIndex = 1, 3 do
        for slotIndex = 1, 4 do
            local playerSlot = gameBoard.locations[locationIndex].playerSlots
            local opponentSlot = gameBoard.locations[locationIndex].opponentSlots
            
            if playerSlot[slotIndex] == card then
                playerSlot[slotIndex] = nil
                return gameBoard.playerDiscardPile
            elseif opponentSlot[slotIndex] == card then
                opponentSlot[slotIndex] = nil
                return gameBoard.opponentDiscardPile
            end
        end
    end
    return nil
end



-- Helper function to stop card animations
local function stopCardAnimations(card)
    if not card then return end
    
    -- Stop position animations
    card.isAnimating = false
    card.animationStartPos = nil
    card.animationTargetPos = nil
    card.animationStartTime = nil
    card.animationCompleteCallback = nil
    
    -- Stop mana animations
    card.isManaAnimating = false
    card.manaAnimationStartAlpha = nil
    card.manaAnimationTargetAlpha = nil
    card.manaAnimationStartTime = nil
    card.manaAnimationCallback = nil
end



-- Check if a card belongs to the player
function GameLogic:isPlayerCard(card, gameBoard)
    -- Check player hand
    if findCardInCollection(card, gameBoard.playerHand) then
        return true
    end
    
    -- Check player slots in all locations
    for locationIndex = 1, 3 do
        for slotIndex = 1, 4 do
            local playerCard = gameBoard.locations[locationIndex].playerSlots[slotIndex]
            if playerCard == card then
                return true
            end
        end
    end
    
    return false
end

-- Discard a card from the game
function GameLogic:discardCard(card, gameBoard)
    -- Check for Hydra discard effect before removing the card
    CardEffects:handleHydraDiscard(card, gameBoard)
    
    local isPlayerCard = self:isPlayerCard(card, gameBoard)
    
    -- Try to remove from hands first
    if removeCardFromCollection(card, gameBoard.playerHand) then
        table.insert(gameBoard.playerDiscardPile, card)
    elseif removeCardFromCollection(card, gameBoard.opponentHand) then
        table.insert(gameBoard.opponentDiscardPile, card)
    else
        -- Try to remove from slots
        local discardPile = removeCardFromSlots(card, gameBoard)
        if discardPile then
            table.insert(discardPile, card)
        else
            -- Fallback: add to appropriate discard pile based on ownership
            local targetPile = isPlayerCard and gameBoard.playerDiscardPile or gameBoard.opponentDiscardPile
            table.insert(targetPile, card)
        end
    end
    
    -- Remove from main cards array
    removeCardFromCollection(card, gameBoard.cards)
end

-- Trigger card effect when a card is revealed (played)
function GameLogic:triggerCardEffect(card, gameBoard)
    if not card or not card.name then
        return false
    end
    
    -- Use the CardEffects system
    return CardEffects:triggerEffect(card.name, card, gameBoard)
end

-- Trigger card effect with location information
function GameLogic:triggerCardEffectWithLocation(card, gameBoard, locationIndex, slotIndex)
    if not card or not card.name then
        return false
    end
    
    -- Use the CardEffects system with location info
    return CardEffects:triggerEffectWithLocation(card.name, card, gameBoard, locationIndex, slotIndex)
end

-- Function to be called when a card is played/placed
function GameLogic:onCardPlayed(card, gameBoard)
    -- Card should remain face down when played - only flip during reveal phase
    card.faceUp = false
    
    -- Add card to placed card list for revealing stage
    table.insert(GameLogic.placedCardList, card)
    
    gameBoard:positionHandCards()
end

-- Check if player can afford to play a card
function GameLogic:canPlayCard(card, isPlayer)
    local player = isPlayer and self.player or self.ai
    return player:canPlayCard(card)
end

-- Play a card (spend mana and trigger effects)
function GameLogic:playCard(card, gameBoard, isPlayer)
    if not self:canPlayCard(card, isPlayer) then
        return false
    end
    
    -- Spend mana using Player or AI class
    local player = isPlayer and self.player or self.ai
    local success = player:spendMana(card.manaCost, gameBoard)
    
    if success then
        self:onCardPlayed(card, gameBoard)
        return true
    end
    
    return false
end

-- Submit player's turn
function GameLogic:submitTurn()
    if self.gamePhase == "staging" and self.turnManager:canPlayerInteract() then
        -- Use turn manager to handle turn submission
        self.turnManager:submitPlayerTurn(self)
    end
end

-- AI plays cards using AI logic
function GameLogic:playAITurn()
    if not self.gameBoard or not self.ai then return end
    
    -- Use AI's strategic play method
    self.ai:playTurn(self.gameBoard, self)
end

-- Start the reveal phase (start the "Revealing Cards..." animation)
function GameLogic:startRevealPhase()
    self.gamePhase = "revealing"
    
    -- Start the "Revealing Cards..." animation
    self.turnManager:startRevealPhase()
end

-- Start the Revealing Cards stage (called after "Revealing Cards..." animation completes)
function GameLogic:flipCardsAndTriggerEffects()
    -- If placedCardList is empty, no cards to reveal
    if #self.placedCardList == 0 then
        self.allCardRevealed = true
        return  -- Don't call completeRevealPhase here, let turn manager handle it
    end
    
    -- Check if there are any face-down cards to reveal
    local hasFaceDownCards = false
    for _, card in ipairs(self.placedCardList) do
        if not card.faceUp then
            hasFaceDownCards = true
            break
        end
    end
    
    -- If no face-down cards, skip to complete reveal phase
    if not hasFaceDownCards then
        self.allCardRevealed = true
        return  -- Don't call completeRevealPhase here, let turn manager handle it
    end
    
    -- Start revealing cards one by one in placement order
    self.gamePhase = "revealing_cards"
    self.allCardRevealed = false  -- Set flag to false as we start revealing
    self.currentRevealIndex = 1
    self:revealNextCard()
end

-- Reveal the next card in the placement order
function GameLogic:revealNextCard()
    -- Check if we've revealed all cards
    if self.currentRevealIndex > #self.placedCardList then
        -- All cards revealed, set flag and let turn manager handle completion
        self.allCardRevealed = true
        self.gamePhase = "revealing"
        return
    end
    
    local card = self.placedCardList[self.currentRevealIndex]
    
    -- Skip if card is already face up
    if card.faceUp then
        self.currentRevealIndex = self.currentRevealIndex + 1
        self:revealNextCard()
        return
    end
    
    -- Find the card's location and slot
    local locationIndex, slotIndex, isPlayer = self:findCardLocation(card)
    if locationIndex and slotIndex then
        -- Play flip sound effect
        if playFlipSound then
            playFlipSound()
        end
        
        -- Reveal the card and trigger its effect
        card.faceUp = true
        self:triggerCardEffectWithLocation(card, self.gameBoard, locationIndex, slotIndex)
        CardEffects:checkPassiveEffects(card, self.gameBoard, locationIndex)
        
        -- Move to next card and schedule next reveal with delay
        self.currentRevealIndex = self.currentRevealIndex + 1
        
        -- Check if this card has active animations
        if card._hasActiveAnimations then
            -- Wait longer for animations to complete
            self.nextRevealTimer = 1.2
        else
            -- Normal delay for cards without animations
            self.nextRevealTimer = 0.5
        end
    else
        -- Card not found in slots, skip it
        self.currentRevealIndex = self.currentRevealIndex + 1
        self:revealNextCard()
    end
end

-- Helper function to find a card's location and slot
function GameLogic:findCardLocation(targetCard)
    for locationIndex = 1, 3 do
        for slotIndex = 1, 4 do
            local playerCard = self.gameBoard.locations[locationIndex].playerSlots[slotIndex]
            local opponentCard = self.gameBoard.locations[locationIndex].opponentSlots[slotIndex]
            
            if playerCard == targetCard then
                return locationIndex, slotIndex, true
            elseif opponentCard == targetCard then
                return locationIndex, slotIndex, false
            end
        end
    end
    return nil, nil, nil
end

-- Complete the reveal phase (calculate scores and check game end)
function GameLogic:completeRevealPhase()
    -- Calculate scores for this turn
    GameStateManager:calculateLocationScores(self, self.gameBoard)
end

-- Start the next turn
function GameLogic:startNextTurn()
    GameStateManager:startNextTurn(self)
end

-- Draw cards at start of turn (only for player now, AI draws during opponent turn)
function GameLogic:drawCards()
    GameStateManager:drawCards(self)
end

-- Update game logic (call this in main update loop)
function GameLogic:update(dt)
    -- Update turn manager
    self.turnManager:update(dt, self.gameBoard, self)
    
    -- Handle card revealing timer during revealing_cards phase
    if self.gamePhase == "revealing_cards" and self.nextRevealTimer then
        self.nextRevealTimer = self.nextRevealTimer - dt
        if self.nextRevealTimer <= 0 then
            -- Check if there are any cards with active animations before proceeding
            local hasActiveAnimations = false
            if self.currentRevealIndex > 1 and self.currentRevealIndex <= #self.placedCardList + 1 then
                local previousCard = self.placedCardList[self.currentRevealIndex - 1]
                if previousCard and previousCard._hasActiveAnimations then
                    hasActiveAnimations = true
                end
            end
            
            if not hasActiveAnimations then
                -- No active animations, safe to reveal next card
                self.nextRevealTimer = nil
                self:revealNextCard()
            else
                -- Still have active animations, wait a bit more
                self.nextRevealTimer = 0.1  -- Check again in 0.1 seconds
            end
        end
    end
end

-- Check if player can interact with the game
function GameLogic:canPlayerInteract()
    return self.turnManager:canPlayerInteract()
end

-- Draw turn animations
function GameLogic:drawTurnAnimation(screenWidth, screenHeight)
    self.turnManager:draw(screenWidth, screenHeight)
end

-- Stop all animations (called when game ends)
function GameLogic:stopAllAnimations()
    -- Stop turn animations
    if self.turnManager then
        self.turnManager:stopAllAnimations()
    end
    
    -- Stop all card animations
    if self.gameBoard and self.gameBoard.cards then
        for _, card in ipairs(self.gameBoard.cards) do
            stopCardAnimations(card)
        end
    end
    
    -- Stop mana display animations
    if self.gameBoard and self.gameBoard.playerManaAnimations then
        for _, manaAnim in ipairs(self.gameBoard.playerManaAnimations) do
            stopCardAnimations(manaAnim)
        end
    end
end

-- Handle game end (called after scoring)
function GameLogic:handleGameEnd()
    return GameStateManager:handleGameEnd(self)
end

-- Check win conditions
function GameLogic:checkWinCondition(gameBoard)
    return GameStateManager:checkWinCondition(self, gameBoard)
end

return GameLogic