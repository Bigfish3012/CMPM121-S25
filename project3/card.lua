-- card file: for the card class

require "vector"

CardClass = {}

CARD_STATE = {
    IDLE = 0,
    MOUSE_OVER = 1,
    GRABBED = 2
}

-- Card image cache to avoid repeated loading
local cardImages = {}
-- Power and mana cost icon caches
local powerIcons = {}
local manaCostIcons = {}

CARD_INFO = {
    -- Format: {card name, mana cost, power value, description text}
    ["Wooden Cow"] = {name = "Wooden Cow", manaCost = 1, power = 1, text = "Vanilla"},
    ["Pegasus"] = {name = "Pegasus", manaCost = 3, power = 5, text = "Vanilla"},
    ["Minotaur"] = {name = "Minotaur", manaCost = 5, power = 9, text = "Vanilla"},
    ["Zeus"] = {name = "Zeus", manaCost = 4, power = 4, text = "When Revealed: Lower the power of each card in your opponent's hand by 1."},
    ["Ares"] = {name = "Ares", manaCost = 3, power = 3, text = "When Revealed: Gain +2 power for each enemy card here."},
    ["Cyclops"] = {name = "Cyclops", manaCost = 3, power = 5, text = "When Revealed: Discard your other cards here, gain +2 power for each discarded."},
}

-- Load card image
function CardClass.loadCardImage(cardName)
    -- if the image is already loaded, return it
    if cardImages[cardName] then
        return cardImages[cardName]
    end
    
    -- load the card image
    local imagePath = "asset/sp/" .. cardName .. ".png"
    local image = love.graphics.newImage(imagePath)
    cardImages[cardName] = image
    return image
end

-- Load power icon
function CardClass.loadPowerIcon(powerValue)
    -- Clamp power value to 0-9 range
    local iconIndex = math.max(0, math.min(9, powerValue))
    local iconKey = string.format("%02d", iconIndex)
    
    if powerIcons[iconKey] then
        return powerIcons[iconKey]
    end
    
    local imagePath = "asset/power/" .. iconKey .. ".png"
    local image = love.graphics.newImage(imagePath)
    powerIcons[iconKey] = image
    return image
end

-- Load mana cost icon
function CardClass.loadManaCostIcon(manaCost)
    -- Clamp mana cost to 0-9 range
    local iconIndex = math.max(0, math.min(9, manaCost))
    local iconKey = string.format("%02d", iconIndex)
    
    if manaCostIcons[iconKey] then
        return manaCostIcons[iconKey]
    end
    
    local imagePath = "asset/manaCost/" .. iconKey .. ".png"
    local image = love.graphics.newImage(imagePath)
    manaCostIcons[iconKey] = image
    return image
end

function CardClass:new(xPos, yPos, name, power, manaCost, text, faceUp)
    local card = {}
    local metadata = {__index = CardClass}
    setmetatable(card, metadata)
    
    card.position = Vector(xPos, yPos)
    card.state = CARD_STATE.IDLE
    card.name = name or "Card"
    card.power = power
    card.manaCost = manaCost
    card.text = text
    card.faceUp = faceUp or false
    card.canDrag = false
    
    -- Try to load the card image
    card.image = CardClass.loadCardImage(card.name)
    
    return card
end

function CardClass:update()
    -- Card-specific update logic can be added here
    -- Position update for grabbed cards is now handled by the grabber
end

function CardClass:draw()
    if self.faceUp then
        -- Draw the front of the card
        if self.image then
            -- Draw the image at its original size (without scaling)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.image, self.position.x, self.position.y)
            
            -- Draw mana cost icon in the top-left corner
            if self.manaCost ~= nil then
                local manaCostIcon = CardClass.loadManaCostIcon(self.manaCost)
                if manaCostIcon then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(manaCostIcon, self.position.x + 5, self.position.y + 5)
                end
            end
            
            -- Draw power icon in the top-right corner
            if self.power ~= nil then
                local powerIcon = CardClass.loadPowerIcon(self.power)
                if powerIcon then
                    love.graphics.setColor(1, 1, 1, 1)
                    local iconX = self.position.x + self.image:getWidth() - powerIcon:getWidth() - 5
                    love.graphics.draw(powerIcon, iconX, self.position.y + 5)
                end
            end
            
            -- Only draw the highlight border when mouse is hovering or grabbing
            if self.state == CARD_STATE.MOUSE_OVER or self.state == CARD_STATE.GRABBED then
                love.graphics.setColor(1, 0.8, 0, 0.5) -- Semi-transparent highlight border
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", self.position.x, self.position.y, 
                                      self.image:getWidth(), self.image:getHeight(), 8, 8)
            end
        else
            -- If there's no image, draw a simple placeholder (for development only)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.rectangle("fill", self.position.x, self.position.y, 100, 150, 8, 8)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setFont(love.graphics.newFont(12))
            love.graphics.print(self.name, self.position.x + 10, self.position.y + 60)
            
            -- Draw mana cost and power icons even for placeholder cards
            if self.manaCost ~= nil then
                local manaCostIcon = CardClass.loadManaCostIcon(self.manaCost)
                if manaCostIcon then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(manaCostIcon, self.position.x + 5, self.position.y + 5)
                end
            end
            
            if self.power ~= nil then
                local powerIcon = CardClass.loadPowerIcon(self.power)
                if powerIcon then
                    love.graphics.setColor(1, 1, 1, 1)
                    local iconX = self.position.x + 100 - powerIcon:getWidth() - 5
                    love.graphics.draw(powerIcon, iconX, self.position.y + 5)
                end
            end
        end
    else
        -- Draw the back of the card
        -- Make sure the card back image is loaded
        if not self.cardBackImage then
            -- Try to get the image from gameBoard
            if gameBoard and gameBoard.cardBackImage then
                self.cardBackImage = gameBoard.cardBackImage
            else
                -- Load directly as a fallback
                self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
            end
        end
        
        -- Draw the card back at its original size (without scaling)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.cardBackImage, self.position.x, self.position.y)
        
        -- Only draw the highlight border when mouse is hovering or grabbing
        if self.state == CARD_STATE.MOUSE_OVER or self.state == CARD_STATE.GRABBED then
            love.graphics.setColor(1, 0.8, 0, 0.5) -- Semi-transparent highlight border
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", self.position.x, self.position.y, 
                                  self.cardBackImage:getWidth(), self.cardBackImage:getHeight(), 8, 8)
        end
    end
    
    -- Show card description (when mouse is hovering)
    if self.state == CARD_STATE.MOUSE_OVER then
        self:description()
    end
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
function CardClass:getName()
    return self.name
