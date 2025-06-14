-- grabber file: for the grabber class
-- Implements card dragging functionality

require "vector"
local GameLogic = require "game"
local CardEffects = require "cards_eff"
local ResourceManager = require "resourceManager"
GrabberClass = {}

function GrabberClass:new(gameBoard)
    local grabber = {}
    local metadata = {__index = GrabberClass}
    setmetatable(grabber, metadata)
    
    grabber.currentMousePos = nil  
    grabber.grabPos = nil          
    grabber.dragOffset = nil    
    grabber.heldObject = nil       
    grabber.gameBoard = gameBoard 
    
    return grabber
end

function GrabberClass:update()
    self.currentMousePos = Vector(
        love.mouse.getX(),
        love.mouse.getY()
    )
    
    -- Check for mouse hover on cards (only when not grabbing anything)
    if not self.heldObject and self.gameBoard and self.gameBoard.cards then
        for _, card in ipairs(self.gameBoard.cards) do
            if card then
                card:checkForMouseOver(self)
            end
        end
    end
    
    -- Handle mouse click (first frame only)
    if love.mouse.isDown(1) then
        if self.grabPos == nil then
            local mx, my = love.mouse.getPosition()
            self.grabPos = Vector(mx, my)
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
        -- clear temporary data
        self.heldObject.originalPosition = nil
    end
    self.heldObject = nil
    self.grabPos = nil
    self.dragOffset = nil
end

-- Attempt to grab a card at the current mouse position
function GrabberClass:grab()
    -- Check if game board is available
    if not self.gameBoard then 
        return 
    end
    
    local mx = self.grabPos.x
    local my = self.grabPos.y
    
    -- Loop through all cards to find one under the mouse
    for _, card in ipairs(self.gameBoard.cards) do
        -- Skip check if card is already grabbed
        if card.state == CARD_STATE.GRABBED then
            goto continue
        end
        
        -- Get card dimensions based on whether it's face up or face down
        local cardWidth, cardHeight
        
        if card.faceUp and card.image then
            cardWidth = card.image:getWidth()
            cardHeight = card.image:getHeight()
        elseif not card.faceUp then
            local cardBackImage = ResourceManager:getCardBackImage()
            if cardBackImage then
                cardWidth = cardBackImage:getWidth()
                cardHeight = cardBackImage:getHeight()
            else
                cardWidth = 100
                cardHeight = 120
            end
        else
            -- Default dimensions if no image is available
            cardWidth = 100
            cardHeight = 120
        end
        
        -- Check if mouse is over this card
        local isMouseOver = mx > card.position.x and 
                           mx < card.position.x + cardWidth and 
                           my > card.position.y and
                           my < card.position.y + cardHeight
        
        if isMouseOver then
            -- Card must be in IDLE or MOUSE_OVER state and draggable
            if (card.state == CARD_STATE.IDLE or card.state == CARD_STATE.MOUSE_OVER) and card.canDrag then
                self.heldObject = card
                self.heldObject.state = CARD_STATE.GRABBED
                self.heldObject.originalPosition = Vector(card.position.x, card.position.y)
                self.dragOffset = Vector(mx - card.position.x, my - card.position.y)
                break
            end
        end
        
        ::continue::
    end
end

-- Handle card release after dragging
function GrabberClass:release()
    if not self.heldObject then
        self:resetGrabState()
        return
    end
    
    local locationIndex, slotIndex, isPlayer = self:checkValidDropZone()
    
    if not locationIndex then
        -- Invalid drop zone - return card to original position
        self:returnCardToOriginalPosition()
    else
        -- Valid drop zone - attempt to place card
        self:attemptCardPlacement(locationIndex, slotIndex, isPlayer)
    end
    
    -- Clean up
    self:resetGrabState()
    self.grabPos = nil
end

-- Return card to its original position
function GrabberClass:returnCardToOriginalPosition()
    if self.heldObject.originalPosition then
        self.heldObject:startAnimation(self.heldObject.originalPosition.x, self.heldObject.originalPosition.y, 0.3)
    end
end

-- Attempt to place card in the specified slot
function GrabberClass:attemptCardPlacement(locationIndex, slotIndex, isPlayer)
    local cardPlaced = self.gameBoard:placeCardInSlot(self.heldObject, locationIndex, slotIndex, isPlayer)
    
    if not cardPlaced then
        -- Slot is occupied - return to original position
        self:returnCardToOriginalPosition()
        return
    end
    
    -- Card placed successfully - now check if player can afford it
    local cardPlayed = GameLogic:playCard(self.heldObject, self.gameBoard, true)
    
    if not cardPlayed then
        -- Not enough mana - undo the placement
        self:undoCardPlacement(locationIndex, slotIndex)
    end
end

-- Undo card placement and return card to hand
function GrabberClass:undoCardPlacement(locationIndex, slotIndex)
    -- Remove card from slot
    self.gameBoard.locations[locationIndex].playerSlots[slotIndex] = nil
    
    -- Restore card to face-up state (cards in player's hand should be face-up)
    -- Play flip sound effect
    if playFlipSound then
        playFlipSound()
    end
    self.heldObject.faceUp = true
    
    -- Return card to player's hand
    table.insert(self.gameBoard.playerHand, self.heldObject)
    
    -- Reposition hand cards and get target position
    self.gameBoard:positionHandCards()
    local targetPos = self.heldObject.position
    
    -- Animate the card to its proper hand position
    self.heldObject:startAnimation(targetPos.x, targetPos.y, 0.4)
end

-- Check if card is dropped in a valid zone
function GrabberClass:checkValidDropZone()
    if not self.heldObject or not self.gameBoard then
        return nil
    end
    return self.gameBoard:checkCardDropZones(self.heldObject)
end