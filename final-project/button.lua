-- button.lua: Centralized button module for UI consistency

local Button = {}

-- Button constructor
function Button:new(x, y, width, height, text, options)
    local button = {}
    local metadata = {__index = Button}
    setmetatable(button, metadata)
    
    -- Basic properties
    button.x = x or 0
    button.y = y or 0
    button.width = width or 100
    button.height = height or 50
    button.text = text or ""
    
    -- Extract options or use defaults
    options = options or {}
    button.color = options.color or {0.976, 0.710, 0.447, 0.7}
    button.hoverColor = options.hoverColor or {1.0, 0.810, 0.547, 0.9}
    button.disabledColor = options.disabledColor or {0.4, 0.4, 0.4, 0.6}
    button.textColor = options.textColor or {0, 0, 0}
    button.disabledTextColor = options.disabledTextColor or {0.6, 0.6, 0.6}
    button.borderColor = options.borderColor or nil
    button.borderWidth = options.borderWidth or 0
    button.cornerRadius = options.cornerRadius or 10
    button.font = options.font or love.graphics.newFont("asset/fonts/game.TTF", 16)
    
    -- State
    button.hover = false
    button.disabled = false
    button.visible = true
    
    return button
end

-- Check if mouse is over the button
function Button:isMouseOver(mx, my)
    if not self.visible then
        return false
    end
    
    mx = mx or love.mouse.getX()
    my = my or love.mouse.getY()
    
    return mx >= self.x and mx <= self.x + self.width and 
           my >= self.y and my <= self.y + self.height
end

-- Update button hover state
function Button:updateHover(mx, my)
    self.hover = self:isMouseOver(mx, my)
end

-- Handle mouse press on button
function Button:mousepressed(x, y, mouseButton)
    if mouseButton == 1 and self:isMouseOver(x, y) and not self.disabled and self.visible then
        return true
    end
    return false
end

-- Draw the button
function Button:draw()
    if not self.visible then
        return
    end
    
    -- Determine colors based on state
    local bgColor = self.color
    local txtColor = self.textColor
    
    if self.disabled then
        bgColor = self.disabledColor
        txtColor = self.disabledTextColor
    elseif self.hover and not self.disabled then
        bgColor = self.hoverColor
    end
    
    -- Draw button background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 
                           self.cornerRadius, self.cornerRadius)
    
    -- Draw border if specified
    if self.borderColor and self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 
                               self.cornerRadius, self.cornerRadius)
    end
    
    -- Draw button text
    love.graphics.setColor(txtColor)
    love.graphics.setFont(self.font)
    love.graphics.printf(self.text, self.x, 
                        self.y + (self.height - self.font:getHeight()) / 2, 
                        self.width, "center")
end

-- Set button position
function Button:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set button size
function Button:setSize(width, height)
    self.width = width
    self.height = height
end

-- Set button text
function Button:setText(text)
    self.text = text
end

-- Enable/disable button
function Button:setDisabled(disabled)
    self.disabled = disabled
end

-- Show/hide button
function Button:setVisible(visible)
    self.visible = visible
end

-- Update button colors
function Button:setColors(color, hoverColor, textColor)
    if color then self.color = color end
    if hoverColor then self.hoverColor = hoverColor end
    if textColor then self.textColor = textColor end
end

return Button 