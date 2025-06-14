-- turns.lua: Handles turn-based game logic and animation

local TurnManager = {}

-- Turn animation states
TurnManager.state = "waiting"  -- waiting, showing_turn, player_turn, ai_turn, ai_playing, revealing
TurnManager.animationStartTime = 0
TurnManager.animationDuration = 0
TurnManager.currentTurnText = ""
TurnManager.font = nil
TurnManager.isPlayerTurn = true
TurnManager.nextStateTimer = nil

-- Animation settings
TurnManager.PLAYER_TURN_DURATION = 2.0  -- Show "Your Turn" for 2 seconds
TurnManager.AI_TURN_DURATION = 1.0      -- Show "Opponent Turn" for 1 second
TurnManager.REVEAL_DURATION = 1.5       -- Show reveal animation

-- Colors for different turn types
TurnManager.colors = {
    player = {0.2, 0.8, 0.2, 1.0},     -- Green for player turn
    opponent = {0.8, 0.2, 0.2, 1.0},   -- Red for opponent turn
    reveal = {0.8, 0.8, 0.2, 1.0}      -- Yellow for reveal
}

-- Initialize the turn manager
function TurnManager:init()
    self.state = "waiting"
    self.font = love.graphics.newFont("asset/fonts/game.TTF", 48)
    self.isPlayerTurn = true
end

-- Start a new turn cycle
function TurnManager:startPlayerTurn()
    self.state = "showing_turn"
    self.currentTurnText = "Your Turn"
    self.animationStartTime = love.timer.getTime()
    self.animationDuration = self.PLAYER_TURN_DURATION
    self.isPlayerTurn = true
end

-- Start opponent turn
function TurnManager:startOpponentTurn()
    self.state = "showing_turn"
    self.currentTurnText = "Opponent Turn"
    self.animationStartTime = love.timer.getTime()
    self.animationDuration = self.AI_TURN_DURATION
    self.isPlayerTurn = false
end

-- Start reveal phase
function TurnManager:startRevealPhase()
    self.state = "showing_turn"
    self.currentTurnText = "Revealing Cards..."
    self.animationStartTime = love.timer.getTime()
    self.animationDuration = self.REVEAL_DURATION
end

-- Update turn animations
function TurnManager:update(dt, gameBoard, gameLogic)
    if self.state == "showing_turn" then
        local elapsed = love.timer.getTime() - self.animationStartTime
        
        if elapsed >= self.animationDuration then
            -- Animation finished, transition to next state
            if self.currentTurnText == "Your Turn" then
                self.state = "player_turn"
                -- Player draws card at start of their turn
                if gameLogic then
                    gameLogic:drawCards()  -- This now only draws for player
                end
                -- Player can now interact with the game
            elseif self.currentTurnText == "Opponent Turn" then
                self.state = "ai_turn"
                -- AI draws cards and makes its moves
                if gameLogic then
                    -- AI draws card first (during opponent turn)
                    gameLogic.ai:drawCard(gameLogic.gameBoard)
                    gameLogic.gameBoard:positionHandCards()
                    
                    -- Wait for draw animation to complete before placing cards
                    self:scheduleAIPlay(gameLogic)
                end
            elseif self.currentTurnText == "Revealing Cards..." then
                self.state = "revealing"
                -- Now that the "Revealing Cards..." animation is complete, start revealing cards
                if gameLogic then
                    gameLogic:flipCardsAndTriggerEffects()
                    -- Note: Don't call completeRevealPhase and scheduleNextTurn here!
                    -- These will be called when all cards are revealed
                end
            end
        end
    elseif self.state == "ai_turn" and self.nextStateTimer then
        -- Handle delayed state transitions (waiting for draw animation)
        self.nextStateTimer = self.nextStateTimer - dt
        if self.nextStateTimer <= 0 then
            self.nextStateTimer = nil
            self.state = "ai_playing"
            if gameLogic then
                -- Now AI can play cards after draw animation completed
                gameLogic:playAITurn()
                -- Schedule transition to reveal phase after AI finishes playing
                self:scheduleRevealPhase(gameLogic)
            end
        end
    elseif self.state == "ai_playing" and self.nextStateTimer then
        -- Handle delayed state transitions (waiting for AI to finish playing)
        self.nextStateTimer = self.nextStateTimer - dt
        if self.nextStateTimer <= 0 then
            self.nextStateTimer = nil
            if gameLogic then
                gameLogic.ai:submitTurn()
                gameLogic:startRevealPhase()
            end
        end
    elseif self.state == "revealing" then
        -- Check if all cards have been revealed
        if gameLogic and gameLogic.allCardRevealed then
            -- All cards revealed, complete the reveal phase
            if not self.nextStateTimer then
                -- First time entering this state, complete reveal phase and schedule next turn
                gameLogic:completeRevealPhase()
                self:scheduleNextTurn()
            end
            
            -- Handle delayed state transitions after reveal
            if self.nextStateTimer then
                self.nextStateTimer = self.nextStateTimer - dt
                if self.nextStateTimer <= 0 then
                    self.nextStateTimer = nil
                    if gameLogic then
                        gameLogic:startNextTurn()
                        self:startPlayerTurn()
                    end
                end
            end
        end
    end
