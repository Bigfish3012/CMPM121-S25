-- grabber file: for the grabber class

require "vector"

GrabberClass = {}

function GrabberClass:new()
    local grabber = {}
    local metadata = {__index = GrabberClass}
    setmetatable(grabber, metadata)
    
    grabber.currentMousePos = nil
    grabber.grabPos = nil
    grabber.dragOffset = nil
    
    grabber.heldObject = nil
    
    return grabber
end

function GrabberClass:update()
    self.currentMousePos = Vector(
        love.mouse.getX(),
        love.mouse.getY()
    )
    
    -- Click (just the first frame)
    if love.mouse.isDown(1) and self.grabPos == nil then
        self:grab()
    end
    -- Release
    if not love.mouse.isDown(1) and self.grabPos ~= nil then
        self:release()
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