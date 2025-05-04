# CMPM 121 Spring 2025 -- Project 2 - Solitaire, but better

Card assets from [Screaming Brain Studios](https://screamingbrainstudios.itch.io/poker-pack)

### Bug Fixes & Improvements
- Fixed inconsistencies between card initialization and placement logic
- Create helper.lua and grabber.lua to help main.lua and grabber.lua
- Implemented proper drag-and-drop behavior for card stacks
- Added a restart button
- Implemented graphical suit icons (♠️♥️♣️♦️) to replace text labels in suit piles
- Added a win screen

## Programming Patterns Used


### 1. Update Method Pattern
- Each card has its own update method (`card:update()`), which allows you to know the state of each card and keep track of whether the card's position makes sense.

### 2. State Pattern
- Cards have clear states (IDLE, MOUSE_OVER, GRABBED), which determine the behavior of the card. This allows you to determine whether a card can be moved based on its different states.

### 3. Component Pattern
- Move part of main.lua to helper.lua for easier management. Similarly, move part of grabber.lua to grabber_helper.lua to achieve the same purpose.

### 4. Game Loop Pattern
- Allow the game to continuously update the gameplay process.

## Project Postmortem
#### 1. Card Movement Logic Issues
- **Problem**: In Project 1, card movement was tightly coupled with rendering, making the code hard to maintain
- **Plan**: Extract movement logic into dedicated helper functions and modules
- **Result**: Successfully created dedicated grabber.lua and grabber_helper.lua modules that handle movement separately from rendering, significantly improving code clarity

#### 2. Draw Pile Management
- **Problem**: Project 1 has bugs in the handling of the draw pile cards, with cards not stacking correctly and showing when they shouldn't.
- **Plan**: Redesign the draw pile mechanism, put the drawn card in the first position and let other cards cover it.
- **Result**: The draw pile is handled correctly, with sound logic to reveal the top three cards and move the previously visible card to position 1.

#### 3. Poor Code Organization
- **Problem**: Most of the functions of Project 1 are contained in the main.lua and grabber.lua files, which are not very readable.
- **Plan**: Refactor into modular components with clear responsibilities
- **Result**: Successfully split code into different file (helper.lua, grabber.lua, grabber_helper.lua, card.lua, restart.lua).

#### 4. Limited Visual Feedback
- **Problem**: The cards in project1 are too simple and not good enough.
- **Plan**: use free game asset
- **Result**: Implemented suit icons, card images, and the win screen.

#### Future Improvement Opportunities
- Add an Undo button, allowing the player to undo the previous step. Add sound effects, and maybe some animations.

## References
- calling function from different lua file: https://stackoverflow.com/questions/22303018/calling-function-from-a-different-lua-file
- shuffle cards: https://gist.github.com/Uradamus/10323382
- get images' width and height: https://love2d.org/forums/viewtopic.php?t=9710
- find images: https://github.com/ZacEmerzian/CMPM121/blob/main/Day%2010%20Demo/sample4.lua