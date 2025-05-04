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
  
  returnBackImage = love.graphics.newImage("sprites/return_back.png")
  
  grabber = GrabberClass:new()
  cardTable = {}
  
  deckPile = {}   -- Deck pile (click to deal three cards)
  drawPile = {}   -- Drawn cards (can be moved)
  visibleDrawCards = {}  -- Visible three cards (actually references to drawPile)
  tableauPiles = {} -- 7 tableau piles
  suitPiles = {}  -- 4 suit piles (Spades, Hearts, Clubs, Diamonds)
  
  -- Add game state
  gameState = {
    hasWon = true,
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
  
  local dummyCard = CardClass:new(0, 0, "Spades", 1, true)
  cardDimensions = {
    width = dummyCard:getCardDimensions()
  }
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
end

function love.draw()
  -- Draw suit pile placeholders first so cards can cover them
  Helper.drawSuitPilePlaceholders(suitPilePositions, suitImages, cardDimensions)
  
  -- if the deck pile is empty, draw the returnBackImage
  if #deckPile == 0 then
    local cardWidth, cardHeight = cardDimensions.width, cardDimensions.height
    love.graphics.draw(returnBackImage, 50, 50, 0, 
      cardWidth / returnBackImage:getWidth(), 
      cardHeight / returnBackImage:getHeight())
  end
  
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
    
    -- Check for click on deck pile area
    local cardWidth, cardHeight = cardDimensions.width, cardDimensions.height
    if x > 50 and x < 50 + cardWidth and y > 50 and y < 50 + cardHeight then
      deckPile, drawPile, visibleDrawCards = Helper.handleDeckPileClick(deckPile, drawPile, visibleDrawCards, drawPilePositions, GrabberHelper)
      grabber.ignoreNextGrab = true  -- add flag to prevent grabber from processing the same click event
      return  -- add return to prevent further processing
    end
  end
end
