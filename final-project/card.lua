-- card file: for the card class

require "vector"
local CardAnimation = require "cardAnimation"
local ResourceManager = require "resourceManager"

CardClass = {}

-- Static variable to track which card needs description rendering
CardClass.cardNeedingDescription = nil

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
    
    -- Try to read the file using Love2D's filesystem
    local success, contents = pcall(love.filesystem.read, "info.txt")
    
    if not success or not contents then
        print("Error: Could not open info.txt file")
        return {}
    end
    
    -- Split contents into lines
    local lines = {}
    for line in contents:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    if #lines == 0 then
        print("Error: info.txt file is empty")
        return {}
    end    
    -- Skip the header line
    local startIndex = 2 -- Skip the first line (header)
    
    -- Read each line and parse card data
    for i = startIndex, #lines do
        local line = lines[i]
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
        print("Warning: Could not load card image for '" .. cardName .. "' at path: " .. imagePath)
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
    
    -- Initialize animation properties using the animation module
    CardAnimation:initCard(card)
    
    -- Try to load the card image
    card.image = CardClass.loadCardImage(card.name)
    
    return card
end

-- Helper function to draw mana cost icon
local function drawManaCostIcon(self)
    if self.manaCost ~= nil then
        local manaCostIcon = CardClass.loadManaCostIcon(self.manaCost)
        if manaCostIcon then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(manaCostIcon, self.position.x + 5, self.position.y + 5)
        end
    end
end

-- Helper function to draw power icon
local function drawPowerIcon(self)
    if self.power ~= nil then
        local powerIcon = CardClass.loadPowerIcon(self.power)
        if powerIcon then
            love.graphics.setColor(1, 1, 1, 1)
            local iconX = self.position.x + (self.image and self.image:getWidth() or 100) - powerIcon:getWidth() - 5
            love.graphics.draw(powerIcon, iconX, self.position.y + 5)
        end
    end
end

-- Helper function to draw highlight border
local function drawHighlightBorder(self, width, height)
    if self.state == CARD_STATE.MOUSE_OVER or self.state == CARD_STATE.GRABBED then
        love.graphics.setColor(1, 0.8, 0, 0.5)
        love.graphics.setLineWidth(self.faceUp and 5 or 3)
        love.graphics.rectangle("line", self.position.x, self.position.y, width, height, 8, 8)
    end
end

-- Helper function to draw face-up card
local function drawFaceUpCard(self)
    if self.image then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.image, self.position.x, self.position.y)
        
        drawManaCostIcon(self)
        drawPowerIcon(self)
        drawHighlightBorder(self, self.image:getWidth(), self.image:getHeight())
    else
        -- Draw placeholder
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.rectangle("fill", self.position.x, self.position.y, 100, 150, 8, 8)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(love.graphics.newFont("asset/fonts/game.TTF", 12))
        love.graphics.print(self.name, self.position.x + 10, self.position.y + 60)
        
        drawManaCostIcon(self)
        drawPowerIcon(self)
        drawHighlightBorder(self, 100, 150)
    end
end

-- Helper function to draw face-down card
local function drawFaceDownCard(self)
    local cardBackImage = ResourceManager:getCardBackImage()
    if cardBackImage then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(cardBackImage, self.position.x, self.position.y)
        drawHighlightBorder(self, cardBackImage:getWidth(), cardBackImage:getHeight())
    end
end

function CardClass:draw()
    -- Store original color to restore later
    local originalR, originalG, originalB, originalA = love.graphics.getColor()
    
    if self.faceUp then
        drawFaceUpCard(self)
    else
        drawFaceDownCard(self)
    end
    
    -- Restore original color
    love.graphics.setColor(originalR, originalG, originalB, originalA)
    
    -- Set this card as needing description rendering if it's being hovered
    if self.state == CARD_STATE.MOUSE_OVER then
        CardClass.cardNeedingDescription = self
    end
end

-- Helper function to get card dimensions
local function getCardDimensions(self)
    if self.faceUp and self.image then
        return self.image:getWidth(), self.image:getHeight()
    elseif not self.faceUp then
        local cardBackImage = ResourceManager:getCardBackImage()
        if cardBackImage then
            return cardBackImage:getWidth(), cardBackImage:getHeight()
        end
    end
    return 100, 120  -- Default dimensions
end

