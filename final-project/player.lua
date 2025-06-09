-- player.lua: Player-related logic and functionality

Player = {}

-- Initialize player
function Player:new()
    local player = {}
    local metadata = {__index = Player}
    setmetatable(player, metadata)
    
    player.mana = 1
    player.manaBonus = 0
    player.score = 0
    player.submitted = false
    
    return player
end

-- Check if player can afford to play a card
function Player:canPlayCard(card)
    return self.mana >= (card.manaCost or 0)
end

-- Spend mana to play a card
function Player:spendMana(amount, gameBoard)
    if self.mana >= amount then
        local previousMana = self.mana
        self.mana = self.mana - amount
        
        -- Trigger mana use animation if gameBoard is available
        if gameBoard and gameBoard.animateManaUse then
            gameBoard:animateManaUse(true, previousMana, self.mana)
        end
        
        return true
    end
    return false
end

-- Add mana bonus for next turn
function Player:addManaBonus(amount)
    self.manaBonus = self.manaBonus + amount
end

-- Set mana for new turn
function Player:setManaForTurn(baseMana, gameBoard)
    local previousMana = self.mana
    self.mana = baseMana + self.manaBonus
    self.manaBonus = 0
    
    -- Trigger mana gain animation if mana increased and gameBoard is available
    if gameBoard and gameBoard.animateManaGain and self.mana > previousMana then
        gameBoard:animateManaGain(true, self.mana)
    end
end

function Player:addScore(points)
    self.score = self.score + points
end

function Player:submitTurn()
    self.submitted = true
end

function Player:resetForNewTurn()
    self.submitted = false
end

function Player:drawCard(gameBoard)
    if #gameBoard.playerHand < 7 and #gameBoard.playerDeck > 0 then
        local card = table.remove(gameBoard.playerDeck)
        
        -- Get deck and hand positions for animation
        local deckPositions = gameBoard:getDeckPositions()
        local deckPos = deckPositions.player
        
        -- Position card at deck first
        card.position = Vector(deckPos.x, deckPos.y)
        card.faceUp = false 
        card.canDrag = false
        
        -- Add to hand first so positioning calculation works
        table.insert(gameBoard.playerHand, card)
        
        -- Calculate target position in hand
        gameBoard:positionHandCards()
        local targetPos = card.position
        
        -- Reset card to deck position and start animation
        card.position = Vector(deckPos.x, deckPos.y)
        card:startAnimation(targetPos.x, targetPos.y, 0.8)
        
        -- Set up animation callback to flip card and enable dragging when animation completes
        card:setAnimationCallback(function()
            card.faceUp = true
            card.canDrag = true
        end)
        
        return card
    end
    return nil
end

function Player:hasWon(targetScore)
    return self.score >= targetScore
end

return Player
