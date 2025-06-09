-- grabber file: for the grabber class
-- Implements card dragging functionality

require "vector"
local GameLogic = require "game"
local CardEffects = require "cards_eff"
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
        elseif not card.faceUp and CardClass.cardBackImage then
            cardWidth = CardClass.cardBackImage:getWidth()
            cardHeight = CardClass.cardBackImage:getHeight()
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
    -- If we have a held card
    if self.heldObject then
        -- Check if the card is in a valid drop zone
        local locationIndex, slotIndex, isPlayer = self:checkValidDropZone()
        
        if not locationIndex then
            -- If not a valid drop, return card to original position
            if self.heldObject.originalPosition then
                self.heldObject.position = self.heldObject.originalPosition
            end
        else
            -- Try to place the card in the slot
            local cardPlaced = self.gameBoard:placeCardInSlot(self.heldObject, locationIndex, slotIndex, isPlayer)
            
            if cardPlaced then
                -- Always treat cards dropped by player as player cards
                local isPlayerCard = true
                
                -- try to play the card (spend mana and trigger effects)
                local cardPlayed = GameLogic:playCard(self.heldObject, self.gameBoard, isPlayerCard)
                
                if cardPlayed then
                    -- Trigger card effects with location information
                    CardEffects:triggerEffectWithLocation(self.heldObject.name, self.heldObject, self.gameBoard, locationIndex, slotIndex)
                    
                    -- Check for passive effects (like Athena) after successful card placement
                    CardEffects:checkPassiveEffects(self.heldObject, self.gameBoard, locationIndex)
                else
                    -- if mana is not enough, remove from slot and return to hand
                    self.gameBoard.locations[locationIndex].playerSlots[slotIndex] = nil
                    table.insert(self.gameBoard.playerHand, self.heldObject)
                    self.gameBoard:positionHandCards()
                end
            else
                -- Slot is occupied, return to original position
                if self.heldObject.originalPosition then
                    self.heldObject.position = self.heldObject.originalPosition
                end
            end
        end
    end
    
    -- Reset grabber state
    self:resetGrabState()
    self.grabPos = nil
end

-- Check if card is dropped in a valid zone
function GrabberClass:checkValidDropZone()
    if not self.heldObject or not self.gameBoard then
        return nil
    end
    return self.gameBoard:checkCardDropZones(self.heldObject)
end