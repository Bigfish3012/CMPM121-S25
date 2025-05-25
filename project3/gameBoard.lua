-- gameBoard: for the game board

GameBoard = {}

function GameBoard:new(width, height)
    local gameBoard = {}
    local metadata = {__index = GameBoard}
    setmetatable(gameBoard, metadata)
    
    -- Store screen dimensions
    gameBoard.screenWidth = width or 1400
    gameBoard.screenHeight = height or 800
    
    -- Card slot properties
    gameBoard.slotWidth = 800
    gameBoard.slotHeight = 140
    
    -- Initialize player and opponent card collections
    gameBoard.playerDeck = {}
    gameBoard.opponentDeck = {}
    gameBoard.playerHand = {}
    gameBoard.opponentHand = {}
    gameBoard.cards = {}
    
    -- Initialize the decks and draw starting hands
    gameBoard:initializeDecks()
    gameBoard:drawStartingHands()
    
    return gameBoard
end

function GameBoard:draw()
    -- Draw background
    love.graphics.setColor(0, 0.7, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Card height
    local cardHeight = 120
    
    -- Draw the opponent's card slot
    self:drawCardSlot(nil, 20, cardHeight)
    -- Draw the player's card slot
    self:drawCardSlot(nil, self.screenHeight - 160, cardHeight)
    
    -- Draw discard piles
    self:drawDiscardPile(nil)
    
    -- Draw decks
    self:drawDeckPile(nil)
    
    -- Draw mana pools
    self:drawManaPool()
    
    -- Draw player's and opponent's hands
    self:drawHands()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Function to draw the semi-transparent card slot at the top or bottom
function GameBoard:drawCardSlot(x, y, height)
    -- Use provided coordinates or default values if not provided
    local slotX = x or (self.screenWidth - self.slotWidth) / 2
    local slotY = y or (self.screenHeight - self.slotHeight - 20)
    
    -- Get card height from parameter or use default
    local cardHeight = height or 120
    
    -- Calculate required slot height - slightly larger than card height to leave some space
    local slotHeight = cardHeight + 20
    
    -- Draw semi-transparent white card slot
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", slotX, slotY, self.slotWidth, slotHeight, 10, 10)
    
    -- Draw card slot border
    love.graphics.setColor(0.9, 0.9, 0.9, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", slotX, slotY, self.slotWidth, slotHeight, 10, 10)
    
    -- Return the slot position and dimensions for use by other functions
    return slotX, slotY, self.slotWidth, slotHeight
end

function GameBoard:drawDiscardPile(card)
    -- for player side, draw the discard pile on the bottom right
    -- for the opponent side, draw the discard pile on the top left
    
    -- Get card dimensions from the card back image
    if not self.cardBackImage then
        self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
    end
    
    local cardWidth = self.cardBackImage:getWidth()
    local cardHeight = self.cardBackImage:getHeight()
    
    -- Draw player's discard pile (bottom right)
    local playerDiscardX = self.screenWidth - cardWidth - 20
    local playerDiscardY = self.screenHeight - cardHeight - 20
    
    -- Draw opponent's discard pile (top left)
    local opponentDiscardX = 20
    local opponentDiscardY = 20
    
    -- Draw semi-transparent white discard pile slots
    love.graphics.setColor(1, 1, 1, 0.3)  -- More transparent than card slots
    
    -- Player's discard pile
    love.graphics.rectangle("fill", playerDiscardX, playerDiscardY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", playerDiscardX, playerDiscardY, cardWidth, cardHeight, 10, 10)
    
    -- Opponent's discard pile
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", opponentDiscardX, opponentDiscardY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.rectangle("line", opponentDiscardX, opponentDiscardY, cardWidth, cardHeight, 10, 10)
    
    -- If a card is provided, draw it in the appropriate discard pile
    if card then
        -- Determine which discard pile to use based on card's position
        local discardX, discardY
        if card.position.y > self.screenHeight / 2 then
            -- Card is in player's half, use player's discard pile
            discardX = playerDiscardX
            discardY = playerDiscardY
        else
            -- Card is in opponent's half, use opponent's discard pile
            discardX = opponentDiscardX
            discardY = opponentDiscardY
        end
        
        -- Draw the card
        card.position = Vector(discardX, discardY)
        card:draw()
    end
end

function GameBoard:drawDeckPile(card)
    -- for player side, draw the deck on the bottom left
    -- for the opponent side, draw the deck on the top right
    
    -- Load the card back image if not already loaded
    if not self.cardBackImage then
        self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
    end
    
    -- Use original card back image size
    local cardWidth = self.cardBackImage:getWidth()
    local cardHeight = self.cardBackImage:getHeight()
    
    -- Draw player's deck (bottom left)
    local playerDeckX = 20
    local playerDeckY = self.screenHeight - 160
    
    -- Draw opponent's deck (top right)
    local opponentDeckX = self.screenWidth - 120
    local opponentDeckY = 20
    
    -- Draw semi-transparent placeholders for decks
    love.graphics.setColor(1, 1, 1, 0.3)
    
    -- Player's deck
    love.graphics.rectangle("fill", playerDeckX, playerDeckY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", playerDeckX, playerDeckY, cardWidth, cardHeight, 10, 10)
    
    -- Opponent's deck
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", opponentDeckX, opponentDeckY, cardWidth, cardHeight, 10, 10)
    love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", opponentDeckX, opponentDeckY, cardWidth, cardHeight, 10, 10)
    
    -- Draw the card back image on each deck
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to full opacity white
    
    -- Draw player's deck card backs (staggered to look like a pile)
    for i = 3, 1, -1 do
        love.graphics.draw(self.cardBackImage, playerDeckX - (i-1)*3, playerDeckY - (i-1)*3, 0, 1, 1)
    end
    
    -- Draw opponent's deck card backs (staggered to look like a pile)
    for i = 3, 1, -1 do
        love.graphics.draw(self.cardBackImage, opponentDeckX - (i-1)*3, opponentDeckY - (i-1)*3, 0, 1, 1)
    end
end

function GameBoard:drawManaPool()
    -- draw the mana pool on the top left (on the left of the discard pile)
    -- for the opponent side, draw the mana pool on the top right (on the right of the discard pile)
    
    -- Load mana images if not already loaded
    if not self.manaImage then
        self.manaImage = love.graphics.newImage("asset/img/Mana.png")
    end
    if not self.emptyManaImage then
        self.emptyManaImage = love.graphics.newImage("asset/img/emptyMana.png")
    end
    
    -- Get image dimensions
    local manaWidth = self.manaImage:getWidth()
    local manaHeight = self.manaImage:getHeight()

    local spacing = 5  -- Space between mana icons
    
    -- Get current mana values (these would be set elsewhere in your game logic)
    -- Default to full mana (10) if not set
    if not self.playerMana then self.playerMana = 10 end
    if not self.opponentMana then self.opponentMana = 10 end
    
    -- Player mana pool position (near discard pile on the bottom right)
    local playerManaStartX = self.screenWidth - 270  -- Left of discard pile
    local playerManaY = self.screenHeight - 160  -- Same level as discard pile
    
    -- Opponent mana pool position (near discard pile on the top left)
    local opponentManaStartX = 150  -- Right of discard pile
    local opponentManaY = 20  -- Same level as discard pile
    
    -- Draw player's mana pool (5 in each row)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to full opacity white
    
    for i = 1, 10 do
        local row = math.ceil(i / 5)  -- 1 for first row, 2 for second row
        local col = (i - 1) % 5 + 1   -- 1-5 for each row
        
        local x = playerManaStartX + (col - 1) * (manaWidth + spacing)
        local y = playerManaY + (row - 1) * (manaHeight + spacing)
        
        -- Draw full or empty mana based on current mana
        local image = (i <= self.playerMana) and self.manaImage or self.emptyManaImage
        love.graphics.draw(image, x, y, 0, 1, 1)
    end
    
    -- Draw opponent's mana pool (5 in each row)
    for i = 1, 10 do
        local row = math.ceil(i / 5)  -- 1 for first row, 2 for second row
        local col = (i - 1) % 5 + 1   -- 1-5 for each row
        
        local x = opponentManaStartX + (col - 1) * (manaWidth + spacing)
        local y = opponentManaY + (row - 1) * (manaHeight + spacing)
        
        -- Draw full or empty mana based on current mana
        local image = (i <= self.opponentMana) and self.manaImage or self.emptyManaImage
        love.graphics.draw(image, x, y, 0, 1, 1)
    end
end

-- Function to initialize decks with cards
function GameBoard:initializeDecks()
    -- Create an array containing all card info for random selection
    local allCards = {}
    for cardName, cardInfo in pairs(CARD_INFO) do
        -- Only use cards that we have images for
        table.insert(allCards, cardName)
    end
    
    -- Create player deck
    for i = 1, 15 do
        -- Randomly select a card
        local randomIndex = love.math.random(1, #allCards)
        local cardName = allCards[randomIndex]
        local cardInfo = CARD_INFO[cardName]
        
        -- Create card object
        local card = CardClass:new(0, 0, cardInfo.name, cardInfo.power, cardInfo.manaCost, cardInfo.text, false)
        table.insert(self.playerDeck, card)
        table.insert(self.cards, card)
    end
    
    -- Create opponent deck
    for i = 1, 15 do
        -- Randomly select a card
        local randomIndex = love.math.random(1, #allCards)
        local cardName = allCards[randomIndex]
        local cardInfo = CARD_INFO[cardName]
        
        -- Create card object
        local card = CardClass:new(0, 0, cardInfo.name, cardInfo.power, cardInfo.manaCost, cardInfo.text, false)
        table.insert(self.opponentDeck, card)
        table.insert(self.cards, card)
    end
    
    -- Shuffle decks
    self:shuffleDeck(self.playerDeck)
    self:shuffleDeck(self.opponentDeck)
end

-- Function to shuffle a deck
function GameBoard:shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- Function to draw starting hands (3 cards each)
function GameBoard:drawStartingHands()
    -- Draw 3 cards for player
    for i = 1, 3 do
        if #self.playerDeck > 0 then
            local card = table.remove(self.playerDeck)
            card.faceUp = true  -- Player can see their cards
            card.canDrag = true -- Player can drag their cards
            table.insert(self.playerHand, card)
        end
    end
    
    -- Draw 3 cards for opponent
    for i = 1, 3 do
        if #self.opponentDeck > 0 then
            local card = table.remove(self.opponentDeck)
            card.faceUp = false  -- Opponent cards are face down to the player
            card.canDrag = false -- Opponent cards cannot be dragged by the player
            table.insert(self.opponentHand, card)
        end
    end
    
    -- Position cards in hands
    self:positionHandCards()
end

-- Function to position cards in player and opponent hands
function GameBoard:positionHandCards()
    -- Card height
    local cardHeight = 120
    
    -- Get the position and dimensions of top and bottom card slots
    local topSlotX, topSlotY, topSlotWidth, topSlotHeight = self:drawCardSlot(nil, 20, cardHeight)
    local bottomSlotX, bottomSlotY, bottomSlotWidth, bottomSlotHeight = self:drawCardSlot(nil, self.screenHeight - 160, cardHeight)
    
    -- Calculate card spacing
    local cardSpacing = 110  -- Space between cards
    
    -- Calculate starting position to center cards in the slot
    local playerHandStartX = bottomSlotX + 50
    local playerHandY = bottomSlotY + (bottomSlotHeight - cardHeight) / 2  -- Vertically centered
    
    -- Position player hand at the bottom
    for i, card in ipairs(self.playerHand) do
        card.position = Vector(playerHandStartX + (i-1) * cardSpacing, playerHandY)
    end
    
    -- Opponent hand starting position
    local opponentHandStartX = topSlotX + 50
    local opponentHandY = topSlotY + (topSlotHeight - cardHeight) / 2  -- Vertically centered
    
    -- Position opponent hand at the top
    for i, card in ipairs(self.opponentHand) do
        card.position = Vector(opponentHandStartX + (i-1) * cardSpacing, opponentHandY)
    end
end

-- Function to draw both player's and opponent's hands
function GameBoard:drawHands()
    -- Draw player's hand (face up)
    for _, card in ipairs(self.playerHand) do
        card:draw()
    end
    
    -- Draw opponent's hand (face down)
    -- Load the card back image if not already loaded
    if not self.cardBackImage then
        self.cardBackImage = love.graphics.newImage("asset/img/card_back.png")
    end
    
    for _, card in ipairs(self.opponentHand) do
        -- We need to temporarily save the card's face-up state
        local originalFaceUp = card.faceUp
        -- Force face down for drawing opponent's cards
        card.faceUp = false
        -- Draw the card
        card:draw()
        -- Restore original face-up state
        card.faceUp = originalFaceUp
    end
end

-- Function to check if a card is dropped in a valid zone
-- Returns true if the card is in a valid zone, false otherwise
function GameBoard:checkCardDropZones(card)
    -- Get card dimensions
    local cardWidth, cardHeight
    if card.faceUp and card.image then
        cardWidth = card.image:getWidth()
        cardHeight = card.image:getHeight()
    elseif not card.faceUp and card.cardBackImage then
        cardWidth = card.cardBackImage:getWidth()
        cardHeight = card.cardBackImage:getHeight()
    else
        cardWidth = 100
        cardHeight = 120
    end
    
    -- Card center position
    local cardCenterX = card.position.x + cardWidth / 2
    local cardCenterY = card.position.y + cardHeight / 2
    
    -- Bottom slot position and dimensions
    local slotX, slotY, slotWidth, slotHeight = self:drawCardSlot(nil, self.screenHeight - 160, cardHeight)
    
    -- Check if card is in the bottom slot (player's play area)
    if cardCenterX > slotX and cardCenterX < slotX + slotWidth and
       cardCenterY > slotY and cardCenterY < slotY + slotHeight then
        return true
    end
    
    return false
end