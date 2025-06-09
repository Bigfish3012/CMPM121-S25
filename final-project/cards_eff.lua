-- cards effect file:
require "card"

CardEffects = {}

-- initialize card effect system
function CardEffects.init(gameLogic)
    CardEffects.gameLogic = gameLogic
    CardEffects.effects = {}
    CardEffects:registerAllEffects()
end

-- register all card effects
function CardEffects:registerAllEffects()
    -- Zeus effect: When Revealed: Lower the power of each card in your opponent's hand by 1.
    self.effects["Zeus"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        
        -- Target opponent's hand
        local targetHand = isPlayerCard and gameBoard.opponentHand or gameBoard.playerHand
        
        for _, targetCard in ipairs(targetHand) do
            if targetCard.power > 0 then  -- Don't reduce power below 0
                targetCard.power = math.max(0, targetCard.power - 1)
            end
        end
        
        return true
    end
    
    -- Ares effect: When Revealed: Gain +2 power for each enemy card here.
    self.effects["Ares"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        local locationIndex, slotIndex = card._tempLocationIndex, card._tempSlotIndex
        
        -- Fallback to finding location if temp data not available
        if not locationIndex then
            locationIndex, slotIndex = self:findCardLocation(card, gameBoard)
        end
        
        if not locationIndex then
            return false
        end
        
        -- Count enemy cards in the same location
        local enemySlots = isPlayerCard and gameBoard.locations[locationIndex].opponentSlots or gameBoard.locations[locationIndex].playerSlots
        local enemyCardsCount = 0
        
        for _, enemyCard in ipairs(enemySlots) do
            if enemyCard ~= nil then
                enemyCardsCount = enemyCardsCount + 1
            end
        end
        
        -- Gain +2 power for each enemy card
        local powerGain = enemyCardsCount * 2
        card.power = card.power + powerGain
        
        return true
    end
    
    -- Cyclops effect: When Revealed: Discard your other cards here, gain +2 power for each discarded.
    self.effects["Cyclops"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        local locationIndex, slotIndex = card._tempLocationIndex, card._tempSlotIndex
        
        -- Fallback to finding location if temp data not available
        if not locationIndex then
            locationIndex, slotIndex = self:findCardLocation(card, gameBoard)
        end
        
        if not locationIndex then
            return false
        end
        
        -- Find other cards in the same location (same side)
        local mySlots = isPlayerCard and gameBoard.locations[locationIndex].playerSlots or gameBoard.locations[locationIndex].opponentSlots
        local cardsToDiscard = {}
        
        for i, slotCard in ipairs(mySlots) do
            if slotCard ~= nil and slotCard ~= card then
                table.insert(cardsToDiscard, {card = slotCard, slot = i})
            end
        end
        
        -- Discard other cards and count them
        local discardedCount = 0
        for _, cardData in ipairs(cardsToDiscard) do
            mySlots[cardData.slot] = nil  -- Remove from slot
            self.gameLogic:discardCard(cardData.card, gameBoard)
            discardedCount = discardedCount + 1
        end
        
        -- Gain +2 power for each discarded card
        local powerGain = discardedCount * 2
        card.power = card.power + powerGain
        
        return true
    end
    
    -- Demeter effect: When Revealed: Both players draw a card.
    self.effects["Demeter"] = function(card, gameBoard)
        -- Both players draw a card from their deck using the animated draw methods
        if self.gameLogic.player then
            self.gameLogic.player:drawCard(gameBoard)
        end
        if self.gameLogic.ai then
            self.gameLogic.ai:drawCard(gameBoard)
        end
        
        return true
    end
    
    -- Apollo effect: When Revealed: Gain +1 mana next turn.
    self.effects["Apollo"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        
        -- Add mana bonus for next turn using the new system
        if isPlayerCard then
            self.gameLogic.player:addManaBonus(1)
        else
            self.gameLogic.ai:addManaBonus(1)
        end
        
        return true
    end
    
    -- Poseidon effect: When Revealed: Move away an enemy card here with the lowest power.
    self.effects["Poseidon"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        local locationIndex, slotIndex = card._tempLocationIndex, card._tempSlotIndex
        
        -- Fallback to finding location if temp data not available
        if not locationIndex then
            locationIndex, slotIndex = self:findCardLocation(card, gameBoard)
        end
        
        if not locationIndex then
            return false
        end
        
        -- Find enemy cards in the same location
        local enemySlots = isPlayerCard and gameBoard.locations[locationIndex].opponentSlots or gameBoard.locations[locationIndex].playerSlots
        local enemyHand = isPlayerCard and gameBoard.opponentHand or gameBoard.playerHand
        
        local lowestPowerCard = nil
        local lowestPowerSlot = nil
        local lowestPower = math.huge
        
        for i, enemyCard in ipairs(enemySlots) do
            if enemyCard ~= nil and enemyCard.power < lowestPower then
                lowestPower = enemyCard.power
                lowestPowerCard = enemyCard
                lowestPowerSlot = i
            end
        end
        
        if lowestPowerCard then
            -- Remove from slot and return to hand
            enemySlots[lowestPowerSlot] = nil
            table.insert(enemyHand, lowestPowerCard)
            
            -- Reposition hand cards
            gameBoard:positionHandCards()
        end
        
        return true
    end
    
    -- Hydra effect: Add two copies to your hand when this card is discarded.
    self.effects["Hydra"] = function(card, gameBoard)
        -- This effect is triggered when the card is discarded, not when revealed
        -- We'll implement this as a special case in the discard function
        return true
    end
    
    -- Prometheus effect: When Revealed: Draw a card from your opponent's deck.
    self.effects["Prometheus"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        
        -- Draw from opponent's deck to your hand with animation
        local drawnCard = nil
        if isPlayerCard then
            -- Player draws from opponent's deck
            if #gameBoard.opponentDeck > 0 then
                drawnCard = table.remove(gameBoard.opponentDeck, 1)
                
                -- Get deck and hand positions for animation
                local deckPositions = gameBoard:getDeckPositions()
                local deckPos = deckPositions.opponent  -- Drawing from opponent's deck
                
                -- Position card at opponent's deck first
                drawnCard.position = Vector(deckPos.x, deckPos.y)
                drawnCard.faceUp = false  -- Start face down, flip during animation
                drawnCard.canDrag = false  -- Don't allow dragging during animation
                
                -- Add to player hand
                table.insert(gameBoard.playerHand, drawnCard)
                
                -- Calculate target position in hand
                gameBoard:positionHandCards()
                local targetPos = drawnCard.position  -- positionHandCards sets the final position
                
                -- Reset card to opponent's deck position and start animation
                drawnCard.position = Vector(deckPos.x, deckPos.y)
                drawnCard:startAnimation(targetPos.x, targetPos.y, 0.8)
                
                -- Set up animation callback to flip card and enable dragging when animation completes
                drawnCard:setAnimationCallback(function()
                    drawnCard.faceUp = true
                    drawnCard.canDrag = true
                end)
            end
        else
            -- Opponent draws from player's deck
            if #gameBoard.playerDeck > 0 then
                drawnCard = table.remove(gameBoard.playerDeck, 1)
                
                -- Get deck and hand positions for animation
                local deckPositions = gameBoard:getDeckPositions()
                local deckPos = deckPositions.player  -- Drawing from player's deck
                
                -- Position card at player's deck first
                drawnCard.position = Vector(deckPos.x, deckPos.y)
                drawnCard.faceUp = false
                drawnCard.canDrag = false
                
                -- Add to opponent hand
                table.insert(gameBoard.opponentHand, drawnCard)
                
                -- Calculate target position in hand
                gameBoard:positionHandCards()
                local targetPos = drawnCard.position  -- positionHandCards sets the final position
                
                -- Reset card to player's deck position and start animation
                drawnCard.position = Vector(deckPos.x, deckPos.y)
                drawnCard:startAnimation(targetPos.x, targetPos.y, 0.8)
            end
        end
        
        return true
    end
    
    -- Dionysus effect: When Revealed: Gain +2 power for each of your other cards here.
    self.effects["Dionysus"] = function(card, gameBoard)
        local isPlayerCard = self.gameLogic:isPlayerCard(card, gameBoard)
        local locationIndex, slotIndex = card._tempLocationIndex, card._tempSlotIndex
        
        -- Fallback to finding location if temp data not available
        if not locationIndex then
            locationIndex, slotIndex = self:findCardLocation(card, gameBoard)
        end
        
        if not locationIndex then
            return false
        end
        
        -- Count other friendly cards in the same location
        local mySlots = isPlayerCard and gameBoard.locations[locationIndex].playerSlots or gameBoard.locations[locationIndex].opponentSlots
        local friendlyCardsCount = 0
        
        for _, slotCard in ipairs(mySlots) do
            if slotCard ~= nil and slotCard ~= card then
                friendlyCardsCount = friendlyCardsCount + 1
            end
        end
        
        -- Gain +2 power for each friendly card
        local powerGain = friendlyCardsCount * 2
        card.power = card.power + powerGain
        
        return true
    end
    
    -- Athena effect: Gain +1 power when you play another card here.
    self.effects["Athena"] = function(card, gameBoard)
        -- This is a passive effect that triggers when other cards are played
        -- We'll mark this card as having a passive effect
        card.hasPassiveEffect = true
        card.passiveEffectType = "athena"
        
        return true
    end
end

-- Helper function to find a card's location and slot
function CardEffects:findCardLocation(card, gameBoard)
    for locationIndex = 1, 3 do
        local location = gameBoard.locations[locationIndex]
        
        -- Check player slots
        for slotIndex, slotCard in ipairs(location.playerSlots) do
            if slotCard == card then
                return locationIndex, slotIndex
            end
        end
        
        -- Check opponent slots
        for slotIndex, slotCard in ipairs(location.opponentSlots) do
            if slotCard == card then
                return locationIndex, slotIndex
            end
        end
    end
    
    return nil, nil
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
    
    for _, slotCard in ipairs(slotsToCheck) do
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
