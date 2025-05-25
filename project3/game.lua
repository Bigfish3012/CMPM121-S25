-- game file: for the game logic

require "card"

GameLogic = {}

-- Game state tracking
GameLogic.currentPlayer = "player"  -- "player" or "opponent"
GameLogic.playerMana = 10
GameLogic.opponentMana = 10
GameLogic.gameBoard = nil

-- Card effect system
GameLogic.cardEffects = {}

-- Initialize game logic with reference to game board
function GameLogic.init(gameBoard)
    GameLogic.gameBoard = gameBoard
    GameLogic:registerCardEffects()
end

-- Register all card effects
function GameLogic:registerCardEffects()
    -- Cyclops effect: When Revealed: Discard your other cards here, gain +2 power for each discarded.
    self.cardEffects["Cyclops"] = function(card, gameBoard)
        print("Triggering Cyclops effect for " .. card.name)
        
        -- Find all other cards in the same slot as this Cyclops
        local cardsInSlot = {}
        local isPlayerCard = GameLogic:isPlayerCard(card, gameBoard)
        
        -- Determine which hand to check based on whether this is a player or opponent card
        local targetHand = isPlayerCard and gameBoard.playerHand or gameBoard.opponentHand
        
        -- Find other cards in the same slot (approximate same Y position)
        for i, otherCard in ipairs(targetHand) do
            if otherCard ~= card and math.abs(otherCard.position.y - card.position.y) < 50 then
                table.insert(cardsInSlot, otherCard)
            end
        end
        
        -- Discard other cards and count them
        local discardedCount = 0
        for _, cardToDiscard in ipairs(cardsInSlot) do
            GameLogic:discardCard(cardToDiscard, gameBoard)
            discardedCount = discardedCount + 1
        end
        
        -- Gain +2 power for each discarded card
        local powerGain = discardedCount * 2
        card.power = card.power + powerGain
        
        print("Cyclops discarded " .. discardedCount .. " cards and gained " .. powerGain .. " power")
        print("Cyclops new power: " .. card.power)
        
        return true  -- Effect successfully triggered
    end
    
    -- Zeus effect: When Revealed: Lower the power of each card in your opponent's hand by 1.
    self.cardEffects["Zeus"] = function(card, gameBoard)
        print("Triggering Zeus effect for " .. card.name)
        
        local isPlayerCard = GameLogic:isPlayerCard(card, gameBoard)
        
        -- Target opponent's hand
        local targetHand = isPlayerCard and gameBoard.opponentHand or gameBoard.playerHand
        
        local affectedCards = 0
        for _, targetCard in ipairs(targetHand) do
            if targetCard.power > 0 then  -- Don't reduce power below 0
                targetCard.power = math.max(0, targetCard.power - 1)
                affectedCards = affectedCards + 1
            end
        end
        
        print("Zeus reduced power of " .. affectedCards .. " opponent cards by 1")
        return true
    end
    
    -- Ares effect: When Revealed: Gain +2 power for each enemy card here.
    self.cardEffects["Ares"] = function(card, gameBoard)
        print("Triggering Ares effect for " .. card.name)
        
        local isPlayerCard = GameLogic:isPlayerCard(card, gameBoard)
        
        -- Count enemy cards in the same slot (opposite side)
        local enemyHand = isPlayerCard and gameBoard.opponentHand or gameBoard.playerHand
        local enemyCardsInSlot = 0
        
        -- Find enemy cards in corresponding slot (approximate same X position)
        for _, enemyCard in ipairs(enemyHand) do
            if math.abs(enemyCard.position.x - card.position.x) < 150 then  -- Same general area
                enemyCardsInSlot = enemyCardsInSlot + 1
            end
        end
        
        -- Gain +2 power for each enemy card
        local powerGain = enemyCardsInSlot * 2
        card.power = card.power + powerGain
        
        print("Ares found " .. enemyCardsInSlot .. " enemy cards and gained " .. powerGain .. " power")
        print("Ares new power: " .. card.power)
        
        return true
    end
end

-- Check if a card belongs to the player
function GameLogic:isPlayerCard(card, gameBoard)
    for _, playerCard in ipairs(gameBoard.playerHand) do
        if playerCard == card then
            return true
        end
    end
    return false