-- Helper function to check if mouse is over card
local function isMouseOverCard(self, mousePos, width, height)
    return mousePos.x > self.position.x and 
           mousePos.x < self.position.x + width and 
           mousePos.y > self.position.y and
           mousePos.y < self.position.y + height
end

function CardClass:checkForMouseOver(grabber)
    -- Skip check if card is already grabbed
    if self.state == CARD_STATE.GRABBED then
        return
    end
    
    local mousePos = grabber.currentMousePos
    if not mousePos then return end
    
    local cardWidth, cardHeight = getCardDimensions(self)
    local isMouseOver = isMouseOverCard(self, mousePos, cardWidth, cardHeight)
    
    -- Update card state based on mouse position
    self.state = isMouseOver and CARD_STATE.MOUSE_OVER or CARD_STATE.IDLE
end

-- Helper function to calculate description box position
local function calculateDescriptionBoxPosition(mouseX, mouseY, boxWidth, boxHeight)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local boxX = mouseX + 20
    local boxY = mouseY - boxHeight / 2
    
    -- Keep the box within screen bounds
    if boxX + boxWidth > screenWidth then
        boxX = mouseX - boxWidth - 20
    end
    
    boxY = math.max(0, math.min(boxY, screenHeight - boxHeight))
    
    return boxX, boxY
end

-- Helper function to draw description background
local function drawDescriptionBackground(boxX, boxY, boxWidth, boxHeight)
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 8, 8)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 8, 8)
end

-- Helper function to draw description text
local function drawDescriptionText(self, boxX, boxY, boxWidth, padding)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Card name
    love.graphics.setFont(ResourceManager:getDescriptionFont(20))
    love.graphics.print(self.name, boxX + padding, boxY + padding)

    -- Stats
    love.graphics.setFont(ResourceManager:getDescriptionFont(16))
    local statsY = boxY + padding + 25
    local statsText = "Mana: " .. (self.manaCost or "?") .. "  Power: " .. (self.power or "?")
    love.graphics.print(statsText, boxX + padding, statsY)
    
    -- Description text
    love.graphics.setFont(ResourceManager:getDescriptionFont(14))
    local textY = boxY + padding + 55
    local wrappedText = love.graphics.newText(love.graphics.getFont())
    wrappedText:setf(self.text or "", boxWidth - padding * 2, "left")
    love.graphics.draw(wrappedText, boxX + padding, textY)
end

function CardClass:description()    
    -- Only show description for face up cards that are being hovered over
    if not self.faceUp or self.state ~= CARD_STATE.MOUSE_OVER then
        self.hoverStartTime = nil
        return
    end
    
    -- Initialize hover start time if this is the first frame of hovering
    if not self.hoverStartTime then
        self.hoverStartTime = love.timer.getTime()
        return
    end
    
    -- Only show description after 0.5 seconds of hovering
    local hoverDuration = love.timer.getTime() - self.hoverStartTime
    if hoverDuration < 0.5 then
        return
    end
    
    -- Get mouse position and box dimensions
    local mouseX, mouseY = love.mouse.getPosition()
    local boxWidth, boxHeight = 300, 180
    local padding = 15
    
    local boxX, boxY = calculateDescriptionBoxPosition(mouseX, mouseY, boxWidth, boxHeight)
    
    -- Store original color
    local originalR, originalG, originalB, originalA = love.graphics.getColor()
    
    drawDescriptionBackground(boxX, boxY, boxWidth, boxHeight)
    drawDescriptionText(self, boxX, boxY, boxWidth, padding)
    
    -- Restore original color
    love.graphics.setColor(originalR, originalG, originalB, originalA)
end

-- Add a static method to draw descriptions on top of everything
function CardClass.drawDescriptions()
    if CardClass.cardNeedingDescription then
        CardClass.cardNeedingDescription:description()
        CardClass.cardNeedingDescription = nil  -- Reset for next frame
    end
end

-- Animation methods
function CardClass:startAnimation(targetX, targetY, duration)
    CardAnimation:startAnimation(self, targetX, targetY, duration)
end

function CardClass:updateAnimation()
    return CardAnimation:updateAnimation(self)
end

function CardClass:isCurrentlyAnimating()
    return CardAnimation:isAnimating(self)
end

function CardClass:setAnimationCallback(callback)
    CardAnimation:setCompletionCallback(self, callback)
end