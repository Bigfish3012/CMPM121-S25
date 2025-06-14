-- cards effect file:
require "card"
require "vector"

CardEffects = {}

-- initialize card effect system
function CardEffects.init(gameLogic)
    CardEffects.gameLogic = gameLogic
    CardEffects.effects = {}
    CardEffects:registerAllEffects()
end

-- Helper function to find enemy cards in a location
local function getEnemyCardsInLocation(card, gameBoard, locationIndex)
    local isPlayerCard = CardEffects.gameLogic:isPlayerCard(card, gameBoard)
    local enemySlots = isPlayerCard and gameBoard.locations[locationIndex].opponentSlots 
                                     or gameBoard.locations[locationIndex].playerSlots
    
    local enemyCards = {}
    for i = 1, 4 do
        if enemySlots[i] ~= nil then
            table.insert(enemyCards, {card = enemySlots[i], slot = i})
        end
    end
    return enemyCards, enemySlots
end

-- Helper function to find allied cards in a location
local function getAlliedCardsInLocation(card, gameBoard, locationIndex)
    local isPlayerCard = CardEffects.gameLogic:isPlayerCard(card, gameBoard)
    local mySlots = isPlayerCard and gameBoard.locations[locationIndex].playerSlots 
                                  or gameBoard.locations[locationIndex].opponentSlots
    
    local alliedCards = {}
    for i = 1, 4 do
        local slotCard = mySlots[i]
        if slotCard ~= nil and slotCard ~= card then
            table.insert(alliedCards, {card = slotCard, slot = i})
        end
    end
    return alliedCards, mySlots
end

-- Helper function to get target hand based on card ownership
local function getTargetHand(card, gameBoard, targetOpponent)
    local isPlayerCard = CardEffects.gameLogic:isPlayerCard(card, gameBoard)
    
    if targetOpponent then
        return isPlayerCard and gameBoard.opponentHand or gameBoard.playerHand
    else
        return isPlayerCard and gameBoard.playerHand or gameBoard.opponentHand
    end
end

-- Helper function to find card location
local function findCardLocation(card, gameBoard)
    -- Use temp data first if available
    if card._tempLocationIndex then
        return card._tempLocationIndex, card._tempSlotIndex
    end
    
    -- Search for card in all locations
    for locationIndex = 1, 3 do
        for slotIndex = 1, 4 do
            if gameBoard.locations[locationIndex].playerSlots[slotIndex] == card or
               gameBoard.locations[locationIndex].opponentSlots[slotIndex] == card then
                return locationIndex, slotIndex
            end
        end
    end
    return nil, nil
end

-- Helper function to animate card draw from deck to hand
local function animateCardDraw(gameBoard, drawnCard, fromDeck, toHand, targetPos, flipOnComplete)
    if not drawnCard then return end
    
    drawnCard.position = Vector(fromDeck.x, fromDeck.y)
    drawnCard.faceUp = false
    drawnCard.canDrag = false
    
    drawnCard:startAnimation(targetPos.x, targetPos.y, 0.8)
    
    if flipOnComplete then
        drawnCard:setAnimationCallback(function()
            -- Play flip sound effect
            if playFlipSound then
                playFlipSound()
            end
            drawnCard.faceUp = true
            drawnCard.canDrag = true
        end)
    end
end

-- Zeus effect: Lower opponent's hand power by 1
local function zeusEffect(card, gameBoard)
    local targetHand = getTargetHand(card, gameBoard, true)
    
    for _, targetCard in ipairs(targetHand) do
        if targetCard.power > 0 then
            targetCard.power = math.max(0, targetCard.power - 1)
        end
    end
    return true
end

-- Ares effect: Gain +2 power for each enemy card in location
local function aresEffect(card, gameBoard)
    local locationIndex = findCardLocation(card, gameBoard)
    if not locationIndex then return false end
    
    local enemyCards = getEnemyCardsInLocation(card, gameBoard, locationIndex)
    local powerGain = #enemyCards * 2
    card.power = card.power + powerGain
    
    return true
end

