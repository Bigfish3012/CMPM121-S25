--main file
io.stdout:setvbuf("no")

require "card"
require "grabber"
RestartModule = require "restart"
Helper = require "helper"
GrabberHelper = require "grabber_helper"

function love.load()
  love.window.setTitle("Solitaire, but better")
  love.window.setMode(900, 700)
  love.graphics.setBackgroundColor(0, 0.7, 0.2, 1)
  
  suitImages = {
    Spades = love.graphics.newImage("sprites/spade.png"),
    Hearts = love.graphics.newImage("sprites/heart.png"),
    Clubs = love.graphics.newImage("sprites/club.png"),
    Diamonds = love.graphics.newImage("sprites/diamond.png")
  }
  
  grabber = GrabberClass:new()
  cardTable = {}
  
  deckPile = {}   -- Deck pile (click to deal three cards)
  drawPile = {}   -- Drawn cards (can be moved)
  visibleDrawCards = {}  -- Visible three cards (actually references to drawPile)
  tableauPiles = {} -- 7 tableau piles
  suitPiles = {}  -- 4 suit piles (Spades, Hearts, Clubs, Diamonds)
  
  -- Add game state
  gameState = {
    hasWon = false,
    showRestartConfirm = false  -- Flag to show restart confirmation dialog
  }
  
  -- Initialize restart module
  RestartModule.init(gameState)
  
  drawPilePositions = {  -- Three visible positions
    Vector(150, 50),
    Vector(245, 50),
    Vector(340, 50)
  }
  
  -- Positions for suit piles
  suitPilePositions = {
    Vector(435, 50), -- Spades
    Vector(530, 50), -- Hearts
    Vector(625, 50), -- Clubs
    Vector(720, 50)  -- Diamonds
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
    
    -- Mark the first card as the deck pile indicator
    if _ == 1 then
      card.isDeckPile = true
    end
    
    table.insert(deckPile, card)
    table.insert(cardTable, card) -- Add all cards to cardTable for draw and update
  end

  -- Create 7 tableau piles, each with i cards
  local startX = 150
  for i = 1, 7 do
    tableauPiles[i] = {}
    for j = 1, i do
      local card = table.remove(deckPile)
      card.position = Vector(startX + (i - 1) * 95, 190 + (j - 1) * 20)
      card.faceUp = (j == i) -- Only the top card is face up
      card.canDrag = (j == i)
      table.insert(tableauPiles[i], card)
      table.insert(cardTable, card)
    end
  end
  
  -- Create a deck pile placeholder card if all cards are removed
  deckPilePlaceholder = CardClass:new(50, 50, "Spades", 1, false)
  deckPilePlaceholder.isDeckPile = true
  deckPilePlaceholder.canDrag = false
  table.insert(cardTable, deckPilePlaceholder)
  
  -- Cache card dimensions to avoid creating temporary objects each frame
  local dummyCard = CardClass:new(0, 0, "Spades", 1, true)
  cardDimensions = {
    width = dummyCard:getCardDimensions()
  }
  -- Also cache height
  cardDimensions.height = select(2, dummyCard:getCardDimensions())
end

function love.update()
  grabber:update()
  checkForMouseMoving()
  for _, card in ipairs(cardTable) do
    card:update()
  end
  
  -- Update draggable state of cards in draw pile
  Helper.updateDrawPileDraggableCards(drawPile, visibleDrawCards)
  
  -- Update draggable state of cards in suit piles
  Helper.updateSuitPilesDraggableCards(suitPiles)
  
  -- Check if player has won the game
  Helper.checkForWin(gameState, cardTable, suitPiles)
  
  -- Show/hide placeholder based on deck pile state
  deckPilePlaceholder.position = Vector(50, 50)
  if #deckPile > 0 then
    -- Hide placeholder when deck has cards
    deckPilePlaceholder.position = Vector(-200, -200)  -- Move off-screen
  end
end

function love.draw()
  -- Draw suit pile placeholders first so cards can cover them
  drawSuitPilePlaceholders()
  
  -- Draw all cards on top
  for _, card in ipairs(cardTable) do
    card:draw()
  end
  
  -- Draw Restart button
  RestartModule.drawButton()
  
  -- Draw victory screen if player has won
  if gameState.hasWon then
    Helper.drawWinScreen(gameState)
  end
  
  -- Draw restart confirmation dialog
  if gameState.showRestartConfirm then
    RestartModule.drawConfirmDialog()
  end
end

function drawSuitPilePlaceholders()
  -- Use cached card dimensions instead of creating temporary objects
  local cardWidth, cardHeight = cardDimensions.width, cardDimensions.height
  
  -- Draw placeholders for each suit pile
  for i, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pos = suitPilePositions[i]
    
    -- Semi-transparent white background
    love.graphics.setColor(1, 1, 1, 0.4)  -- Semi-transparent white
    love.graphics.rectangle("fill", pos.x, pos.y, cardWidth, cardHeight, 6, 6)
    
    -- Border
    if suit == "Hearts" or suit == "Diamonds" then
      love.graphics.setColor(1, 0, 0, 0.7)  -- Red border for red suits
    else
      love.graphics.setColor(0, 0, 0, 0.7)  -- Black border for black suits
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", pos.x, pos.y, cardWidth, cardHeight, 6, 6)
    
    -- Draw suit image instead of text label
    love.graphics.setColor(1, 1, 1, 1)
    local image = suitImages[suit]
    local scale = 3
    local imgWidth, imgHeight = image:getDimensions()
    love.graphics.draw(
      image, 
      pos.x + cardWidth/2 - (imgWidth*scale)/2, 
      pos.y + cardHeight/2 - (imgHeight*scale)/2,
      0,  -- rotation
      scale, scale  -- scale x, y
    )
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
    -- If restart confirmation is showing, check for button clicks
    if gameState.showRestartConfirm then
      RestartModule.handleConfirmClick(x, y, RestartModule.restartGame)
      return -- Don't process other clicks when dialog is open
    end
    
    -- Check for restart button click
    if RestartModule.checkButtonClick(x, y) then
      return
    end
    
    -- Check for click on deck pile area (replacing button click)
    local cardWidth, cardHeight = cardDimensions.width, cardDimensions.height
    if x > 50 and x < 50 + cardWidth and y > 50 and y < 50 + cardHeight then
      handleDeckPileClick()
      grabber.ignoreNextGrab = true  -- 添加标志以防止grabber处理同一个点击事件
      return  -- 添加return以阻止进一步处理
    end
  end
end

-- Handle click on deck pile (replacing buttonClick)
function handleDeckPileClick()
  if #deckPile > 0 then
    -- Calculate how many cards to keep from previous round
    local cardsToShow = math.min(3, #deckPile)
    local previousCardsToKeep = 0
    
    -- If new cards are less than 3, and there are previous visible cards, keep some
    if cardsToShow < 3 and #visibleDrawCards > 0 then
      -- Calculate how many previous cards to keep (to ensure a total of 3 visible cards)
      previousCardsToKeep = math.min(3 - cardsToShow, #visibleDrawCards)
    end
    
    -- Stack cards that don't need to be kept at position 1
    if #visibleDrawCards > 0 then
      for i = 1, #visibleDrawCards - previousCardsToKeep do
        local card = visibleDrawCards[i]
        card.position = drawPilePositions[1]
        card.canDrag = false  -- Ensure stacked cards cannot be dragged
        card.state = CARD_STATE.IDLE  -- 重置状态以防止错误的鼠标悬停事件
      end
    end
    
    -- Keep needed cards and adjust their positions
    local newVisibleCards = {}
    if previousCardsToKeep > 0 then
      -- Start keeping cards from the rightmost of previous round
      for i = #visibleDrawCards - previousCardsToKeep + 1, #visibleDrawCards do
        local card = visibleDrawCards[i]
        card.state = CARD_STATE.IDLE  -- 重置状态
        table.insert(newVisibleCards, card)
      end
    end
    
    -- Clear visible cards array, will be refilled later
    visibleDrawCards = {}
    
    -- Draw new cards from deck
    for i = 1, cardsToShow do
      local card = table.remove(deckPile)
      if card then
        card.faceUp = true
        card.state = CARD_STATE.IDLE  -- 设置新卡牌的状态为IDLE
        
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
      table.insert(visibleDrawCards, card)
    end
    
    -- Use Helper to reorganize cards
    Helper.reorganizeVisibleDrawCards(drawPile, visibleDrawCards, drawPilePositions)
    
  elseif #drawPile > 0 then
    -- No cards in deck pile, recycle draw pile
    visibleDrawCards = {}
    while #drawPile > 0 do
      local card = table.remove(drawPile)
      card.faceUp = false
      card.canDrag = false
      card.state = CARD_STATE.IDLE  -- 重置状态
      card.position = Vector(50, 50) -- Put back to deckPile position
      table.insert(deckPile, card)
    end
  end
end

-- Remove specified card from drawPile
function removeCardFromDrawPile(card)
  local removedIndex = 0
  
  -- First remove from visibleDrawCards and remember position
  for i = #visibleDrawCards, 1, -1 do
    if visibleDrawCards[i] == card then
      removedIndex = i
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
  
  -- Reorganize remaining visible cards
  Helper.reorganizeVisibleDrawCards(drawPile, visibleDrawCards, drawPilePositions)
  
end

-- Check if a card can be added to a suit pile
function canAddToSuitPile(card, suit)
  local pile = suitPiles[suit]
  
  -- Card must match the suit
  if card.suit ~= suit then
    return false
  end
  
  -- If pile is empty, only A can be placed
  if #pile == 0 then
    return card.value == 1 -- A
  end
  
  -- Otherwise, card must be one rank higher than the top card
  local topCard = pile[#pile]
  
  return card.value == topCard.value + 1
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
  Helper.updateSuitPilesDraggableCards(suitPiles)
end

-- Remove a card from a suit pile
function removeFromSuitPile(card)
  for _, suit in ipairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
    local pile = suitPiles[suit]
    for i = #pile, 1, -1 do
      if pile[i] == card then
        table.remove(pile, i)
        Helper.updateSuitPilesDraggableCards(suitPiles)
        return
      end
    end
  end
end