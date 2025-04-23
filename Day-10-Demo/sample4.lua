
-- Original Code Sample #4
-- In love.load()

cards = {}

local suits = {"S", "H", "D", "C"}
local ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}

for i=1, #suits do
    for j=1, #ranks do
        table.insert(cards, love.graphics.newImage("sprites/" .. suits[i] .. ranks[j] .. ".png"))
    end
end