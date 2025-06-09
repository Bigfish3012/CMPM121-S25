-- ai.lua: AI opponent logic and decision making

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
    
    local attempts = 0
    local maxAttempts = 20
    
    -- AI tries to play cards based on strategy
    while #gameBoard.opponentHand > 0 and attempts < maxAttempts do
        attempts = attempts + 1
        
        local bestCard, bestLocation, bestSlot = self:chooseBestPlay(gameBoard)
        
        if bestCard and bestLocation and bestSlot then
            -- Try to place the card
            if gameBoard.locations[bestLocation].opponentSlots[bestSlot] == nil then
                -- Place card and spend mana
                gameBoard.locations[bestLocation].opponentSlots[bestSlot] = bestCard
                bestCard.faceUp = false  -- AI cards start face down
                
                -- Spend mana
                if self:spendMana(bestCard.manaCost, gameBoard) then
                    -- Remove from hand
                    for i, card in ipairs(gameBoard.opponentHand) do
                        if card == bestCard then
                            table.remove(gameBoard.opponentHand, i)
                            break
                        end
                    end
                    gameBoard:positionHandCards()
                    break
                else
                    -- Can't afford card, remove it from slot
                    gameBoard.locations[bestLocation].opponentSlots[bestSlot] = nil
                end
            end
        else
            -- No valid play found, try random placement
            self:playRandomCard(gameBoard)
            break
        end
    end
end

-- Choose the best card and location to play (AI strategy)
function AI:chooseBestPlay(gameBoard)
    local bestCard = nil
    local bestLocation = nil
    local bestSlot = nil
    local bestScore = -1
    
    -- Evaluate each card in hand
    for _, card in ipairs(gameBoard.opponentHand) do
        if self:canPlayCard(card) then
            -- Evaluate each location
            for locationIndex = 1, 3 do
                for slotIndex = 1, 4 do
                    if gameBoard.locations[locationIndex].opponentSlots[slotIndex] == nil then
                        local score = self:evaluatePlay(card, locationIndex, slotIndex, gameBoard)
                        if score > bestScore then
                            bestScore = score
                            bestCard = card
                            bestLocation = locationIndex
                            bestSlot = slotIndex
                        end
                    end
                end
            end
        end
    end
    
    return bestCard, bestLocation, bestSlot
end

-- Evaluate how good a play would be (AI strategy)
function AI:evaluatePlay(card, locationIndex, slotIndex, gameBoard)
    local score = 0
    
    -- Base score is the card's power
    score = score + (card.power or 0)
    
    -- Bonus for playing in locations where we're behind
    local playerPower = 0
    local aiPower = 0
    
    for slot = 1, 4 do
        local playerCard = gameBoard.locations[locationIndex].playerSlots[slot]
        local aiCard = gameBoard.locations[locationIndex].opponentSlots[slot]
        
        if playerCard and playerCard.faceUp then
            playerPower = playerPower + (playerCard.power or 0)
        end
        if aiCard and aiCard.faceUp then
            aiPower = aiPower + (aiCard.power or 0)
        end
    end
    
    -- If we're behind in this location, prioritize it
    if playerPower > aiPower then
        score = score + 5
    end
    
    -- Special card considerations
    if card.name == "Ares" then
        -- Ares gets stronger with enemy cards, so prefer contested locations
        local enemyCards = 0
        for slot = 1, 4 do
            if gameBoard.locations[locationIndex].playerSlots[slot] then
                enemyCards = enemyCards + 1
            end
        end
        score = score + enemyCards * 2
    elseif card.name == "Cyclops" then
        -- Cyclops benefits from having other cards to sacrifice
        local ownCards = 0
        for slot = 1, 4 do
            if gameBoard.locations[locationIndex].opponentSlots[slot] then
                ownCards = ownCards + 1
            end
        end
        score = score + ownCards * 2
    elseif card.name == "Zeus" then
        -- Zeus is generally good, slight bonus
        score = score + 3
    end
    
    -- Prefer playing higher cost cards when we have more mana
    if self.mana > 5 and (card.manaCost or 0) > 3 then
        score = score + 2
    end
    
    return score
end

-- Fallback: play a random card (simple AI)
function AI:playRandomCard(gameBoard)
    local attempts = 0
    while #gameBoard.opponentHand > 0 and attempts < 10 do
        attempts = attempts + 1
        
        -- Pick a random card from AI hand
        local cardIndex = love.math.random(1, #gameBoard.opponentHand)
        local card = gameBoard.opponentHand[cardIndex]
        
        -- Check if AI can afford this card
        if self:canPlayCard(card) then
            -- Find a random empty slot
            local locationIndex = love.math.random(1, 3)
            local slotIndex = love.math.random(1, 4)
            
            -- Try to place the card
            if gameBoard.locations[locationIndex].opponentSlots[slotIndex] == nil then
                -- Place card and spend mana
                gameBoard.locations[locationIndex].opponentSlots[slotIndex] = card
                card.faceUp = false  -- AI cards start face down
                self:spendMana(card.manaCost, gameBoard)
                
                -- Remove from hand
                table.remove(gameBoard.opponentHand, cardIndex)
                gameBoard:positionHandCards()
                break
            end
        end
    end
end


return AI