-- Cyclops effect: Discard allied cards, gain +2 power per discarded
local function cyclopsEffect(card, gameBoard)
    local locationIndex = findCardLocation(card, gameBoard)
    if not locationIndex then return false end
    
    local alliedCards, mySlots = getAlliedCardsInLocation(card, gameBoard, locationIndex)
    
    -- Determine the correct discard pile before removing cards from slots
    local isPlayerCard = CardEffects.gameLogic:isPlayerCard(card, gameBoard)
    local targetDiscardPile = isPlayerCard and gameBoard.playerDiscardPile or gameBoard.opponentDiscardPile
    
    -- Discard allied cards and count them
    local discardedCount = 0
    for _, cardData in ipairs(alliedCards) do
        -- Remove from slot
        mySlots[cardData.slot] = nil
        
        -- Add directly to the correct discard pile
        table.insert(targetDiscardPile, cardData.card)
        
        -- Handle any special discard effects (like Hydra)
        CardEffects:handleHydraDiscard(cardData.card, gameBoard)
        
        -- Remove from main cards array
        for i = #gameBoard.cards, 1, -1 do
            if gameBoard.cards[i] == cardData.card then
                table.remove(gameBoard.cards, i)
                break
            end
        end
        
        discardedCount = discardedCount + 1
    end
    
    -- Gain power
    card.power = card.power + (discardedCount * 2)
    return true
end

-- Demeter effect: Both players draw a card
local function demeterEffect(card, gameBoard)
    local animationsStarted = false
    local playerCard = nil
    local aiCard = nil
    
    if CardEffects.gameLogic.player then
        playerCard = CardEffects.gameLogic.player:drawCard(gameBoard)
        if playerCard then
            animationsStarted = true
        end
    end
    
    if CardEffects.gameLogic.ai then
        aiCard = CardEffects.gameLogic.ai:drawCard(gameBoard)
        if aiCard then
            animationsStarted = true
        end
    end
    
    -- If animations were started, we need to wait for them to complete
    if animationsStarted then
        -- Set a flag to indicate this effect has animations
        card._hasActiveAnimations = true
        
        -- Track completion of both animations
        local completedAnimations = 0
        local totalAnimations = (playerCard and 1 or 0) + (aiCard and 1 or 0)
        
        local function onAnimationComplete()
            completedAnimations = completedAnimations + 1
            if completedAnimations >= totalAnimations then
                -- All animations complete, clear the flag
                card._hasActiveAnimations = false
            end
        end
        
        -- Set completion callbacks
        if playerCard then
            local originalCallback = playerCard.animationCompleteCallback
            playerCard.animationCompleteCallback = function()
                if originalCallback then
                    originalCallback()
                end
                onAnimationComplete()
            end
        end
        
        if aiCard then
            local originalCallback = aiCard.animationCompleteCallback
            aiCard.animationCompleteCallback = function()
                if originalCallback then
                    originalCallback()
                end
                onAnimationComplete()
            end
        end
    end
    
    return true
end

-- Apollo effect: Gain +1 mana next turn
local function apolloEffect(card, gameBoard)
    local isPlayerCard = CardEffects.gameLogic:isPlayerCard(card, gameBoard)
    
    if isPlayerCard then
        CardEffects.gameLogic.player:addManaBonus(1)
    else
        CardEffects.gameLogic.ai:addManaBonus(1)
    end
    return true
end

-- Poseidon effect: Move away lowest power enemy card
local function poseidonEffect(card, gameBoard)
    local locationIndex = findCardLocation(card, gameBoard)
    if not locationIndex then return false end
    
    local enemyCards, enemySlots = getEnemyCardsInLocation(card, gameBoard, locationIndex)
    
    -- Find lowest power enemy card
    local lowestPowerCard, lowestPowerSlot = nil, nil
    local lowestPower = math.huge
    
    for _, enemyData in ipairs(enemyCards) do
        local power = enemyData.card.power or 0
        if power < lowestPower then
            lowestPower = power
            lowestPowerCard = enemyData.card
            lowestPowerSlot = enemyData.slot
        end
    end
    
    if lowestPowerCard then
        -- Play flip sound effect
        if playFlipSound then
            playFlipSound()
        end
        lowestPowerCard.faceUp = true
        lowestPowerCard.canDrag = false
        CardEffects.gameLogic:discardCard(lowestPowerCard, gameBoard)
    end
    
    return true
end

