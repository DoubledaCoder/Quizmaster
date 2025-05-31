LogicTonk will deliver questions in a local area and provide hints over the course of 60 seconds. Players nearby can respond via /say with their answer. First to answer correctly gets celebrated!

LogicTonk keeps track of total amount of correct guesses from a player as well as streaks if the player is able to continuiously answer questions. Streaks do not end if no one knows the correct answer.

LogicTonk demo setup is located at (  .go xyz -11820.909 -4747.388 6.90528 1  ). BE sure to add ALL queries in the trivia.sql file to properly stage the demo setup.

LogicTonk is based off old Diablo 2 Lobby Trivia Bots. Hints are delivered in the form of exposed letters at a rate of 10% of the answer-characters every 10 seconds.

Ensure any npc the script is used for is set to Faction Template 35(Friendly) or similar and cannot be attacked by players.

** DOES NOT WORK WITH <GM> ON. <GM> MUST BE OFF FOR /says to register to the npc **

    Name:        trivia.lua (Quizmaster)
    Author:	 Stephen Kania/Youpeoples
    Repository:	 https://github.com/Youpeoples/Quizmaster
    Download:	 https://github.com/Youpeoples/Quizmaster/archive/refs/heads/main.zip
    License:	 MIT


