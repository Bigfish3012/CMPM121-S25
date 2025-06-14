-- ai.lua: AI opponent logic and decision making
require "vector"
local AIStrategy = require "aiStrategy"

AI = {}

-- Initialize AI
function AI:new()
    local ai = {}
    local metadata = {__index = AI}
    setmetatable(ai, metadata)
    
    ai.mana = 1
    ai.manaBonus = 0
    ai.score = 0
    ai.submitted = false
    ai.allAnimationsComplete = true  -- Initialize animation state as complete
    return ai
end

-- Check if AI can afford to play a card
function AI:canPlayCard(card)
    return self.mana >= (card.manaCost or 0)
end

-- Spend mana to play a card
function AI:spendMana(amount, gameBoard)
    if self.mana >= amount then
        local previousMana = self.mana
        self.mana = self.mana - amount
        
        -- Trigger mana use animation if gameBoard is available
        if gameBoard and gameBoard.animateManaUse then
            gameBoard:animateManaUse(false, previousMana, self.mana)
        end
        
        return true
    end
    return false
end

-- Add mana bonus for next turn
function AI:addManaBonus(amount)
    self.manaBonus = self.manaBonus + amount
end

-- Set mana for new turn
function AI:setManaForTurn(baseMana, gameBoard)
    local previousMana = self.mana
    self.mana = baseMana + self.manaBonus
    self.manaBonus = 0  -- Reset bonus after use
    
    -- Trigger mana gain animation if mana increased and gameBoard is available
    if gameBoard and gameBoard.animateManaGain and self.mana > previousMana then
        gameBoard:animateManaGain(false, self.mana)
    end
end

-- Add points to score
function AI:addScore(points)
    self.score = self.score + points
end

-- Submit turn
function AI:submitTurn()
    self.submitted = true
end

-- Reset for new turn
function AI:resetForNewTurn()
    self.submitted = false
    self.allAnimationsComplete = true  -- Reset animation state
end

-- Check if all AI animations are complete
function AI:areAllAnimationsComplete()
    return self.allAnimationsComplete ~= false  -- Default to true if not set
end

-- Draw a card from deck to hand
function AI:drawCard(gameBoard)
    if #gameBoard.opponentHand < 7 and #gameBoard.opponentDeck > 0 then
        local card = table.remove(gameBoard.opponentDeck)
        
        -- Get deck and hand positions for animation
        local deckPositions = gameBoard:getDeckPositions()
        local deckPos = deckPositions.opponent
        
        -- Position card at deck first
        card.position = Vector(deckPos.x, deckPos.y)
        card.faceUp = false
        card.canDrag = false
        
        -- Add to hand first so positioning calculation works
        table.insert(gameBoard.opponentHand, card)
        
        -- Calculate target position in hand
        gameBoard:positionHandCards()
        local targetPos = card.position
        
        -- Reset card to deck position and start animation
        card.position = Vector(deckPos.x, deckPos.y)
        card:startAnimation(targetPos.x, targetPos.y, 0.8)
        
        return card
    end
    return nil
end

-- Check if AI has won
function AI:hasWon(targetScore)
    return self.score >= targetScore
end

-- AI decision making: play cards from hand
function AI:playTurn(gameBoard, gameLogic)
    if not gameBoard then return end
    
    -- Initialize animation state
    self.allAnimationsComplete = false
    
    -- AI will play cards synchronously to avoid animation timing issues
    self:playCardsSequentially(gameBoard, gameLogic)
end