-- Prometheus effect: Draw from opponent's deck
local function prometheusEffect(card, gameBoard)
    local isPlayerCard = CardEffects.gameLogic:isPlayerCard(card, gameBoard)
    local deckPositions = gameBoard:getDeckPositions()
    
    local sourceDeck, targetHand, deckPos
    if isPlayerCard then
        sourceDeck = gameBoard.opponentDeck
        targetHand = gameBoard.playerHand
        deckPos = deckPositions.opponent
    else
        sourceDeck = gameBoard.playerDeck
        targetHand = gameBoard.opponentHand
        deckPos = deckPositions.player
    end
    
    if #sourceDeck > 0 then
        local drawnCard = table.remove(sourceDeck, 1)
        table.insert(targetHand, drawnCard)
        
        gameBoard:positionHandCards()
        local targetPos = drawnCard.position
        
        -- Set flag to indicate this effect has animations
        card._hasActiveAnimations = true
        
        -- Set up the card animation first
        drawnCard.position = Vector(deckPos.x, deckPos.y)
        drawnCard.faceUp = false
        drawnCard.canDrag = false
        
        drawnCard:startAnimation(targetPos.x, targetPos.y, 0.8)
        
        -- Set up completion callback to clear the animation flag and handle flipping
        drawnCard:setAnimationCallback(function()
            -- Handle card flipping for player cards
            if isPlayerCard then
                -- Play flip sound effect
                if playFlipSound then
                    playFlipSound()
                end
                drawnCard.faceUp = true
                drawnCard.canDrag = true
            end
            
            -- Clear the animation flag when animation completes
            card._hasActiveAnimations = false
        end)
    end
    
    return true
end

-- Dionysus effect: Gain +2 power for each allied card
local function dionysusEffect(card, gameBoard)
    local locationIndex = findCardLocation(card, gameBoard)
    if not locationIndex then return false end
    
    local alliedCards = getAlliedCardsInLocation(card, gameBoard, locationIndex)
    local powerGain = #alliedCards * 2
    card.power = card.power + powerGain
    
    return true
end

-- register all card effects
function CardEffects:registerAllEffects()
    self.effects = {
        ["Zeus"] = zeusEffect,
        ["Ares"] = aresEffect,
        ["Cyclops"] = cyclopsEffect,
        ["Demeter"] = demeterEffect,
        ["Apollo"] = apolloEffect,
        ["Poseidon"] = poseidonEffect,
        ["Hydra"] = function() return true end, -- Special handling in discard
        ["Prometheus"] = prometheusEffect,
        ["Dionysus"] = dionysusEffect,
        ["Athena"] = function(card, gameBoard)
            card.hasPassiveEffect = true
            card.passiveEffectType = "athena"
            return true
        end
    }
end

-- Alternative method to find card location by passing location info
function CardEffects:triggerEffectWithLocation(cardName, card, gameBoard, locationIndex, slotIndex)
    local effectFunction = self.effects[cardName]
    if effectFunction then
        -- Store location info temporarily for effects that need it
        card._tempLocationIndex = locationIndex
        card._tempSlotIndex = slotIndex
        local result = effectFunction(card, gameBoard)
        -- Clean up temporary data
        card._tempLocationIndex = nil
        card._tempSlotIndex = nil
        return result
    else
        return false
    end
end

-- Trigger a card effect
function CardEffects:triggerEffect(cardName, card, gameBoard)
    local effectFunction = self.effects[cardName]
    if effectFunction then
        return effectFunction(card, gameBoard)
    else
        return false
    end
end

-- Check for passive effects (like Athena)
function CardEffects:checkPassiveEffects(newCard, gameBoard, locationIndex)
    local location = gameBoard.locations[locationIndex]
    local isPlayerCard = self.gameLogic:isPlayerCard(newCard, gameBoard)
    
    -- Check slots for Athena cards
    local slotsToCheck = isPlayerCard and location.playerSlots or location.opponentSlots
    
    for i = 1, 4 do
        local slotCard = slotsToCheck[i]
        if slotCard and slotCard ~= newCard and slotCard.hasPassiveEffect and slotCard.passiveEffectType == "athena" then
            slotCard.power = slotCard.power + 1
        end
    end
end

-- Special handling for Hydra discard effect
function CardEffects:handleHydraDiscard(card, gameBoard)
    if card.name == "Hydra" then
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        local targetHand = isPlayerCard and gameBoard.playerHand or gameBoard.opponentHand
        
        -- Create two copies of Hydra
        for i = 1, 2 do
            local hydraInfo = CARD_INFO["Hydra"]
            
            if hydraInfo then
                local newHydra = CardClass:new(0, 0, hydraInfo.name, hydraInfo.power, hydraInfo.manaCost, hydraInfo.text, false)
                newHydra.canDrag = isPlayerCard
                table.insert(targetHand, newHydra)
                table.insert(gameBoard.cards, newHydra)
            end
        end
        
        gameBoard:positionHandCards()
        
        return true
    end
    
    return false
end

return CardEffects
