-- aiStrategy.lua: AI decision strategy module
local AIStrategy = {}

-- Evaluate the value of card placement
function AIStrategy:evaluatePlay(card, locationIndex, slotIndex, gameBoard)
    local score = 0
    
    -- Base score is the card's power value
    score = score + (card.power or 0)
    
    -- Extra reward for placing cards in losing positions
    local playerPower = 0
    local aiPower = 0
    
    for slot = 1, 4 do
        local playerCard = gameBoard.locations[locationIndex].playerSlots[slot]
        local aiCard = gameBoard.locations[locationIndex].opponentSlots[slot]
        
        if playerCard then
            playerPower = playerPower + (playerCard.power or 0)
        end
        
        if aiCard then
            aiPower = aiPower + (aiCard.power or 0)
        end
    end
    
    -- If behind in this position, give reward
    if playerPower > aiPower then
        score = score + 2
    end
    
    -- Prioritize filling locations (4-card locations get bonus)
    local aiCardsInLocation = 0
    for slot = 1, 4 do
        if gameBoard.locations[locationIndex].opponentSlots[slot] then
            aiCardsInLocation = aiCardsInLocation + 1
        end
    end
    
    if aiCardsInLocation == 3 then
        score = score + 3  -- 4th card gets extra bonus
    end
    
    -- Mana efficiency bonus
    local manaCost = card.manaCost or 0
    if manaCost > 0 then
        score = score + (card.power or 0) / manaCost
    end
    
    return score
end

-- Choose best card and position
function AIStrategy:chooseBestPlay(gameBoard, cardsToPlay, ai)
    local bestCard = nil
    local bestLocation = nil
    local bestSlot = nil
    local bestScore = -1
    
    -- Evaluate each card in hand
    for _, card in ipairs(gameBoard.opponentHand) do
        if ai:canPlayCard(card) then
            -- Evaluate each position
            for locationIndex = 1, 3 do
                for slotIndex = 1, 4 do
                    if self:isSlotAvailable(gameBoard, locationIndex, slotIndex, cardsToPlay or {}) then
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

-- Check if slot is available
function AIStrategy:isSlotAvailable(gameBoard, locationIndex, slotIndex, cardsToPlay)
    -- Check if slot is already occupied
    if gameBoard.locations[locationIndex].opponentSlots[slotIndex] ~= nil then
        return false
    end
    
    -- Check if already in planned cards list
    for _, play in ipairs(cardsToPlay) do
        if play.location == locationIndex and play.slot == slotIndex then
            return false
        end
    end
    
    return true
end

-- Get random viable placement
function AIStrategy:getRandomPlay(gameBoard, cardsToPlay, ai)
    local availablePlays = {}
    
    for _, card in ipairs(gameBoard.opponentHand) do
        if ai:canPlayCard(card) then
            for locationIndex = 1, 3 do
                for slotIndex = 1, 4 do
                    if self:isSlotAvailable(gameBoard, locationIndex, slotIndex, cardsToPlay) then
                        table.insert(availablePlays, {
                            card = card,
                            location = locationIndex,
                            slot = slotIndex
                        })
                    end
                end
            end
        end
    end
    
    if #availablePlays > 0 then
        local randomIndex = love.math.random(1, #availablePlays)
        return availablePlays[randomIndex]
    end
    
    return nil
end

return AIStrategy 