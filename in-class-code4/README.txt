###README file for Second Discussion Section

1. How much work is being done in main.lua?
  main.lua currently acts as the central hub of the project—it initializes the window, loads assets, stores the global game state, runs the main update, and draws loops. 
  
2. How encapsulated are the different part of the code?
  I will say the encapsulation is just okay for the different parts of the code.
  
3. Is the code easy to follow? (Maybe get an outside opinion for that one)
  I will say it is kind of hard to read and understand, but it's just because I don't like the interface of ZeroBrane Studio. There is no special distinction in colors, so sometimes I misread some values ​​and names.
4. How could you improve any of these issues?
  I might be going to move logic like collision checks or card grabbing into relevant classes instead of keeping it in main.lua.
5. What patterns are currently being used and which ones could be used (and why)?
  **Currently used patterns**:
  - Loose component structure with separate files per class.

  **Something could be used**:
  - **Event system**: Instead of checking for mouse interactions in every card, a simple event system could dispatch mouse events to cards.

***Added feature***
- Cards return to original position if being dropped on an invalid position