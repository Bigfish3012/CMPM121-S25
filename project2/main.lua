--main file
io.stdout:setvbuf("no")

require "card"
require "grabber"

function love.load()
  love.window.setMode(700, 500)
  love.graphics.setBackgroundColor(0, 0.7, 0.2, 1)
  
  grabber = GrabberClass:new()
  cardTable = {}
  
  deckPile = {}   -- Deck pile (click to deal three cards)
  drawPile = {}   -- Drawn cards (can be moved)
  visibleDrawCards = {}  -- Visible three cards (actually references to drawPile)
  tableauPiles = {} -- 7 tableau piles
  suitPiles = {}  -- 4 suit piles (Spades, Hearts, Clubs, Diamonds)
  
  drawPilePositions = {  -- Three visible positions
    Vector(130, 50),
    Vector(200, 50),
    Vector(270, 50)
  }
  
  -- Positions for suit piles
  suitPilePositions = {
    Vector(350, 50), -- Spades
    Vector(420, 50), -- Hearts
    Vector(490, 50), -- Clubs
    Vector(560, 50)  -- Diamonds
  }

  -- Create the suit piles
  local suitOrder = {"Spades", "Hearts", "Clubs", "Diamonds"}
  for i, suit in ipairs(suitOrder) do
    suitPiles[suit] = {}
  end

  fullDeck = createDeck()

  -- Put the entire deck into deckPile (top left)
  for _, card in ipairs(fullDeck) do
    card.position = Vector(50, 50)
    card.canDrag = false
    card.faceUp = false
    table.insert(deckPile, card)
    table.insert(cardTable, card) -- Add all cards to cardTable for draw and update
  end

  -- Create 7 tableau piles, each with i cards
  local startX = 130
  for i = 1, 7 do
    tableauPiles[i] = {}
    for j = 1, i do
      local card = table.remove(deckPile)
      card.position = Vector(startX + (i - 1) * 70, 150 + (j - 1) * 20)
      card.faceUp = (j == i) -- Only the top card is face up
      card.canDrag = (j == i)
      table.insert(tableauPiles[i], card)
      table.insert(cardTable, card)
    end
  end
end

function love.update()
  grabber:update()
  checkForMouseMoving()
  for _, card in ipairs(cardTable) do
    card:update()
  end
  
  -- Update draggable state of cards in draw pile
  updateDrawPileDraggableCards()
  
  -- Update draggable state of cards in suit piles
  updateSuitPilesDraggableCards()
end