end

-- Discard a card from the game
function GameLogic:discardCard(card, gameBoard)
    -- Remove from player hand
    for i, playerCard in ipairs(gameBoard.playerHand) do
        if playerCard == card then
            table.remove(gameBoard.playerHand, i)
            break
        end
    end
    
    -- Remove from opponent hand
    for i, opponentCard in ipairs(gameBoard.opponentHand) do
        if opponentCard == card then
            table.remove(gameBoard.opponentHand, i)
            break
        end
    end
    
    -- Remove from main cards array
    for i, gameCard in ipairs(gameBoard.cards) do
        if gameCard == card then
            table.remove(gameBoard.cards, i)
            break
        end
    end
    
    print("Discarded card: " .. card.name)
end

-- Trigger card effect when a card is revealed (played)
function GameLogic:triggerCardEffect(card, gameBoard)
    if not card or not card.name then
        return false
    end
    
    -- Check if this card has an effect
    local effectFunction = self.cardEffects[card.name]
    if effectFunction then
        print("Card " .. card.name .. " has an effect, triggering...")
        return effectFunction(card, gameBoard)
    else
        print("Card " .. card.name .. " has no special effect")
        return false
    end
end

-- Function to be called when a card is played/revealed
function GameLogic:onCardPlayed(card, gameBoard)
    print("Card played: " .. card.name)
    
    -- Make sure the card is face up (revealed)
    card.faceUp = true
    
    -- Trigger any card effects
    self:triggerCardEffect(card, gameBoard)
    
    -- Reposition cards after effects
    gameBoard:positionHandCards()
end

-- Check if player can afford to play a card
function GameLogic:canPlayCard(card, isPlayer)
    local currentMana = isPlayer and self.playerMana or self.opponentMana
    return currentMana >= card.manaCost
end

-- Play a card (spend mana and trigger effects)
function GameLogic:playCard(card, gameBoard, isPlayer)
    if not self:canPlayCard(card, isPlayer) then
        print("Not enough mana to play " .. card.name)
        return false
    end
    
    -- Spend mana
    if isPlayer then
        self.playerMana = self.playerMana - card.manaCost
        gameBoard.playerMana = self.playerMana  -- Update gameBoard's mana tracking
    else
        self.opponentMana = self.opponentMana - card.manaCost
        gameBoard.opponentMana = self.opponentMana
    end
    
    print("Spent " .. card.manaCost .. " mana to play " .. card.name)
    
    -- Trigger card effects
    self:onCardPlayed(card, gameBoard)
    
    return true
end

-- End turn and switch to other player
function GameLogic:endTurn()
    print("Ending turn for " .. self.currentPlayer)
    
    -- Restore mana at start of turn
    if self.currentPlayer == "player" then
        self.currentPlayer = "opponent"
        self.opponentMana = math.min(10, self.opponentMana + 1)  -- Gain 1 mana per turn, max 10
        if self.gameBoard then
            self.gameBoard.opponentMana = self.opponentMana
        end
    else
        self.currentPlayer = "player"
        self.playerMana = math.min(10, self.playerMana + 1)
        if self.gameBoard then
            self.gameBoard.playerMana = self.playerMana
        end
    end
    
    print("It's now " .. self.currentPlayer .. "'s turn")
end

-- Calculate total power for a player
function GameLogic:calculatePlayerPower(gameBoard, isPlayer)
    local totalPower = 0
    local targetHand = isPlayer and gameBoard.playerHand or gameBoard.opponentHand
    
    for _, card in ipairs(targetHand) do
        if card.faceUp then  -- Only count revealed cards
            totalPower = totalPower + card.power
        end
    end
    
    return totalPower
end

-- Check win conditions
function GameLogic:checkWinCondition(gameBoard)
    -- Example win condition: first to 20 power wins
    local playerPower = self:calculatePlayerPower(gameBoard, true)
    local opponentPower = self:calculatePlayerPower(gameBoard, false)
    
    print("Player power: " .. playerPower .. ", Opponent power: " .. opponentPower)
    
    if playerPower >= 20 then
        return "player"
    elseif opponentPower >= 20 then
        return "opponent"
    end
    
    return nil  -- No winner yet
end

return GameLogic