end

function CardClass:checkForMouseOver(grabber)
    -- Skip check if card is already grabbed
    if self.state == CARD_STATE.GRABBED then
        return
    end
    
    local mousePos = grabber.currentMousePos
    if not mousePos then return end
    
    -- Use the mouseOver method to check if mouse is over this card
    local isMouseOver = self:mouseOver(mousePos.x, mousePos.y)
    
    -- Update card state based on mouse position
    self.state = isMouseOver and CARD_STATE.MOUSE_OVER or CARD_STATE.IDLE
end

function CardClass:description()
    -- when the card is face up, and the mouse is over the card, show the description:
    -- Draw the a description box on the right side of the mouse, but also ensure that it is within the screen bounds
    
    -- Only show description for face up cards that are being hovered over
    if not self.faceUp or self.state ~= CARD_STATE.MOUSE_OVER then
        -- Reset hover timer if not hovering
        self.hoverStartTime = nil
        return
    end
    
    -- Initialize hover start time if this is the first frame of hovering
    if not self.hoverStartTime then
        self.hoverStartTime = love.timer.getTime()
        return
    end
    
    -- Calculate how long the mouse has been hovering
    local hoverDuration = love.timer.getTime() - self.hoverStartTime
    
    -- Only show description after 2 seconds of hovering
    if hoverDuration < 2 then
        return
    end
    
    -- Get mouse position
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- Box dimensions
    local boxWidth = 200
    local boxHeight = 120
    local padding = 10
    
    -- Position the box to the right of the mouse, but keep it on screen
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local boxX = mouseX + 20 -- 20 pixels to the right of mouse
    local boxY = mouseY - boxHeight / 2 -- Centered vertically with mouse
    
    -- Keep the box within screen bounds
    if boxX + boxWidth > screenWidth then
        boxX = mouseX - boxWidth - 20 -- Place on left side of mouse if too close to right edge
    end
    
    if boxY < 0 then
        boxY = 0
    elseif boxY + boxHeight > screenHeight then
        boxY = screenHeight - boxHeight
    end
    
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 8, 8)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 8, 8)
    
    -- Draw card information
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Card name (title)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print(self.name, boxX + padding, boxY + padding)

    -- Mana cost and power information
    love.graphics.setFont(love.graphics.newFont(12))
    local statsY = boxY + padding + 20
    local statsText = "Mana: " .. (self.manaCost or "?") .. "  Power: " .. (self.power or "?")
    love.graphics.print(statsText, boxX + padding, statsY)
    
    -- Card text/description
    love.graphics.setFont(love.graphics.newFont(10))
    local textY = boxY + padding + 45
    
    -- Wrap text to fit in the box
    local wrappedText = love.graphics.newText(love.graphics.getFont())
    wrappedText:setf(self.text or "", boxWidth - padding * 2, "left")
    love.graphics.draw(wrappedText, boxX + padding, textY)
    
    -- Reset font
    love.graphics.setFont(love.graphics.getFont())
end

function CardClass:mouseOver(x, y)
    -- Check if mouse position (x, y) is over this card
    
    -- Skip check if card is already grabbed
    if self.state == CARD_STATE.GRABBED then
        return false
    end
    
    -- Get card dimensions based on whether it's face up or face down
    local cardWidth, cardHeight
    
    if self.faceUp and self.image then
        cardWidth = self.image:getWidth()
        cardHeight = self.image:getHeight()
    elseif not self.faceUp and self.cardBackImage then
        cardWidth = self.cardBackImage:getWidth()
        cardHeight = self.cardBackImage:getHeight()
    else
        -- Default dimensions if no image is available
        cardWidth = 100
        cardHeight = 120
    end
    
    -- Check if mouse is over this card
    local isOver = x > self.position.x and 
           x < self.position.x + cardWidth and 
           y > self.position.y and
           y < self.position.y + cardHeight
    
    return isOver
end