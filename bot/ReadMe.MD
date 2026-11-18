GA Scrabble Bot

The aim of this genertic algorithm is to figure out how to set hyperparameters to the problem of position evaluation

Hyperparameters:
- Weightings for the following considerations
    - Move Score
    - Rack Left 
        - Bingo Probability 
        - Value of Letters
            - Individual Relative Score
            - Relative Score of Pairs/Sets
    - Tiles Used (Reuses Value of Letters from Above)
    - Hooks Created
    - Hooks Closed
    - Endgame Specific Factors
        - 

**Encoding**
An individual is represented by two joined tuples of N weightings, one for each hyperparam (normalised to sum to 1)
The first tuple represents the beginning weights and the latter the endgame weights
The effective individual codification is a weighted average of the tuples, based on a phase variable from 1->0

**Selection**
Fitness is evaluated in a duplicate tournament mode wherein every individual is paired with another
A game is set up with bot1 vs. bot2 and the gameState set
The bots then play a game against each other with this gameState
Next they same gameState is used with the bots swapped and they play again
The player with the greater spread after both games comes out on top and the loser is discarded

^^^^^^
It's possible that this could tend us towards a local maximum wherein the bots are able to beat eachother but don't improve, in which case it may be best to have a fixed baseline bot which picks the highest score every turn instead.

**Mutation**
This is relatively easy because an individual is represented by two tuples of real numbers so we follow standard practice for GA real value mutation

**Crossing / Reproduction**
This is also simple, a simple pick-n exchange could work, though there are many options so this could be explored further