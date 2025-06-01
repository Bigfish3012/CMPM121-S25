-- deckManager.lua: Manages deck-related functionality
require "card"

local DeckManager = {}

-- Initialize decks
function DeckManager:initializeDecks()
    -- Check if card information is available
    if not CARD_INFO or next(CARD_INFO) == nil then
        print("Warning: CARD_INFO is empty or not loaded!")
        return {}, {}
    end
    
    -- Create array containing all card info for random selection
    local allCards = {}
    for cardName, cardInfo in pairs(CARD_INFO) do
        if cardInfo and cardInfo.name and cardInfo.power and cardInfo.manaCost then
            table.insert(allCards, cardName)
        end
    end
    
    -- If no valid cards found, return empty decks
    if #allCards == 0 then
        print("Error: No valid cards found!")
        return {}, {}
    end
    
    -- Create player deck
    local playerDeck = {}
    local playerCardCounts = {}
    for i = 1, 20 do
        local card = self:createRandomCard(allCards, playerCardCounts, false)
        if card then
            table.insert(playerDeck, card)
        end
    end
    
    -- Create opponent deck
    local opponentDeck = {}
    local opponentCardCounts = {}
    for i = 1, 20 do
        local card = self:createRandomCard(allCards, opponentCardCounts, false)
        if card then
            table.insert(opponentDeck, card)
        end
    end
    
    -- Shuffle decks
    self:shuffleDeck(playerDeck)
    self:shuffleDeck(opponentDeck)
    
    return playerDeck, opponentDeck
end

-- Create a random card
function DeckManager:createRandomCard(allCards, cardCounts, faceUp)
    local attempts = 0
    while attempts < 100 do
        attempts = attempts + 1
        local randomIndex = love.math.random(1, #allCards)
        local cardName = allCards[randomIndex]
        local cardInfo = CARD_INFO[cardName]
        
        -- Check if we can add this card (max 2 copies)
        local currentCount = cardCounts[cardName] or 0
        if currentCount < 2 and cardInfo then
            local card = CardClass:new(0, 0, cardInfo.name, cardInfo.power, cardInfo.manaCost, cardInfo.text, faceUp)
            cardCounts[cardName] = currentCount + 1
            return card
        end
    end
    
    -- If we couldn't add a card due to restrictions, add any available card
    if #allCards > 0 then
        local cardName = allCards[1]
        local cardInfo = CARD_INFO[cardName]
        if cardInfo then
            return CardClass:new(0, 0, cardInfo.name, cardInfo.power, cardInfo.manaCost, cardInfo.text, faceUp)
        end
    end
    
    return nil
end

-- Shuffle functionality
function DeckManager:shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- Draw starting hands (3 cards each)
function DeckManager:drawStartingHands(playerDeck, opponentDeck)
    local playerHand = {}
    local opponentHand = {}
    
    -- Player draws 3 cards
    for i = 1, 3 do
        if #playerDeck > 0 then
            local card = table.remove(playerDeck)
            card.faceUp = true
            card.canDrag = true
            table.insert(playerHand, card)
        end
    end
    
    -- Opponent draws 3 cards
    for i = 1, 3 do
        if #opponentDeck > 0 then
            local card = table.remove(opponentDeck)
            card.faceUp = false
            card.canDrag = false
            table.insert(opponentHand, card)
        end
    end
    
    return playerHand, opponentHand
end

return DeckManager 