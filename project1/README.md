# CMPM 121 Spring 2025 -- Project 1 - Solitaire

## Programming Patterns Used

1. **State Pattern**
   - Implemented different card states (IDLE, MOUSE_OVER, GRABBED)
   - Each state has specific behaviors and transitions

2. **Component Pattern**
   - Cards have multiple components (position, suit, rank, etc.)
    Makes it easy to add new features without affecting existing code too much

## Postmortem
I don't think I have done anything well. My code is too messy and not well structured.

### What Could Be Improved

1. **Code Structure**
   - The main.lua file became quite large and could be split into multiple files
   - Understanding how the game works before writing code will allow you to summarize the basic code structure and how subsequent code will run and build. I found that during my coding process, I always need to make frequent changes and will be limited by the previous code, so I have to use other methods to implement new ideas.

2. **Visual Polish**
   - Maybe card animations would increase the player experience
   - More visual feedback for valid/invalid moves would be helpful
   - Currently, the game doesn't have a win screen yet, so I think a game completion celebration would provide a better scene.

## The tool that I used:
- [Piskel](https://www.piskelapp.com/p/create/sprite) - for create sprites
- [RGB Color Picker](https://rgbcolorpicker.com/0-1) - for color