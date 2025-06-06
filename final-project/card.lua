-- card file: for the card class

require "vector"

CardClass = {}

CARD_STATE = {
    IDLE = 0,
    MOUSE_OVER = 1,
    GRABBED = 2
}

local cardImages = {}
local powerIcons = {}
local manaCostIcons = {}

-- Function to load card information from info.txt
local function loadCardInfo()
    local cardInfo = {}
        local possiblePaths = {
        "info.txt",
        "project3/info.txt",
        "./info.txt"
    }
    
    local file = nil
    local usedPath = nil
    
    for _, path in ipairs(possiblePaths) do
        file = io.open(path, "r")
        if file then
            usedPath = path
            break
        end
    end
    
    if not file then
        print("Error: Could not open info.txt file! Tried paths:")
        for _, path in ipairs(possiblePaths) do
            print("  - " .. path)
        end
        return {}
    end    
    -- Skip the header line
    local header = file:read("*line")
    
    -- Read each line and parse card data
    for line in file:lines() do
        if line and line ~= "" then
            -- Split by tab characters
            local parts = {}
            for part in line:gmatch("[^\t]+") do
                table.insert(parts, part)
            end
            
            if #parts >= 4 then
                local name = parts[1]
                local manaCost = tonumber(parts[2]) or 0
                local power = tonumber(parts[3]) or 0
                local text = parts[4] or ""
                
                cardInfo[name] = {
                    name = name,
                    manaCost = manaCost,
                    power = power,
                    text = text
                }
            end
        end
    end
    
    file:close()
    return cardInfo
end

-- Load card information from file
CARD_INFO = loadCardInfo()

-- Load card image
function CardClass.loadCardImage(cardName)
    -- if the image is already loaded, return it
    if cardImages[cardName] then
        return cardImages[cardName]
    end
    
    -- load the card image with error handling
    local imagePath = "asset/sp/" .. cardName .. ".png"
    local success, image = pcall(love.graphics.newImage, imagePath)
    
    if success then
        cardImages[cardName] = image
        return image
    else
        
        cardImages[cardName] = nil
        return nil
    end
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
            -- If there's no image, draw a simple placeholder
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.rectangle("fill", self.position.x, self.position.y, 100, 150, 8, 8)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setFont(love.graphics.newFont("asset/fonts/game.TTF", 12))
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
        if not CardClass.cardBackImage then
            CardClass.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(CardClass.cardBackImage, self.position.x, self.position.y)
        
        -- Only draw the highlight border when mouse is hovering or grabbing
        if self.state == CARD_STATE.MOUSE_OVER or self.state == CARD_STATE.GRABBED then
            love.graphics.setColor(1, 0.8, 0, 0.5) -- Semi-transparent highlight border
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", self.position.x, self.position.y, 
                                  CardClass.cardBackImage:getWidth(), CardClass.cardBackImage:getHeight(), 8, 8)
        end
    end
    
    -- Show card description (when mouse is hovering)
    if self.state == CARD_STATE.MOUSE_OVER then
        self:description()
    end
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
    local boxX = mouseX + 20
    local boxY = mouseY - boxHeight / 2
    
    -- Keep the box within screen bounds
    if boxX + boxWidth > screenWidth then
        boxX = mouseX - boxWidth - 20
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
    love.graphics.setFont(love.graphics.newFont("asset/fonts/des.ttf", 14))
    love.graphics.print(self.name, boxX + padding, boxY + padding)

    -- Mana cost and power information
    love.graphics.setFont(love.graphics.newFont("asset/fonts/des.ttf", 12))
    local statsY = boxY + padding + 20
    local statsText = "Mana: " .. (self.manaCost or "?") .. "  Power: " .. (self.power or "?")
    love.graphics.print(statsText, boxX + padding, statsY)
    
    -- Card text/description
    love.graphics.setFont(love.graphics.newFont("asset/fonts/des.ttf", 10))
    local textY = boxY + padding + 45
    
    -- Wrap text to fit in the box
    local wrappedText = love.graphics.newText(love.graphics.getFont())
    wrappedText:setf(self.text or "", boxWidth - padding * 2, "left")
    love.graphics.draw(wrappedText, boxX + padding, textY)
    
    -- Reset font
    love.graphics.setFont(love.graphics.getFont())
end

function CardClass:mouseOver(x, y)    
    -- Skip check if card is already grabbed
    if self.state == CARD_STATE.GRABBED then
        return false
    end
    
    -- Get card dimensions based on whether it's face up or face down
    local cardWidth, cardHeight
    
    if self.faceUp and self.image then
        cardWidth = self.image:getWidth()
        cardHeight = self.image:getHeight()
    elseif not self.faceUp and CardClass.cardBackImage then
        cardWidth = CardClass.cardBackImage:getWidth()
        cardHeight = CardClass.cardBackImage:getHeight()
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