-- Play cards one by one, considering mana constraints
function AI:playCardsSequentially(gameBoard, gameLogic)
    -- Create a list of cards to play
    local cardsToPlay = {}
    local attempts = 0
    local maxAttempts = 20 
    local maxCardsPerTurn = 4
    local consecutiveFailures = 0
    local maxConsecutiveFailures = 5    
    
    while #gameBoard.opponentHand > 0 and attempts < maxAttempts and #cardsToPlay < maxCardsPerTurn and consecutiveFailures < maxConsecutiveFailures do
        attempts = attempts + 1
        local playFound = false
        
        local bestCard, bestLocation, bestSlot = AIStrategy:chooseBestPlay(gameBoard, cardsToPlay, self)
        
        if bestCard and bestLocation and bestSlot then
            -- Check if slot is empty and AI can afford the card
            if AIStrategy:isSlotAvailable(gameBoard, bestLocation, bestSlot, cardsToPlay) and self:canPlayCard(bestCard) then
                -- Add to play queue
                table.insert(cardsToPlay, {
                    card = bestCard,
                    location = bestLocation,
                    slot = bestSlot
                })
                
                -- Immediately spend mana to prevent double-spending
                self:spendMana(bestCard.manaCost or 0, gameBoard)
                playFound = true
            else
                -- Can't play best card, try random placement
                local randomPlay = AIStrategy:getRandomPlay(gameBoard, cardsToPlay, self)
                if randomPlay then
                    table.insert(cardsToPlay, randomPlay)
                    self:spendMana(randomPlay.card.manaCost or 0, gameBoard)
                    playFound = true
                end
            end
        else
            -- No valid strategic play found, try random placement
            local randomPlay = AIStrategy:getRandomPlay(gameBoard, cardsToPlay, self)
            if randomPlay then
                table.insert(cardsToPlay, randomPlay)
                self:spendMana(randomPlay.card.manaCost or 0, gameBoard)
                playFound = true
            end
        end
        
        if playFound then
            consecutiveFailures = 0
        else
            consecutiveFailures = consecutiveFailures + 1
        end
        if not playFound and consecutiveFailures >= maxConsecutiveFailures then
            break
        end
    end
    
    -- Now play cards with proper animation sequencing
    if #cardsToPlay > 0 then
        self.allAnimationsComplete = false
        self:playCardsWithAnimation(cardsToPlay, gameBoard, 1, function()
            self.allAnimationsComplete = true
        end)
    else
        -- No cards to play, animations are immediately complete
        self.allAnimationsComplete = true
    end
end





-- Play cards with sequential animation
function AI:playCardsWithAnimation(cardsToPlay, gameBoard, index, onAllAnimationsComplete)
    if index > #cardsToPlay then
        -- All cards have been played, call completion callback if provided
        if onAllAnimationsComplete then
            onAllAnimationsComplete()
        end
        return
    end
    
    local play = cardsToPlay[index]
    local card = play.card
    local location = play.location
    local slot = play.slot
    
    -- Calculate target position for animation
    local targetPos = gameBoard.cardPositioning:getSlotPosition(
        location, slot, true, 
        gameBoard.screenWidth, gameBoard.screenHeight, 
        gameBoard.cardWidth, gameBoard.cardHeight
    )
    
    -- Set up completion callback to place card and continue with next card
    card.animationCompleteCallback = function()
        -- Place the actual card in the slot
        gameBoard.locations[location].opponentSlots[slot] = card
        card.faceUp = false  -- AI cards start face down
        
        -- Remove from hand
        for i, c in ipairs(gameBoard.opponentHand) do
            if c == card then
                table.remove(gameBoard.opponentHand, i)
                break
            end
        end
        gameBoard:positionHandCards()
        
        -- Notify GameLogic that a card was played (for placement tracking)
        local GameLogic = require "game"
        GameLogic:onCardPlayed(card, gameBoard)
        
        -- Play next card immediately (no delay needed since animations are sequential)
        if index < #cardsToPlay then
            self:playCardsWithAnimation(cardsToPlay, gameBoard, index + 1, onAllAnimationsComplete)
        else
            -- This was the last card, call completion callback
            if onAllAnimationsComplete then
                onAllAnimationsComplete()
            end
        end
    end
    
    -- Start animation from hand to board position
    card:startAnimation(targetPos.x, targetPos.y, 0.6)
end

return AI
