# CMPM 121 Spring 2025 -- Project 2 - Solitaire, but better

Card assets from [Screaming Brain Studios](https://screamingbrainstudios.itch.io/poker-pack)

## Features & Enhancements

### Visual Improvements
- Implemented graphical suit icons (♠️♥️♣️♦️) to replace text labels in suit piles
- Optimized rendering order to ensure cards properly overlay suit placeholder images
- Added elegant animations for victory and card movements

### Bug Fixes & Technical Improvements
- Resolved King card misalignment when placed on empty tableau piles
  - Standardized coordinate calculations (150px x-coordinate used consistently)
  - Fixed inconsistencies between card initialization and placement logic
- Reorganized code into modular components for better maintainability
- Implemented proper drag-and-drop behavior for card stacks

### Gameplay Enhancements
- Added victory screen with pulsing animation when player completes the game
- Implemented comprehensive win condition checking (all cards face-up or all suit piles filled)
- Added automatic card reorganization when removing cards from draw pile

### User Experience
- Added restart functionality with confirmation dialog to prevent accidental resets
- Improved visual feedback for card interactions
- Enhanced card pile management with clearer visual indicators

## Programming Patterns & Architecture

### Object-Oriented Approach
- Leveraged Lua's metatable system to implement class-like structures
- Created specialized classes for cards, input handling, and UI management
- Organized code into logical modules with clear responsibilities

### State Management
- Implemented a robust state system for cards (IDLE, MOUSE_OVER, GRABBED)
- Created distinct game states (normal play, victory, confirmation dialogs)
- Managed transitions between states with appropriate visual feedback

### Observer Pattern
- Developed an input system that observes mouse movements and triggers appropriate actions
- Cards observe their position in piles to determine behavior and appearance
- Game state observers trigger appropriate visual changes and animations

### Factory Pattern
- Created a deck generation system that handles card creation and randomization
- Standardized UI element creation for consistency throughout the interface
- Implemented modular creation of game components for easier maintenance

## Development Insights

### Challenges Addressed

#### Improved Code Organization
- **Previous Issue**: Card movement logic was tightly coupled with rendering code
- **Solution**: Separated concerns by moving functionality into dedicated modules
- **Outcome**: Significantly improved maintainability and reduced debugging time

#### Positioning System Refinement
- **Previous Issue**: Inconsistent hard-coded positioning led to visual glitches
- **Solution**: Implemented standardized position calculations across all card functions
- **Outcome**: Eliminated alignment issues and improved visual consistency

#### Enhanced Visual Feedback
- **Previous Issue**: Basic representation of game elements limited player engagement
- **Solution**: Added proper graphics, animations, and interactive elements
- **Outcome**: Created a more polished and enjoyable gaming experience

#### Comprehensive Game Flow
- **Previous Issue**: Limited game lifecycle management (no victory or restart)
- **Solution**: Implemented complete game loop with proper state transitions
- **Outcome**: Delivered a complete game experience with appropriate feedback

### Future Development Opportunities
- Implement undo/redo functionality for player moves
- Add sound effects and background music
- Create multiple difficulty levels or alternative rule sets
- Enhance animations and visual effects
- Add scoring system with persistent high scores


## References
- calling function from different lua file: https://stackoverflow.com/questions/22303018/calling-function-from-a-different-lua-file

- shuffle cards: https://gist.github.com/Uradamus/10323382

- get images' width and height: https://love2d.org/forums/viewtopic.php?t=9710
- find images: https://github.com/ZacEmerzian/CMPM121/blob/main/Day%2010%20Demo/sample4.lua