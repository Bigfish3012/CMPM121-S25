-- cardPositioning.lua: Handles card position calculations and arrangements
require "vector"

local CardPositioning = {}

-- Calculate and set hand card positions
function CardPositioning:positionHandCards(playerHand, opponentHand, screenWidth, screenHeight, cardHeight)
    local cardSpacing = 110
    
    -- Calculate player hand position
    local playerHandWidth = #playerHand * cardSpacing
    local playerHandStartX = (screenWidth - playerHandWidth) / 2
    local playerHandY = screenHeight - cardHeight - 80
    
    -- Set player hand positions
    for i, card in ipairs(playerHand) do
        card.position = Vector(playerHandStartX + (i-1) * cardSpacing, playerHandY)
    end
    
    -- Calculate opponent hand position
    local opponentHandWidth = #opponentHand * cardSpacing
    local opponentHandStartX = (screenWidth - opponentHandWidth) / 2
    local opponentHandY = 20
    
    -- Set opponent hand positions
    for i, card in ipairs(opponentHand) do
        card.position = Vector(opponentHandStartX + (i-1) * cardSpacing, opponentHandY)
    end
end

-- Check if card is in a valid drop zone
function CardPositioning:checkCardDropZones(card, screenWidth, screenHeight, cardWidth, cardHeight)
    -- Card center position
    local cardCenterX = card.position.x + cardWidth / 2
    local cardCenterY = card.position.y + cardHeight / 2
    
    -- Calculate location areas
    local locationWidth = 400
    local locationHeight = 350
    local spacing = 20
    local totalWidth = 3 * locationWidth + 2 * spacing
    local startX = (screenWidth - totalWidth) / 2
    local centerY = screenHeight / 2
    
    -- Check each of the 3 location areas
    for i = 1, 3 do
        local locationX = startX + (i - 1) * (locationWidth + spacing)
        local locationY = centerY - locationHeight / 2
        
        -- Check if card is within this location area
        if cardCenterX >= locationX and cardCenterX <= locationX + locationWidth and
           cardCenterY >= locationY and cardCenterY <= locationY + locationHeight then
            
            -- Determine if it's in player area or opponent area
            local isPlayerArea = cardCenterY > centerY
            
            if isPlayerArea then
                -- Check which of the 4 player slots
                local slotY = locationY + locationHeight - 150
                local slotSpacing = 10
                local slotWidth = (locationWidth - 5 * slotSpacing) / 4
                
                for slot = 1, 4 do
                    local slotX = locationX + slotSpacing + (slot - 1) * (slotWidth + slotSpacing)
                    
                    if cardCenterX >= slotX and cardCenterX <= slotX + slotWidth and
                       cardCenterY >= slotY and cardCenterY <= slotY + cardHeight + 10 then
                        return i, slot, true  -- location, slot, isPlayer
                    end
                end
            end
        end
    end
    
    return nil  -- Not in a valid drop zone
end

-- Calculate game location dimensions and position info
function CardPositioning:getLocationDimensions(screenWidth, screenHeight)
    local locationWidth = 400
    local locationHeight = 350
    local spacing = 20
    local totalWidth = 3 * locationWidth + 2 * spacing
    local startX = (screenWidth - totalWidth) / 2
    local centerY = screenHeight / 2
    
    return {
        locationWidth = locationWidth,
        locationHeight = locationHeight,
        spacing = spacing,
        startX = startX,
        centerY = centerY
    }
end

-- Calculate slot position
function CardPositioning:getSlotPosition(locationIndex, slotIndex, isOpponent, screenWidth, screenHeight, cardWidth, cardHeight)
    local dims = self:getLocationDimensions(screenWidth, screenHeight)
    
    local locationX = dims.startX + (locationIndex - 1) * (dims.locationWidth + dims.spacing)
    local locationY = dims.centerY - dims.locationHeight / 2
    
    local slotSpacing = 10
    local slotWidth = (dims.locationWidth - 5 * slotSpacing) / 4
    local slotHeight = cardHeight + 10
    
    local slotX = locationX + slotSpacing + (slotIndex - 1) * (slotWidth + slotSpacing)
    local slotY
    
    if isOpponent then
        slotY = locationY + 50
    else
        slotY = locationY + dims.locationHeight - 150
    end
    
    -- Return card position with slight right offset and better centering
    local cardOffsetX = (slotWidth - cardWidth) / 2 + 5
    local cardOffsetY = (slotHeight - cardHeight) / 2
    return Vector(slotX + cardOffsetX, slotY + cardOffsetY)
end

return CardPositioning 