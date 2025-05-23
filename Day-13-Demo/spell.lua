
ELEMENTS = {
  EARTH = 1,
  FIRE = 2,
  WATER = 3,
  WIND = 4
}

elementDisplayName = {
  "Earth",
  "Fire",
  "Water",
  "Wind"
}

radialDamageFalloff = {
  0.8,
  0.6,
  0.4,
  0.2
}

SpellPrototype = {}

function SpellPrototype:new(dispName, descrip, pow, elem, cost, range)
  local spell = {}
  local metadata = {__index = SpellPrototype}
  setmetatable(spell, metadata)
   
  spell.displayName = dispName
  spell.description = descrip
  spell.power = pow
  spell.element = elem
  spell.cost = cost
  spell.range = range or 0
  
  return spell
end
function SpellPrototype:getElementName()
  return elementDisplayName[self.element]
end
function SpellPrototype:getRandomEnemy()
  local randIndex = math.random(#enemyTable)
  return enemyTable[randIndex]
end
function SpellPrototype:getAdjacentEnemy(givenEnemy, range)
  local target = {}

  --Get Given Enemy's Index
  local givenIndex = -1
  for i = 1, #enemyTable do
    if enemyTable[i] == givenEnemy then
      givenIndex = i
    end
  end
  if givenIndex < 1 then
    return nil
  end
  for i = 1, range do
    local adjacents = {}
    local leftIndex = givenIndex - i
    if leftIndex > 0 then
      table.insert(adjacents, enemyTable[leftIndex])
    end
    local rightIndex = givenIndex + i
    
    if rightIndex <= #enemyTable then
      table.insert(adjacents, enemyTable[rightIndex])
    end
  end

end
function SpellPrototype:damageEntity(entity, damage)
  if entity == nil then
    print("No targets remaining for " .. tostring(self.displayName) .. "!")
    return
  end
  
  entity:takeDamage(damage)
end

-- SPELL DEFINITIONS --
CarpetBombPrototype = SpellPrototype:new(
  "Carpet Bomb",
  "Attack with a bomb blast.",
  130,
  ELEMENTS.FIRE,
  29,
  0 -- TODO: 3
)
function CarpetBombPrototype:new()
  return CarpetBombPrototype
end
function CarpetBombPrototype:cast()
  local target = self:getRandomEnemy()
  self:damageEntity(target, self.power)
end

GrowthPrototype = SpellPrototype:new(
  "Growth",
  "Attack with wild plants.",
  25,
  ELEMENTS.EARTH,
  4
)
function GrowthPrototype:new()
  return GrowthPrototype
end
function GrowthPrototype:cast()
  local target = self:getRandomEnemy()
  self:damageEntity(target, self.power)
end

FrothSpiralPrototype = SpellPrototype:new(
  "Froth Spiral",
  "Attack with a water vortex.",
  150,
  ELEMENTS.WATER,
  31,
  3
)

function FrothSpiralPrototype:new()
  return FrothSpiralPrototype
end

function FrothSpiralPrototype:cast()
  -- AOE damage to a random enemy
  local target = self:getRandomEnemy()
  self:damageEntity(target, self.power)

  local subTargets = self:getAdjacentEnemy(target, self.range)
  if subTargets == nil or #subTargets == 0 then
    return
  end
  for k, v in ipairs(subTargets) do
    local damage = self.power * radialDamageFalloff[k]
    for _, adjacents in ipairs(v) do
      self:damageEntity(adjacents, damage)
    end
  end
  return target
end

