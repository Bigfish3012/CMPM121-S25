-- resourceManager.lua: Unified game resource management to avoid duplicate loading
local ResourceManager = {}

-- Image cache
local imageCache = {}
local fontCache = {}

-- Load image
function ResourceManager:loadImage(imagePath)
    if imageCache[imagePath] then
        return imageCache[imagePath]
    end
    
    local success, image = pcall(love.graphics.newImage, imagePath)
    if success then
        imageCache[imagePath] = image
        return image
    else
        print("Warning: Could not load image at path: " .. imagePath)
        return nil
    end
end

-- Load font
function ResourceManager:loadFont(fontPath, fontSize)
    local fontKey = fontPath .. "_" .. fontSize
    if fontCache[fontKey] then
        return fontCache[fontKey]
    end
    
    local success, font = pcall(love.graphics.newFont, fontPath, fontSize)
    if success then
        fontCache[fontKey] = font
        return font
    else
        print("Warning: Could not load font at path: " .. fontPath .. " size: " .. fontSize)
        return love.graphics.newFont(fontSize)
    end
end

-- Preload common resources
function ResourceManager:preloadCommonResources()
    -- Preload card-related images
    self:loadImage("asset/img/card_back.png")
    self:loadImage("asset/img/Mana.png")
    self:loadImage("asset/img/emptyMana.png")
    
    -- Preload common fonts
    self:loadFont("asset/fonts/game.TTF", 16)
    self:loadFont("asset/fonts/game.TTF", 20)
    self:loadFont("asset/fonts/des.ttf", 14)
    self:loadFont("asset/fonts/des.ttf", 16)
    self:loadFont("asset/fonts/des.ttf", 20)
end

-- Get card back image
function ResourceManager:getCardBackImage()
    return self:loadImage("asset/img/card_back.png")
end

-- Get mana images
function ResourceManager:getManaImages()
    return {
        mana = self:loadImage("asset/img/Mana.png"),
        emptyMana = self:loadImage("asset/img/emptyMana.png")
    }
end

-- Get game font
function ResourceManager:getGameFont(size)
    return self:loadFont("asset/fonts/game.TTF", size)
end

-- Get description font
function ResourceManager:getDescriptionFont(size)
    return self:loadFont("asset/fonts/des.ttf", size)
end

return ResourceManager 