function updateDrawPileDraggableCards()
  -- Reset all cards in drawPile to not draggable
  for _, card in ipairs(drawPile) do
    card.canDrag = false
  end
  
  -- Only the topmost visible card can be dragged
  if #visibleDrawCards > 0 then
    visibleDrawCards[#visibleDrawCards].canDrag = true
  end
end

function updateSuitPilesDraggableCards()
  -- For each suit pile, only the top card can be dragged
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pile = suitPiles[suit]
    for i, card in ipairs(pile) do
      card.canDrag = (i == #pile)  -- Only the top card can be dragged
    end
  end
end

function love.draw()
  for _, card in ipairs(cardTable) do
    card:draw()
  end
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Mouse: - " .. tostring(grabber.currentMousePos.x) .. ", " .. tostring(grabber.currentMousePos.y))
  
  -- Display pile status
  love.graphics.print("Deck pile: " .. #deckPile, 20, 300)
  love.graphics.print("Draw pile: " .. #drawPile, 20, 320)
  love.graphics.print("Visible cards: " .. #visibleDrawCards, 20, 340)
  
  -- Draw suit pile placeholders
  drawSuitPilePlaceholders()
  
  love.graphics.setColor(1, 0.4, 0.7) -- Pink (R,G,B)
  love.graphics.setLineWidth(2)       -- Border thickness
  love.graphics.rectangle("line", 50, 140, 60, 30, 4, 4) -- "line" mode for border
  love.graphics.setColor(0.741, 0.867, 0.894)
  love.graphics.rectangle("fill", 50, 140, 60, 30, 4, 4) -- box
  love.graphics.setColor(0, 0, 0)
  love.graphics.printf("Draw", 50, 148, 60, "center")
end

function drawSuitPilePlaceholders()
  local suitLabels = {
    Spades = "S",
    Hearts = "H",
    Clubs = "C",
    Diamonds = "D"
  }
  
  -- Draw placeholders for each suit pile
  for i, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pos = suitPilePositions[i]
    local color = {1, 1, 1, 0.3}  -- Transparent white
    
    if suit == "Hearts" or suit == "Diamonds" then
      love.graphics.setColor(1, 0, 0, 0.3)  -- Transparent red for Hearts and Diamonds
    else
      love.graphics.setColor(0, 0, 0, 0.3)  -- Transparent black for Spades and Clubs
    end
    
    -- Draw card placeholder
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", pos.x, pos.y, 60, 80, 6, 6)
    
    -- Draw suit label
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf(suitLabels[suit], pos.x, pos.y + 30, 60, "center")
    
    -- If there's a card in this pile, draw the count
    if #suitPiles[suit] > 0 then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(#suitPiles[suit], pos.x + 45, pos.y - 15)
    end
  end
end

function checkForMouseMoving()
  if grabber.currentMousePos == nil then
    return
  end
  
  for _, card in ipairs(cardTable) do
    card:checkForMouseOver(grabber)
  end
end

function createDeck()
  local suits = {"Spades", "Hearts", "Clubs", "Diamonds"}
  local deck = {}
  for _, suit in ipairs(suits) do
    for value = 1, 13 do
      table.insert(deck, CardClass:new(0, 0, suit, value, false)) -- Initialize with face down
    end
  end

  -- Shuffle
  for i = #deck, 2, -1 do
    local j = love.math.random(i)
    deck[i], deck[j] = deck[j], deck[i]
  end

  return deck
end


function love.mousepressed(x, y, button)
  if button == 1 then
    butoonClik(x, y)
  end
end

function butoonClik(x, y)
  -- Button area click
  if x > 50 and x < 110 and y > 140 and y < 190 then
    print("===== Draw Button Clicked =====")
    print("Current deck pile count: " .. #deckPile)
    print("Current draw pile count: " .. #drawPile)
    print("Current visible cards count: " .. #visibleDrawCards)
    
    if #deckPile > 0 then
      print("Drawing cards from deck...")
      
      -- Calculate how many cards to keep from previous round
      local cardsToShow = math.min(3, #deckPile)
      local previousCardsToKeep = 0
      
      -- If new cards are less than 3, and there are previous visible cards, keep some
      if cardsToShow < 3 and #visibleDrawCards > 0 then
        -- Calculate how many previous cards to keep (to ensure a total of 3 visible cards)
        previousCardsToKeep = math.min(3 - cardsToShow, #visibleDrawCards)
        print("Need to keep " .. previousCardsToKeep .. " cards from previous round")
      end
      
      -- Stack cards that don't need to be kept at position 1
      if #visibleDrawCards > 0 then
        for i = 1, #visibleDrawCards - previousCardsToKeep do
          local card = visibleDrawCards[i]
          print("Stacking visible card #" .. i .. ": " .. tostring(card))
          card.position = drawPilePositions[1]
          card.canDrag = false  -- Ensure stacked cards cannot be dragged
        end
      end
      
      -- Keep needed cards and adjust their positions
      local newVisibleCards = {}
      if previousCardsToKeep > 0 then
        -- Start keeping cards from the rightmost of previous round
        for i = #visibleDrawCards - previousCardsToKeep + 1, #visibleDrawCards do
          local card = visibleDrawCards[i]
          table.insert(newVisibleCards, card)
          print("Keeping card: " .. tostring(card))
        end
      end
      
      -- Clear visible cards array, will be refilled later
      visibleDrawCards = {}
      
      -- Draw new cards from deck
      print("Preparing to draw " .. cardsToShow .. " new cards")
      for i = 1, cardsToShow do
        local card = table.remove(deckPile)
        if card then
          print("Drew new card #" .. i .. ": " .. tostring(card))
          card.faceUp = true
          
          -- Ensure new cards are at the top of rendering order
          for j, c in ipairs(cardTable) do
            if c == card then
              table.remove(cardTable, j)
              table.insert(cardTable, card) -- Reinsert at the end (top)
              break
            end
          end
          
          table.insert(drawPile, card)
          table.insert(newVisibleCards, card)
        end
      end
      
      -- Update visibleDrawCards and set correct positions
      for i, card in ipairs(newVisibleCards) do
        card.position = drawPilePositions[i]
        table.insert(visibleDrawCards, card)
      end
      
      print("Deck pile count after drawing: " .. #deckPile)
      print("Draw pile count after drawing: " .. #drawPile)
      print("Visible cards count after drawing: " .. #visibleDrawCards)
      
    elseif #drawPile > 0 then
      print("Deck is empty, recycling " .. #drawPile .. " cards from draw pile")
      -- No cards, recycle drawPile
      visibleDrawCards = {}
      while #drawPile > 0 do
        local card = table.remove(drawPile)
        card.faceUp = false
        card.canDrag = false
        card.position = Vector(50, 50) -- Put back to deckPile position
        table.insert(deckPile, card)
      end
      
      print("Deck pile count after recycling: " .. #deckPile)
    end
    
    -- Update draggable status
    updateDrawPileDraggableCards()
    print("===== Drawing Complete =====")
  end
end

-- Remove specified card from drawPile
function removeCardFromDrawPile(card)
  -- First remove from visibleDrawCards
  for i = #visibleDrawCards, 1, -1 do
    if visibleDrawCards[i] == card then
      table.remove(visibleDrawCards, i)
      break
    end
  end
  
  -- Remove from drawPile
  for i = #drawPile, 1, -1 do
    if drawPile[i] == card then
      table.remove(drawPile, i)
      break
    end
  end
  
  -- If visible cards are less than 3 and there are cards in deckPile, can refill
  -- Here we don't automatically refill, player needs to click Draw button
  
  -- Update draggable status
  updateDrawPileDraggableCards()
end

-- Check if a card can be added to a suit pile
function canAddToSuitPile(card, suit)
  local pile = suitPiles[suit]
  
  -- Card must match the suit
  if card.suit ~= suit then
    return false
  end
  
  -- If pile is empty, only Ace can be placed
  if #pile == 0 then
    return CardClass.rankToValue(card.rank) == 1 -- Ace
  end
  
  -- Otherwise, card must be one rank higher than the top card
  local topCard = pile[#pile]
  local cardValue = CardClass.rankToValue(card.rank)
  local topValue = CardClass.rankToValue(topCard.rank)
  
  return cardValue == topValue + 1
end

-- Add a card to a suit pile
function addToSuitPile(card, suit)
  -- Add card to suit pile
  table.insert(suitPiles[suit], card)
  
  -- Update card position
  local suitIndex = 0
  for i, s in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    if s == suit then
      suitIndex = i
      break
    end
  end
  
  card.position = suitPilePositions[suitIndex]
  
  -- Ensure card is face up
  card.faceUp = true
  
  -- Move card to top of render order
  for i, c in ipairs(cardTable) do
    if c == card then
      table.remove(cardTable, i)
      table.insert(cardTable, card)
      break
    end
  end
  
  -- Update draggable state
  updateSuitPilesDraggableCards()
end

-- Remove a card from a suit pile
function removeFromSuitPile(card)
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pile = suitPiles[suit]
    for i = #pile, 1, -1 do
      if pile[i] == card then
        table.remove(pile, i)
        updateSuitPilesDraggableCards()
        return
      end
    end
  end
end
