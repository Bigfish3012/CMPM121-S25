-- player file: for the player class

playerClass = {}

function playerClass:new()
    local player = {}
    local metadata = {__index = playerClass}
    setmetatable(player, metadata)
    
    player.hand = {}
    player.mana = 0
    player.maxMana = 10
    player.maxHandSize = 7
    player.totallPower = 0
    
    return player
end