-- card file: for the card class

require "vector"

CardClass = {}

CARD_STATE = {
    IDLE = 0,
    MOUSE_OVER = 1,
    GRABBED = 2
}

function CardClass:new(xPos, yPos, power, manaCost, text, faceUp)
    local card = {}
    local metadata = {__index = CardClass}
    setmetatable(card, metadata)
    
    card.position = Vector(xPos, yPos)
    card.state = CARD_STATE.IDLE
    card.power = power
    card.manaCost = manaCost
    card.text = text
    card.faceUp = faceUp or false
    card.canDrag = false
    
    return card
end

function CardClass:update()
    if self.state == CARD_STATE.GRABBED then
        self.position = grabber.currentMousePos + grabber.dragOffset
    end
end

function CardClass:draw()
    -- Draw the card
end


function CardClass:getPower()
    return self.power
end
function CardClass:getManaCost()
    return self.manaCost
end
function CardClass:getText()
    return self.text
end
