
SpriteClass = {}

function SpriteClass:new()
  local sprite = {}
  local metadata = {__index = SpriteClass}
  setmetatable(sprite, metadata)
  
  sprite.sprites = {
    love.graphics.newImage("Sprites/Gibdo.png")
  }
  
  return sprite
end

function SpriteClass:getSprite(dir, isAnimating)
  
  return self.sprites[1]
end

LinkSprites = SpriteClass:new()
function LinkSprites:new()
  self.sprites = {
    love.graphics.newImage("Sprites/LinkUp.png")
    love.graphics.newImage("Sprites/LinkDown.png")
    love.graphics.newImage("Sprites/LinkSide1.png")
    love.graphics.newImage("Sprites/LinkSide2.png")
  }
  self.directionSprites = {
    [DIRECTIONS.UP] = {
      {sprite = self.sprite[1], flipX = false},
      {sprite = self.sprite[1], flipX = true},
    },
    [DIRECTIONS.DOWN] = {
      {sprite = self.sprite[2], flipX = false},
      {sprite = self.sprite[2], flipX = true},
    },
    [DIRECTIONS.LEFT] = {
      {sprite = self.sprite[3], flipX = false},
      {sprite = self.sprite[4], flipX = false},
    },
    [DIRECTIONS.RIGHT] = {
      {sprite = self.sprite[3], flipX = true},
      {sprite = self.sprite[4], flipX = true},
    },
  }
  return self
end
