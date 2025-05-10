-- card file: for the card class

require "vector"

CardClass = {}

CARD_STATE = {
    IDLE = 0,
    MOUSE_OVER = 1,
    GRABBED = 2
}

function CardClass:new(xPos, yPos, value)
    local card = {}
    local metadata = {__index = CardClass}
    setmetatable(card, metadata)
    
    card.position = Vector(xPos, yPos)
    card.state = CARD_STATE.IDLE
    card.value = value
    
    return card
end