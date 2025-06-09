-- cardAnimation.lua: Handles card animation functionality
require "vector"

local CardAnimation = {}

-- Initialize animation properties for a card
function CardAnimation:initCard(card)
    card.isAnimating = false
    card.animationStartPos = nil
    card.animationTargetPos = nil
    card.animationStartTime = nil
    card.animationDuration = 0.5
    card.animationCompleteCallback = nil
    
    -- Initialize mana animation properties
    card.isManaAnimating = false
    card.manaAnimationStartAlpha = nil
    card.manaAnimationTargetAlpha = nil
    card.manaAnimationStartTime = nil
    card.manaAnimationDuration = 0.8
    card.manaAnimationCallback = nil
    card.currentAlpha = 1.0
end

-- Start an animation from current position to target position
function CardAnimation:startAnimation(card, targetX, targetY, duration)
    card.isAnimating = true
    card.animationStartPos = Vector(card.position.x, card.position.y)
    card.animationTargetPos = Vector(targetX, targetY)
    card.animationStartTime = love.timer.getTime()
    card.animationDuration = duration or 0.5
end

-- Start mana gain animation (semi-transparent to opaque)
function CardAnimation:startManaGainAnimation(card, duration)
    card.isManaAnimating = true
    card.manaAnimationStartAlpha = card.currentAlpha or 0.3
    card.manaAnimationTargetAlpha = 1.0
    card.manaAnimationStartTime = love.timer.getTime()
    card.manaAnimationDuration = duration or 0.8
    
    -- Set initial alpha if not set
    if not card.currentAlpha then
        card.currentAlpha = 0.3
    end
end

-- Start mana use animation (opaque to transparent)
function CardAnimation:startManaUseAnimation(card, duration)
    card.isManaAnimating = true
    card.manaAnimationStartAlpha = card.currentAlpha or 1.0
    card.manaAnimationTargetAlpha = 0.3
    card.manaAnimationStartTime = love.timer.getTime()
    card.manaAnimationDuration = duration or 0.8
    
    -- Set initial alpha if not set
    if not card.currentAlpha then
        card.currentAlpha = 1.0
    end
end

-- Update animation (call this in update loop)
function CardAnimation:updateAnimation(card)
    local positionAnimationRunning = self:updatePositionAnimation(card)
    local manaAnimationRunning = self:updateManaAnimation(card)
    
    return positionAnimationRunning or manaAnimationRunning
end

-- Update position animation
function CardAnimation:updatePositionAnimation(card)
    if not card.isAnimating then
        return false
    end
    
    local currentTime = love.timer.getTime()
    local elapsed = currentTime - card.animationStartTime
    local progress = elapsed / card.animationDuration
    
    if progress >= 1.0 then
        -- Animation finished
        card.position = Vector(card.animationTargetPos.x, card.animationTargetPos.y)
        card.isAnimating = false
        card.animationStartPos = nil
        card.animationTargetPos = nil
        card.animationStartTime = nil
        
        -- Call completion callback if it exists
        if card.animationCompleteCallback then
            card.animationCompleteCallback()
            card.animationCompleteCallback = nil
        end
        
        return false
    else
        -- Interpolate position using easing (ease-out cubic)
        local easedProgress = 1 - math.pow(1 - progress, 3)
        
        local x = card.animationStartPos.x + (card.animationTargetPos.x - card.animationStartPos.x) * easedProgress
        local y = card.animationStartPos.y + (card.animationTargetPos.y - card.animationStartPos.y) * easedProgress
        
        card.position = Vector(x, y)
        
        -- Add a slight arc to the animation for more visual appeal
        local arcHeight = 30
        local arcProgress = math.sin(progress * math.pi)
        card.position.y = card.position.y - arcHeight * arcProgress
        
        return true
    end
end

-- Update mana animation
function CardAnimation:updateManaAnimation(card)
    if not card.isManaAnimating then
        return false
    end
    
    local currentTime = love.timer.getTime()
    local elapsed = currentTime - card.manaAnimationStartTime
    local progress = elapsed / card.manaAnimationDuration
    
    if progress >= 1.0 then
        -- Mana animation finished
        card.currentAlpha = card.manaAnimationTargetAlpha
        card.isManaAnimating = false
        card.manaAnimationStartAlpha = nil
        card.manaAnimationTargetAlpha = nil
        card.manaAnimationStartTime = nil
        
        -- Call completion callback if it exists
        if card.manaAnimationCallback then
            card.manaAnimationCallback()
            card.manaAnimationCallback = nil
        end
        
        return false
    else
        -- Interpolate alpha using smooth easing (ease-in-out)
        local easedProgress = progress < 0.5 
            and 2 * progress * progress 
            or 1 - math.pow(-2 * progress + 2, 2) / 2
        
        card.currentAlpha = card.manaAnimationStartAlpha + 
                           (card.manaAnimationTargetAlpha - card.manaAnimationStartAlpha) * easedProgress
        
        return true
    end
end

-- Check if card is currently animating (position or mana)
function CardAnimation:isAnimating(card)
    return card.isAnimating or card.isManaAnimating
end

-- Check if card is currently doing position animation
function CardAnimation:isPositionAnimating(card)
    return card.isAnimating
end

-- Check if card is currently doing mana animation
function CardAnimation:isManaAnimating(card)
    return card.isManaAnimating
end

-- Set animation completion callback
function CardAnimation:setCompletionCallback(card, callback)
    card.animationCompleteCallback = callback
end

-- Set mana animation completion callback
function CardAnimation:setManaAnimationCallback(card, callback)
    card.manaAnimationCallback = callback
end

-- Get current alpha value for rendering
function CardAnimation:getCurrentAlpha(card)
    return card.currentAlpha or 1.0
end

-- Set current alpha value manually
function CardAnimation:setCurrentAlpha(card, alpha)
    card.currentAlpha = math.max(0, math.min(1, alpha))
end

return CardAnimation 