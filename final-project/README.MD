# CMPM 121 Spring 2025 - Project 3: CCCG

## Programming Patterns

### State Pattern
- **Game Screens**: Title, game, credits, and game over states
- **Game Phases**: Staging and revealing phases with distinct behaviors
- **Card States**: Multiple card states (hand, idle, mouseOver, revealed)

### Component Pattern
  - `game.lua` - Core game logic and turn management
  - `ai.lua` - AI decision-making and strategy
  - `player.lua` - Player state and actions
  - `gameBoard.lua` - Visual representation and board management
  - `card.lua` - Card objects and behaviors
  - `cards_eff.lua` - Card effect system
  - `grabber.lua` - Drag-and-drop mechanics
  - `helper.lua` - Game over box

## Project Postmortem

### Key Challenges and Solutions

#### Card Effect System
- **Challenge**: Implement unique card abilities with complex interactions
- **Solution**: Modular effect system, and then manually implement the effect of each card
- **Result**: Most of the card effects have been implemented, but there are still bugs

#### Turn-Based Flow
- **Challenge**: Coordinating player and AI turns with proper phase management
- **Result**: Not very satisfactory, currently only the end of the round is achieved.

#### Game Balance
- **Challenge**: Ensuring balanced cards with satisfying progression
- **Solution**: Constantly adjust the value
- **Result**: The results are less than satisfactory, and the game often ends battles very quickly.

### Future Improvements
- Players can customize their decks
- Expanded card set with more characters
- Visual effects and animations
- Audio feedback system
- Eliminate card placement errors

## Assets

### Fonts
- **Title Screen**: (https://www.dafont.com/angels.font)
- **Credit Screen**: (https://www.dafont.com/relationship-of-melodrame.font?back=theme)
- **In game**: (https://www.dafont.com/squarefont.font)
- **description**: (https://www.dafont.com/poetsen-one.font?text=location&back=theme)

### Images
- [Demon Sprite Pack](https://deepdivegamestudio.itch.io/demon-sprite-pack)
- [Holy Asset Pack](https://deepdivegamestudio.itch.io/holyassetpack)
- [Monster Asset Pack](https://deepdivegamestudio.itch.io/monsterassetpack)

### Music and sound effects
- Background Music 1: https://pixabay.com/music/video-games-pixel-fight-8-bit-arcade-music-background-music-for-video-208775/

- Background Music 2: https://pixabay.com/music/video-games-byte-blast-8-bit-arcade-music-background-music-for-video-208780/

- win sound effect: https://pixabay.com/sound-effects/brass-fanfare-with-timpani-and-winchimes-reverberated-146260/

- lose sound effect: https://pixabay.com/sound-effects/violin-lose-4-185125/

- card flip sound effect: https://pixabay.com/sound-effects/turnpage-99756/

- button click sound effect: https://pixabay.com/sound-effects/level-passed-142971/

## References
- [Multiple Screen Management](https://love2d.org/forums/viewtopic.php?t=93629)
- [Font Implementation](https://love2d.org/wiki/Tutorial:Fonts_and_Text)
- [File Reading](https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua)

- add music: https://love2d.org/wiki/Tutorial:Audio
- quit the game: https://love2d.org/forums/viewtopic.php?t=78482