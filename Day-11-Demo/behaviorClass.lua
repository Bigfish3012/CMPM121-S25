
BehaviorClass = {}

function BehaviorClass:new(o)
    local behavior = {}
    local metatable = {__index = BehaviorClass}
    setmetatable(behavior, metatable)

    behavior.owner = o
    return behavior
end

function BehaviorClass:update()
end
function BehaviorClass:simpleMove(directionToVector)
    self.owner.position = self.owner.position + (directionToVector * self.owner.dataClass.moveSpeed)

    if directionToVector.y ~= 0 then
        self.owner.facingDirection = directionToVector.y > 0 and DIRECTIONS.DOWN or DIRECTIONS.UP
    elseif directionToVector.x ~= 0 then
        self.owner.facingDirection = directionToVector.x > 0 and DIRECTIONS.RIGHT or DIRECTIONS.LEFT
    end
end

-- PLAYER INPUT --
PlayerInputClass = BehaviorClass:new()
function PlayerInputClass:new(o)
    local playerInput = {}
    local metadata = {__index = PlayerInputClass}
    setmetatable(playerInput, metadata)

    playerInput.owner = o
    return playerInput
end
function PlayerInputClass:update()
    local moveDirection = Vector(0, 0)

    for input, direction in pairs(inputVector) do
        if love.keyboard.isDown(input) then
            moveDirection = moveDirection + direction
        end
    end
    self.owner.walking = moveDirection ~= Vector(0, 0)
    
    -- Actually Move
    if self.owner.walking then
        self:simpleMove(moveDirection)    
    end
    
end

-- CARDINAL WANDER
CardinalWanderClass = BehaviorClass:new()
function CardinalWanderClass:new(o)
    local cardinalWander = {}
    local metatable = {__index = CardinalWanderClass}
    setmetatable(cardinalWander, metatable)

    cardinalWander.owner = o
    cardinalWander.moveDirection = Vector()
    cardinalWander.timer = 0
    return cardinalWander
end

function CardinalWanderClass:update()
    
    if self.timer > 0 then
        self.timer  = self.timer - love.timer.getDelta()
    else -- time up
        if not self.owner.walking then
            -- start walking
            self.movingDirection = directionToVector[math.random(#directionToVector)]
            self.timer = math.random(1, 3) -- or math.random()*3
            self.owner.walking = true
        else
            -- stop walking
            self.movingDirection = Vector()
            self.timer = math.random(1, 2) -- or math.random()*2
            self.owner.walking = false 
        end
    end

    -- Actually moving
    if self.owner.walking then
        self:simpleMove(self.movingDirection)
    end
end