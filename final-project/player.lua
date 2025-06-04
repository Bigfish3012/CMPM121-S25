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
function Player:spendMana(amount)
    if self.mana >= amount then
        self.mana = self.mana - amount
        return true
    end
    return false
end

-- Add mana bonus for next turn
function Player:addManaBonus(amount)
    self.manaBonus = self.manaBonus + amount
end

-- Set mana for new turn
function Player:setManaForTurn(baseMana)
    self.mana = baseMana + self.manaBonus
    self.manaBonus = 0
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
        card.faceUp = true
        card.canDrag = true
        table.insert(gameBoard.playerHand, card)
        return card
    end
    return nil
end

function Player:hasWon(targetScore)
    return self.score >= targetScore
end

return Player
