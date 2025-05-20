-- grabber file: for the grabber class
-- Implements card dragging functionality

require "vector"

GrabberClass = {}

function GrabberClass:new(gameBoard)
    local grabber = {}
    local metadata = {__index = GrabberClass}
    setmetatable(grabber, metadata)
    
    -- Mouse tracking
    grabber.currentMousePos = nil  -- Current mouse position
    grabber.grabPos = nil          -- Position where mouse was clicked
    grabber.dragOffset = nil       -- Offset between mouse position and card position
    
    -- Card tracking
    grabber.heldObject = nil       -- Currently held card
    grabber.gameBoard = gameBoard  -- Reference to the game board
    
    return grabber
end

function GrabberClass:update()
    -- Update mouse position
    self.currentMousePos = Vector(
        love.mouse.getX(),
        love.mouse.getY()
    )
    
    -- Handle mouse click (first frame only)
    if love.mouse.isDown(1) then
        if self.grabPos == nil then  -- First frame of click
            local mx, my = love.mouse.getPosition()
            self.grabPos = Vector(mx, my)
            print("Mouse clicked at: " .. mx .. "," .. my)
            self:grab()
        end
    else
        -- Handle mouse release
        if self.grabPos ~= nil then
            self:release()
        end
    end
    
    -- Update held card position
    if self.heldObject then
        self.heldObject.position = self.currentMousePos - self.dragOffset
    end
end

-- Reset grabber state
function GrabberClass:resetGrabState()
    if self.heldObject then
        self.heldObject.state = CARD_STATE.IDLE
    end
    self.heldObject = nil
    self.grabPos = nil
    self.dragOffset = nil
end

-- Attempt to grab a card at the current mouse position
function GrabberClass:grab()
    -- Check if game board is available
    if not self.gameBoard then 
        print("Error: gameBoard not set in grabber")
        return 
    end
    
    local mx = self.grabPos.x
    local my = self.grabPos.y
    local foundCard = false
    
    print("Attempting to grab card at: " .. mx .. "," .. my)
    
    -- Loop through all cards to find one under the mouse
    for _, card in ipairs(self.gameBoard.cards) do
        -- Check if mouse is over this card
        if card:mouseOver(mx, my) then
            foundCard = true
            
            -- Output debug info
            print("Found card at mouse position: " .. card.name)
            print("  Card state: " .. tostring(card.state))
            print("  Card canDrag: " .. tostring(card.canDrag))
            
            -- Card must be in IDLE or MOUSE_OVER state and draggable
            if (card.state == CARD_STATE.IDLE or card.state == CARD_STATE.MOUSE_OVER) and card.canDrag then
                -- Set card as held object
                self.heldObject = card
                self.heldObject.state = CARD_STATE.GRABBED
                print("Grabbed card: " .. card.name)
                
                -- Store original position for snap back if needed
                self.heldObject.originalPosition = Vector(card.position.x, card.position.y)
                
                -- Calculate drag offset (difference between mouse and card positions)
                self.dragOffset = Vector(
                    mx - card.position.x,
                    my - card.position.y
                )
                
                -- Bring card to top visually (handled by draw order in gameBoard)
                
                break
            else
                print("  Can't grab card: state=" .. tostring(card.state) .. ", canDrag=" .. tostring(card.canDrag))
            end
        end
    end
    
    if not foundCard then
        print("No card found at mouse position: " .. mx .. "," .. my)
    end
end

-- Handle card release after dragging
function GrabberClass:release()
    -- If we have a held card
    if self.heldObject then
        print("Released card: " .. self.heldObject.name)
        
        -- Check if the card is in a valid drop zone
        local validDrop = self:checkValidDropZone()
        
        if not validDrop then
            -- If not a valid drop, return card to original position
            if self.heldObject.originalPosition then
                self.heldObject.position = self.heldObject.originalPosition
                print("  Card returned to original position")
            end
        else
            print("  Card dropped in valid zone")
            -- Card stays where it was dropped
        end
    end
    
    -- Reset grabber state
    self:resetGrabState()
    
    -- Need to set grabPos to nil to allow for new grabs
    self.grabPos = nil
end

-- Check if card is dropped in a valid zone
-- This function uses the gameBoard to determine valid drop zones
function GrabberClass:checkValidDropZone()
    if not self.heldObject or not self.gameBoard then
        return false
    end
    
    -- Use the gameBoard's drop zone checking function
    return self.gameBoard:checkCardDropZones(self.heldObject)
end

-- Helper function to check if a point is inside a rectangle
function GrabberClass:pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end