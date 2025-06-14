# CMPM 121 Spring 2025 - Project 3: CCCG

## Programming Patterns

### State Pattern
The game implements a robust state machine system following the State pattern:
- **Game States**: Title, gameplay, credits, and game over states are managed through `gameStateManager.lua`
- **Game Phases**: Staging and revealing phases with distinct behaviors in `turns.lua`
- **Card States**: Multiple card states (hand, idle, mouseOver, revealed) implemented in `card.lua`

### Component Pattern
The game follows a component-based architecture where each component is responsible for a specific aspect of the game:
- `game.lua` - Core game logic and turn management
- `ai.lua` & `aiStrategy.lua` - AI decision-making and strategy implementation
- `player.lua` - Player state and actions
- `gameBoard.lua` - Visual representation and board management
- `card.lua` & `cards_eff.lua` - Card objects, behaviors, and effect system
- `grabber.lua` - Drag-and-drop mechanics
- `inputManager.lua` - Input handling and event management
- `audioManager.lua` - Sound system management
- `uiManager.lua` - User interface components
- `resourceManager.lua` - Asset loading and management

### Observer Pattern
The game implements the Observer pattern for event handling:
- Card effects and game state changes are broadcast to relevant components
- UI updates are triggered through event notifications
- Game state changes are observed by multiple systems

### Command Pattern
The game uses the Command pattern for:
- Card actions and effects
- Turn management
- Input handling
- AI decision making

### Singleton Pattern
Several managers are implemented as singletons:
- `resourceManager.lua` - Manages game assets
- `audioManager.lua` - Controls sound system
- `gameStateManager.lua` - Manages game states
- `inputManager.lua` - Handles input processing

### Strategy Pattern
The AI system uses the Strategy pattern:
- Different AI strategies are implemented in `aiStrategy.lua`
- Strategies can be swapped during gameplay
- Each strategy implements a common interface for decision making

## Project Postmortem

### What Worked Well
1. **Modular Design**: The component-based architecture made it easier to manage different aspects of the game independently.
2. **State Management**: Clear separation of game states helped maintain organized code structure.
3. **Card System**: The modular effect system allowed for flexible card implementation.

### What Could Be Improved
1. **Card Effect System**
   - Challenge: Complex card interactions and unique abilities
   - Current Solution: Modular effect system with manual implementation
   - Future Improvement: Create a more robust and automated effect system

2. **Game Balance**
   - Challenge: Ensuring balanced gameplay and satisfying progression
   - Current Status: Battles end too quickly
   - Future Improvement: Implement better balancing system

### Future Enhancements
- Custom deck building system
- Expanded card collection
- Enhanced visual effects and animations
- Improved audio feedback system
- Better error handling for card placement

## Assets

### Fonts
- Title Screen: [Angels Font](https://www.dafont.com/angels.font)
- Credit Screen: [Relationship of Melodrame](https://www.dafont.com/relationship-of-melodrame.font)
- In-game: [Square Font](https://www.dafont.com/squarefont.font)
- Description: [Poetsen One](https://www.dafont.com/poetsen-one.font)

### Sprites
- [Demon Sprite Pack](https://deepdivegamestudio.itch.io/demon-sprite-pack)
- [Holy Asset Pack](https://deepdivegamestudio.itch.io/holyassetpack)
- [Monster Asset Pack](https://deepdivegamestudio.itch.io/monsterassetpack)

### Audio
- Background Music 1: [Pixel Fight](https://pixabay.com/music/video-games-pixel-fight-8-bit-arcade-music-background-music-for-video-208775/)
- Background Music 2: [Byte Blast](https://pixabay.com/music/video-games-byte-blast-8-bit-arcade-music-background-music-for-video-208780/)
- Win Sound: [Brass Fanfare](https://pixabay.com/sound-effects/brass-fanfare-with-timpani-and-winchimes-reverberated-146260/)
- Lose Sound: [Violin Lose](https://pixabay.com/sound-effects/violin-lose-4-185125/)
- Card Flip Sound: [Turn Page](https://pixabay.com/sound-effects/turnpage-99756/)
- Button Click Sound: [Level Passed](https://pixabay.com/sound-effects/level-passed-142971/)

## References
- [Multiple Screen Management](https://love2d.org/forums/viewtopic.php?t=93629)
- [Font Implementation](https://love2d.org/wiki/Tutorial:Fonts_and_Text)
- [File Reading](https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua)
- [Audio Implementation](https://love2d.org/wiki/Tutorial:Audio)
- [Game Quit Implementation](https://love2d.org/forums/viewtopic.php?t=78482)