end

-- Check if player can interact (place cards, submit turn, etc.)
function TurnManager:canPlayerInteract()
    return self.state == "player_turn"
end

-- Check if AI can interact
function TurnManager:canAIInteract()
    return self.state == "ai_turn" or self.state == "ai_playing"
end

-- Handle player turn submission
function TurnManager:submitPlayerTurn(gameLogic)
    if self.state == "player_turn" then
        -- Player has submitted their turn
        if gameLogic then
            gameLogic.player:submitTurn()
        end
        -- Start opponent turn
        self:startOpponentTurn()
    end
end

-- Draw turn animation
function TurnManager:draw(screenWidth, screenHeight)
    if self.state == "showing_turn" then
        -- Calculate animation progress
        local elapsed = love.timer.getTime() - self.animationStartTime
        local progress = math.min(elapsed / self.animationDuration, 1.0)
        
        -- Animation effects
        local alpha = 1.0
        local scale = 1.0
        
        -- Fade in/out effect
        if progress < 0.2 then
            alpha = progress / 0.2
            scale = 0.8 + (progress / 0.2) * 0.2
        elseif progress > 0.8 then
            alpha = (1.0 - progress) / 0.2
            scale = 1.0 + (progress - 0.8) / 0.2 * 0.1
        end
        
        -- Set color based on turn type
        local color = self.colors.player
        if self.currentTurnText == "Opponent Turn" then
            color = self.colors.opponent
        elseif self.currentTurnText == "Revealing Cards..." then
            color = self.colors.reveal
        end
        
        -- Draw background overlay
        love.graphics.setColor(0, 0, 0, 0.5 * alpha)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        
        -- Draw turn text
        love.graphics.setFont(self.font)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        
        local text = self.currentTurnText
        local textWidth = self.font:getWidth(text)
        local textHeight = self.font:getHeight()
        
        local x = (screenWidth - textWidth * scale) / 2
        local y = (screenHeight - textHeight * scale) / 2
        
        -- Draw text with scaling
        love.graphics.push()
        love.graphics.translate(x + textWidth * scale / 2, y + textHeight * scale / 2)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-textWidth / 2, -textHeight / 2)
        love.graphics.print(text, 0, 0)
        love.graphics.pop()
        
        -- Draw decorative border
        love.graphics.setColor(1, 1, 1, alpha * 0.8)
        love.graphics.setLineWidth(3)
        local borderWidth = textWidth * scale + 40
        local borderHeight = textHeight * scale + 20
        local borderX = (screenWidth - borderWidth) / 2
        local borderY = (screenHeight - borderHeight) / 2
        love.graphics.rectangle("line", borderX, borderY, borderWidth, borderHeight, 10, 10)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Get current state
function TurnManager:getState()
    return self.state
end

-- Check if animation is playing
function TurnManager:isAnimating()
    return self.state == "showing_turn"
end

-- Schedule AI card playing after draw animation
function TurnManager:scheduleAIPlay(gameLogic)
    self.nextStateTimer = 0.9  -- Wait slightly longer than AI draw animation (0.8s)
end

-- Schedule reveal phase after AI turn
function TurnManager:scheduleRevealPhase(gameLogic)
    self.nextStateTimer = 1.0  -- Give AI animations enough time to complete
end

-- Schedule next turn after reveal
function TurnManager:scheduleNextTurn()
    self.nextStateTimer = 1.0  -- Brief pause after reveal
end

-- Stop all turn animations (called when game ends)
function TurnManager:stopAllAnimations()
    self.state = "waiting"
    self.animationStartTime = 0
    self.animationDuration = 0
    self.currentTurnText = ""
    self.nextStateTimer = nil
end

return TurnManager