-- inputManager.lua: Centralized input handling
local InputManager = {}

-- Handle mouse press events
function InputManager:handleMousePressed(x, y, button, currentScreen, gameEnded, screens, gameBoard, GameLogic, AudioManager)
    -- First check if setting box is interacted with
    if screens.settingBox.visible then
        local result = screens.settingBox:mousepressed(x, y, button)
        if result == "restart" then
            AudioManager:playbutton1(function()
                screens.initializeGame()
                AudioManager:switchMusic("game")
            end)
            return "game"
        elseif result == "title" then
            AudioManager:playbutton2(function()
                screens.initializeGame()
                AudioManager:switchMusic("title")
            end)
            return "title"
        elseif result == "quit" then
            AudioManager:playbutton2(function()
                love.event.quit()
            end)
            return currentScreen
        elseif result == "close" then
            AudioManager:playbutton2(function()
                -- Just close the dialog, no other action needed
            end)
            return currentScreen
        end
    end
    
    -- Then check if game over box is interacted with
    if screens.gameOverBox.visible then
        local result = screens.gameOverBox:mousepressed(x, y, button)
        if result == "title" then
            AudioManager:playbutton2(function()
                screens.initializeGame()
                AudioManager:switchMusic("title")
            end)
            return "title"
        elseif result == "restart" then
            AudioManager:playbutton1(function()
                screens.initializeGame()
                AudioManager:switchMusic("game")
            end)
            return "game"
        elseif result == "quit" then
            AudioManager:playbutton2(function()
                love.event.quit()
            end)
            return currentScreen
        end
    end
    
    -- Process other screens if no overlay is visible or was not interacted with
    if currentScreen == "title" then
        local result = screens.titleScreen:mousepressed(x, y, button)
        if result == "game" then
            AudioManager:playbutton1(function()
                AudioManager:switchMusic("game")
            end)
            return "game"
        elseif result == "credits" then
            AudioManager:playbutton2(function()
                AudioManager:switchMusic("credits")
            end)
            return "credits"
        elseif result == "quit" then
            AudioManager:playbutton2(function()
                love.event.quit()
            end)
        end
    elseif currentScreen == "credits" then
        local result = screens.creditScreen:mousepressed(x, y, button)
        if result == "title" then
            AudioManager:playbutton2(function()
                AudioManager:switchMusic("title")
            end)
            return "title"
        end
    elseif currentScreen == "game" and not gameEnded then
        -- Check if settings button was clicked
        if gameBoard and gameBoard:isPointInSettingsButton(x, y) then
            AudioManager:playbutton2(function()
                screens.settingBox:show()
            end)
            return currentScreen
        end
        
        -- Check if end turn button was clicked (only if player can interact)
        if gameBoard and gameBoard:isPointInEndTurnButton(x, y) then
            if GameLogic.gamePhase == "staging" and not GameLogic.player.submitted and GameLogic:canPlayerInteract() then
                AudioManager:playbutton2(function()
                    GameLogic:submitTurn()
                end)
            end
        end
    end
    
    return currentScreen
end

-- Handle mouse move events
function InputManager:handleMouseMoved(x, y, dx, dy, currentScreen, screens, gameBoard)
    -- Update setting box
    screens.settingBox:mousemoved(x, y)
    
    -- Update game over box
    screens.gameOverBox:mousemoved(x, y)
    
    -- Update other screens
    if currentScreen == "title" then
        screens.titleScreen:mousemoved(x, y)
    elseif currentScreen == "credits" then
        screens.creditScreen:mousemoved(x, y)
    elseif currentScreen == "game" then
        -- Update UI buttons in game screen
        if gameBoard and gameBoard.uiManager then
            gameBoard.uiManager:updateButtonHover(x, y)
        end
    end
end

return InputManager 