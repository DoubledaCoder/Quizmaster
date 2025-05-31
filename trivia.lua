-- Keeps track of player correct answers and streaks.
-- Reacts and emotes throughout.
-- Letter reveals while waiting for right answer.
-- Currently only looking for the isolated answer in a /say radius. NoN cAsE sEnSiTiVe.
-- Suffles so the questions stay fresh even on frequent resets.
--** DOES NOT WORK WITH <GM> ON. <GM> MUST BE OFF FOR /says to register to the npc



-- Fisher-Yates Shuffle
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

-- CONFIG
local NPC_ENTRY = 2069424
local LISTEN_RADIUS = 40
local CHAT_MSG_SAY = 1
local QUESTION_INTERVAL = 60     -- seconds between questions (if unanswered)
local ANSWER_DELAY = 15          -- seconds after a correct answer before next question
local lastCountdownTime = QUESTION_INTERVAL  -- to track countdown announcements
local FOLLOWER_NPC_ENTRY = 33880 -- I use mimiron images. If set around the Main Quizmaster npc, the configured npc here will emote and become part of the show as well. Its cute. Do it.
local EMOTE_RADIUS = 20
local FAIL_SPELL_ID = 76010

-- Questions and answers
local trivia = {
    { q = "What is the capital of the Night Elves?", a = "darnassus" },
    { q = "What is the name of the final boss in the Deadmines dungeon?", a = "edwin vancleef" },
    { q = "What faction does Edwin VanCleef lead?", a = "defias brotherhood" },
    { q = "What is the name of the ship found at the end of the Deadmines?", a = "invincible" },
    { q = "What large mechanical boss guards the ship in the Deadmines?", a = "sneed's shredder" },
    { q = "What is the name of the goblin boss that rides a shredder in Deadmines?", a = "sneed" },
    { q = "What mining-themed area do players enter before reaching the final ship in Deadmines?", a = "the foundry" },
    { q = "What is the name of the female caster boss in the Deadmines?", a = "helix gearbreaker" },
    { q = "What boss in the Deadmines uses an ogre as a mount?", a = "helix gearbreaker" },
    { q = "Who is the first boss encountered in the Deadmines?", a = "glubtok" },
    { q = "What type of creature is Glubtok in the Deadmines?", a = "ogre" },
    { q = "What rogue-type mini-boss appears on the ship in the Deadmines?", a = "captain greenskin" },
    { q = "What dungeon is located in Westfall and is accessible via a mine entrance?", a = "deadmines" },
    { q = "What is the name of the engineer gnome miniboss who appears with bombs in Deadmines?", a = "foe reaper 5000" },
    { q = "What boss in Deadmines is a large mechanical reaper?", a = "foe reaper 5000" },
    { q = "What is the name of the zone where the Deadmines entrance is located?", a = "westfall" },
    { q = "Which Defias leader was once a stonemason for Stormwind?", a = "edwin vancleef" },
    { q = "What is the name of the tauren NPC who helps players enter the Deadmines in the reworked version?", a = "brubaker" },
    { q = "Which expansion reworked the Deadmines into a level 85 heroic version?", a = "cataclysm" },
    { q = "What alliance city is closest to the Deadmines entrance?", a = "stormwind" },
    { q = "What is the name of the druid who leads the Wailing Caverns cult?", a = "naralex" },
    { q = "What is the name of the final boss in Wailing Caverns?", a = "mutanus the devourer" },
    { q = "What group of druids is responsible for the corruption in the Wailing Caverns?", a = "the druids of the fang" },
    { q = "What race is the NPC Naralex?", a = "tauren" },
    { q = "What creature is summoned when Naralex awakens?", a = "mutanus the devourer" },
    { q = "What snake-like boss is part of the Druid of the Fang in Wailing Caverns?", a = "lord serpentsis" },
    { q = "What boss in Wailing Caverns drops the Serpent's Shoulders?", a = "lady anacondra" },
    { q = "What is the name of the fang-wielding boss found near the central cave lake?", a = "lord pythas" },
    { q = "What is the name of the raptor boss in Wailing Caverns?", a = "skum" },
    { q = "What is the name of the Deviate creature that guards Naralex?", a = "mutanus the devourer" },
    { q = "Which boss in Wailing Caverns drops the Crescent Staff?", a = "mutanus the devourer" },
    { q = "What is the name of the naga boss encountered in Wailing Caverns?", a = "lord cobrahn" },
    { q = "Which Druid of the Fang uses sleep spells in Wailing Caverns?", a = "lady anacondra" },
    { q = "What is the name of the neutral zone near the Wailing Caverns entrance?", a = "the barrens" },
    { q = "Which fang-themed staff is often used to summon the final boss in Wailing Caverns?", a = "serpentbloom staff" },
    { q = "Which vendor NPC outside Wailing Caverns is known for selling rare recipes?", a = "khelden brewmaster" },
    { q = "What corrupted plant creatures are found throughout Wailing Caverns?", a = "deviate lashers" },
    { q = "What type of creature is Skum in Wailing Caverns?", a = "thunder lizard" },
    { q = "What must be completed before Mutanus the Devourer appears?", a = "escort naralex" },
    { q = "What is the name of the object required to summon Mutanus in Wailing Caverns?", a = "serpentbloom staff" },
    { q = "Who is the final boss in Shadowfang Keep?", a = "archmage arugal" },
    { q = "What type of magic does Arugal primarily use?", a = "shadow" },
    { q = "What is the name of the werewolf boss below the chapel in Shadowfang Keep?", a = "baron silverlaine" },
    { q = "Which boss in Shadowfang Keep is summoned with a book and pentagram?", a = "azoroth" },
    { q = "What is the name of the haunted castle that houses Shadowfang Keep?", a = "shadowfang keep" },
    { q = "What ghostly boss drops the Ghostly Mantle in Shadowfang Keep?", a = "commander springvale" },
    { q = "What undead boss in Shadowfang Keep is known for silencing casters?", a = "deathsworn captain" },
    { q = "What elite worgen commander is encountered in Shadowfang Keep?", a = "fenrus the devourer" },
    { q = "What is the name of the area where Shadowfang Keep is located?", a = "silverpine forest" },
    { q = "What type of creature is Fenrus in Shadowfang Keep?", a = "worgen" },
    { q = "Which boss is directly associated with the curse that haunts Shadowfang Keep?", a = "archmage arugal" },
    { q = "What boss in Shadowfang Keep guards the courtyard?", a = "baron silverlaine" },
    { q = "Which undead boss is found in the wine cellar area of Shadowfang Keep?", a = "razorclaw the butcher" },
    { q = "What was Archmage Arugal’s original faction before his betrayal?", a = "kirin tor" },
    { q = "What spectral wolf boss is summoned by Baron Silverlaine?", a = "olf grizzlegut" },
    { q = "Which boss is the cause of the worgen infestation in Shadowfang Keep?", a = "archmage arugal" },
    { q = "What is the name of the ghostly boss that appears near the stables in Shadowfang Keep?", a = "commander springvale" },
    { q = "Which boss shouts 'I will feed on your soul!' in Shadowfang Keep?", a = "archmage arugal" },
    { q = "What creature type are most of the enemies in Shadowfang Keep?", a = "undead" },
    { q = "What is the name of the ancient naga boss in Blackfathom Deeps?", a = "gelihast" },
    { q = "What is the name of the final boss in Blackfathom Deeps?", a = "aku'mai" },
    { q = "What two-headed hydra appears at the end of Blackfathom Deeps?", a = "aku'mai" },
    { q = "Which cult is responsible for the corruption in Blackfathom Deeps?", a = "twilight's hammer" },
    { q = "Which boss in Blackfathom Deeps is associated with the Twilight's Hammer?", a = "twilight lord kelris" },
    { q = "What is the name of the aquatic demon god worshiped in Blackfathom Deeps?", a = "aku'mai" },
    { q = "What is the name of the murloc boss in Blackfathom Deeps?", a = "gelihast" },
    { q = "Which boss in Blackfathom Deeps summons nightmares during battle?", a = "twilight lord kelris" },
    { q = "What race is Old Serra'kis in Blackfathom Deeps?", a = "thresher" },
    { q = "Which boss in Blackfathom Deeps is found swimming underwater?", a = "old serra'kis" },
    { q = "Which naga boss guards the central altar in Blackfathom Deeps?", a = "gelihast" },
    { q = "What corrupted elemental is fought in the early chambers of Blackfathom Deeps?", a = "ghamoo-ra" },
    { q = "Which boss in Blackfathom Deeps resembles a giant turtle?", a = "ghamoo-ra" },
    { q = "What is the name of the main cavern system Blackfathom Deeps is set in?", a = "ashenvale coast" },
    { q = "What is the name of the water-bound monster with powerful cleave attacks?", a = "ghamoo-ra" },
    { q = "Which cult uses mind control and nightmares in Blackfathom Deeps?", a = "twilight's hammer" },
    { q = "What is the name of the altar used to summon Aku'mai?", a = "altar of the deep" },
    { q = "Which rare boss can spawn in the lower caves of Blackfathom Deeps?", a = "lorgus jett" },
    { q = "What is the name of the pool where Aku'mai dwells?", a = "moonshrine sanctum" },
    { q = "What is the name of the sea witch involved in corrupting the deeps?", a = "baron aquanis" },
    { q = "What city is The Stockade dungeon located in?", a = "stormwind" },
    { q = "Who is the final boss in The Stockade?", a = "bazil thredd" },
    { q = "What prison rebellion is central to The Stockade storyline?", a = "the stonemason uprising" },
    { q = "What is the name of the rogue leader causing chaos in The Stockade?", a = "bazil thredd" },
    { q = "Which boss in The Stockade was formerly a Stonemason?", a = "bazil thredd" },
    { q = "Which Defias NPC appears in The Stockade as a boss?", a = "dextren ward" },
    { q = "What is the name of the spellcasting boss in The Stockade?", a = "hamhock" },
    { q = "What is the name of the area beneath Stormwind that contains The Stockade?", a = "old town" },
    { q = "What boss in The Stockade is known for throwing fireballs?", a = "hamhock" },
    { q = "Which boss in The Stockade drops the Gold-plated Buckler?", a = "kam deepfury" },
    { q = "What is the name of the Tauren boss imprisoned in The Stockade?", a = "kam deepfury" },
    { q = "Which faction does Bazil Thredd belong to?", a = "defias brotherhood" },
    { q = "What boss in The Stockade was a high-ranking Defias operative?", a = "bazil thredd" },
    { q = "What event leads to the prison break in The Stockade?", a = "stonemason rebellion" },
    { q = "What is the main enemy type fought in The Stockade?", a = "humanoid" },
    { q = "What boss in The Stockade wears a red Defias mask?", a = "dextren ward" },
    { q = "What is the name of the dwarf prisoner in The Stockade?", a = "bruegal ironknuckle" },
    { q = "Which boss in The Stockade can be summoned through a rare spawn?", a = "bruegal ironknuckle" },
    { q = "Which faction is responsible for imprisoning most of the bosses in The Stockade?", a = "stormwind" },
    { q = "Which NPC gives a quest to confront Bazil Thredd?", a = "warden thelwater" },
    { q = "What quilboar tribe controls Razorfen Kraul?", a = "death's head" },
    { q = "Who is the final boss of Razorfen Kraul?", a = "charlga razorflank" },
    { q = "What type of creature is Charlga Razorflank?", a = "quilboar" },
    { q = "What is the name of the giant turtle boss in Razorfen Kraul?", a = "blind hunter" },
    { q = "What rare boss in Razorfen Kraul is a huge turtle?", a = "blind hunter" },
    { q = "What plant-based creature is summoned by Charlga Razorflank?", a = "spirit of agamaggan" },
    { q = "What is the name of the pig-like race found throughout Razorfen Kraul?", a = "quilboar" },
    { q = "What is the name of the ancient boar deity associated with Razorfen Kraul?", a = "agamaggan" },
    { q = "What is the name of the troll boss located in Razorfen Kraul?", a = "death speaker jargba" },
    { q = "What boss in Razorfen Kraul can mind control players?", a = "death speaker jargba" },
    { q = "What undead boss appears in Razorfen Kraul near the altar area?", a = "rotting agamaggan" },
    { q = "What dungeon is located at the southern edge of the Barrens and filled with brambles?", a = "razorfen kraul" },
    { q = "What boss in Razorfen Kraul is associated with the Scourge?", a = "death speaker jargba" },
    { q = "What is the name of the druid NPC who gives quests inside Razorfen Kraul?", a = "willix the importer" },
    { q = "Which Razorfen Kraul boss is known for summoning earth elementals?", a = "earthcaller halmgar" },
    { q = "Which boss drops the Swine Tusk Shank in Razorfen Kraul?", a = "charlga razorflank" },
    { q = "What is the name of the prison cage where Willix is found in Razorfen Kraul?", a = "slave pens" },
    { q = "Which zone is Razorfen Kraul located in?", a = "the barrens" },
    { q = "Which boar deity’s spirit can be seen in Razorfen Kraul?", a = "agamaggan" },
    { q = "What is the name of the final chamber where Charlga Razorflank is encountered?", a = "razorfen altar" },
    { q = "Who is the final boss of Razorfen Downs?", a = "amnennar the coldbringer" },
    { q = "What is the name of the lich that rules over Razorfen Downs?", a = "amnennar the coldbringer" },
    { q = "Which Scourge-affiliated boss appears in Razorfen Downs?", a = "amnennar the coldbringer" },
    { q = "What is the name of the area where Razorfen Downs is located?", a = "thousand needles" },
    { q = "What undead creature in Razorfen Downs uses frost magic?", a = "amnennar the coldbringer" },
    { q = "What is the name of the circular bone pit used to fight mobs in Razorfen Downs?", a = "bone pit" },
    { q = "Which Razorfen Downs boss summons skeletons during battle?", a = "amnennar the coldbringer" },
    { q = "What is the name of the rare undead boar found in Razorfen Downs?", a = "plaguemaw the rotting" },
    { q = "What boss in Razorfen Downs is encountered within a frost-covered chamber?", a = "amnennar the coldbringer" },
    { q = "What type of creature is Mordresh Fire Eye in Razorfen Downs?", a = "lich" },
    { q = "Which boss rides a skeletal steed in Razorfen Downs?", a = "amnennar the coldbringer" },
    { q = "What boss is found in the central brazier platform in Razorfen Downs?", a = "mordresh fire eye" },
    { q = "What undead boss drops the Bonefingers in Razorfen Downs?", a = "mordresh fire eye" },
    { q = "What NPC in Razorfen Downs gives a quest to defeat Mordresh?", a = "belnistrasz" },
    { q = "Which NPC channels a brazier to weaken Mordresh Fire Eye?", a = "belnistrasz" },
    { q = "What boss drops the Coldrage Dagger in Razorfen Downs?", a = "amnennar the coldbringer" },
    { q = "What is the name of the undead druid boss in Razorfen Downs?", a = "ragglesnout" },
    { q = "Which boss in Razorfen Downs uses a giant frost nova ability?", a = "amnennar the coldbringer" },
    { q = "What is the name of the undead spider boss in Razorfen Downs?", a = "tuten'kash" },
    { q = "Which boss in Razorfen Downs is summoned by ringing a gong?", a = "tuten'kash" },
    { q = "What is the name of the final boss in Gnomeregan?", a = "mekgineer thermaplugg" },
    { q = "What gnome betrayed his people and took control of Gnomeregan?", a = "mekgineer thermaplugg" },
    { q = "What is the name of the corrupted city where Gnomeregan is located?", a = "gnomeregan" },
    { q = "What is the name of the toxic ooze boss in Gnomeregan?", a = "viscous fallout" },
    { q = "What boss in Gnomeregan patrols on a mechanical chicken walker?", a = "crowd pummeler 9-60" },
    { q = "What is the name of the rare radioactive slime boss in Gnomeregan?", a = "viscous fallout" },
    { q = "Which boss in Gnomeregan is a large mechanical punching machine?", a = "crowd pummeler 9-60" },
    { q = "What NPC in Gnomeregan provides bombs for a quest objective?", a = "kernobee" },
    { q = "What creature type is Mekgineer Thermaplugg?", a = "gnome" },
    { q = "What item must be activated to disable the bomb consoles in the final boss room of Gnomeregan?", a = "emergency shutdown button" },
    { q = "What is the name of the air filtration device room in Gnomeregan?", a = "clean room" },
    { q = "What zone is Gnomeregan located in?", a = "dun morogh" },
    { q = "What type of radiation fills the halls of Gnomeregan?", a = "radioactive fallout" },
    { q = "What is the name of the trogg boss in Gnomeregan?", a = "grubbis" },
    { q = "What rare boss in Gnomeregan is a mechanical gnome?", a = "mechano-tank" },
    { q = "Which gnome gives quests to defeat Thermaplugg in Gnomeregan?", a = "tinkmaster overspark" },
    { q = "What boss drops the Electrocutioner Leg in Gnomeregan?", a = "electrocutioner 6000" },
    { q = "What type of creature is Electrocutioner 6000?", a = "robot" },
    { q = "What boss in Gnomeregan is surrounded by bombs and consoles?", a = "mekgineer thermaplugg" },
    { q = "What is the name of the lower section filled with troggs in Gnomeregan?", a = "the dormitory" },
    { q = "What is the name of the fanatical human order that controls Scarlet Monastery?", a = "scarlet crusade" },
    { q = "Who is the final boss of the Scarlet Monastery Cathedral wing?", a = "high inquisitor whitemane" },
    { q = "What boss resurrects Scarlet Commander Mograine during the Cathedral fight?", a = "high inquisitor whitemane" },
    { q = "What is the name of the boss who shouts 'Arise, my champion!'?", a = "high inquisitor whitemane" },
    { q = "What is the name of the boss found in the Scarlet Monastery Armory?", a = "herod" },
    { q = "Which Scarlet Crusade boss is known as the 'Scarlet Champion'?", a = "herod" },
    { q = "What unique attack does Herod use that causes him to spin in a whirlwind?", a = "bladestorm" },
    { q = "What is the name of the book-burning boss in the Scarlet Monastery Library?", a = "arcanist doan" },
    { q = "Which Scarlet Monastery boss uses a silence field as a defensive spell?", a = "arcanist doan" },
    { q = "What is the name of the final boss in the Scarlet Monastery Graveyard?", a = "bloodmage thalnos" },
    { q = "What type of magic does Bloodmage Thalnos primarily use?", a = "shadow" },
    { q = "Which boss is found reading forbidden tomes in the Library wing?", a = "arcanist doan" },
    { q = "What boss drops the Raging Berserker’s Helm in Scarlet Monastery?", a = "herod" },
    { q = "What title does Whitemane hold within the Scarlet Crusade?", a = "high inquisitor" },
    { q = "Which boss uses Divine Shield during combat in Scarlet Monastery?", a = "high inquisitor whitemane" },
    { q = "What is the name of the elite monk adds summoned during Herod’s fight?", a = "scarlet trainees" },
    { q = "What room contains Mograine’s sarcophagus?", a = "cathedral altar" },
    { q = "What zone is Scarlet Monastery located in?", a = "tille's hope" },
    { q = "What faction opposes the Scarlet Crusade within lore?", a = "argent dawn" },
    { q = "What is the name of the commander paired with Whitemane?", a = "scarlet commander mograine" },
    { q = "What is the name of the titan vault explored in Uldaman?", a = "uldaman" },
    { q = "Who is the final boss of Uldaman?", a = "araghamar" },
    { q = "What titan construct guards the disks of Norgannon in Uldaman?", a = "araghamar" },
    { q = "What is the name of the ancient data storage artifact found in Uldaman?", a = "disks of norgannon" },
    { q = "What is the name of the leader of the troggs in Uldaman?", a = "grimlok" },
    { q = "What is the name of the stone giant boss in Uldaman?", a = "araghamar" },
    { q = "What dwarven group excavates Uldaman for titan secrets?", a = "explorer's league" },
    { q = "Which boss in Uldaman is a dark iron dwarf spellcaster?", a = "baelog" },
    { q = "What is the name of the ancient titan facility buried in the Badlands?", a = "uldaman" },
    { q = "What race were the original inhabitants of Uldaman before being corrupted?", a = "earthen" },
    { q = "What race devolved into troggs according to Uldaman lore?", a = "earthen" },
    { q = "Which boss in Uldaman carries the Staff of Jordan as loot?", a = "araghamar" },
    { q = "What is the name of the hidden chamber where the Disks of Norgannon are stored?", a = "hall of the keepers" },
    { q = "Which explorer NPC gives quests inside Uldaman?", a = "lead prospector dagran" },
    { q = "What item in Uldaman is needed for the Staff of Prehistoria quest?", a = "amulet of gni'kiv" },
    { q = "What titan language is stored on the disks of Norgannon?", a = "titanscript" },
    { q = "What enemy type is most common in the early parts of Uldaman?", a = "trogg" },
    { q = "Which Uldaman boss is known for throwing rocks and knockbacks?", a = "revelosh" },
    { q = "What titan structure lies beneath the Badlands?", a = "uldaman" },
    { q = "Which elemental boss in Uldaman is composed entirely of stone?", a = "araghamar" },
    { q = "What is the name of the final boss in Zul'Farrak?", a = "chief ukorz sandscalp" },
    { q = "What troll tribe inhabits Zul'Farrak?", a = "sandfury" },
    { q = "What troll shaman boss rides a giant basilisk in Zul'Farrak?", a = "zel'mak" },
    { q = "What is the name of the boss who uses a giant serpent in Zul'Farrak?", a = "theka the martyr" },
    { q = "What is the name of the imprisoned NPCs you help rescue during a scripted event?", a = "sergeant bly" },
    { q = "What is the name of the pyramid ambush encounter in Zul'Farrak?", a = "stair event" },
    { q = "Which boss summons zombies during the pyramid event in Zul'Farrak?", a = "shadowpriest sezz'ziz" },
    { q = "Which Zul'Farrak boss drops the Jang'thraze, the Protector?", a = "chief ukorz sandscalp" },
    { q = "What type of creature is summoned by Witch Doctor Zum'rah in Zul'Farrak?", a = "zombies" },
    { q = "Which boss is encountered in the graveyard area of Zul'Farrak?", a = "witch doctor zum'rah" },
    { q = "Which troll uses fear and totems in his boss fight in Zul'Farrak?", a = "nez'ral the shadow" },
    { q = "What is the name of the great hydra boss in Zul'Farrak?", a = "gahz'rilla" },
    { q = "What item is needed to summon Gahz'rilla?", a = "mallet of zul'farak" },
    { q = "Who gives the quest that involves summoning Gahz'rilla?", a = "warrior mastok wrathfist" },
    { q = "Which boss drops the Zul'Farrak ceremonial staff?", a = "chief ukorz sandscalp" },
    { q = "What is the name of the entrance zone where Zul'Farrak is located?", a = "tanaris" },
    { q = "What troll priest is known for summoning skeletal minions?", a = "witch doctor zum'rah" },
    { q = "What rare boss patrols on a raptor in Zul'Farrak?", a = "shadowpriest sezz'ziz" },
    { q = "Which boss in Zul'Farrak gives the 'Divino-matic Rod' as a quest item?", a = "sergeant bly" },
    { q = "What title does Ukorz Sandscalp hold in the Sandfury tribe?", a = "chief" },
    { q = "What is the name of the Dark Iron dwarf city located inside Blackrock Mountain?", a = "blackrock depths" },
    { q = "Who is the emperor of the Dark Iron dwarves in Blackrock Depths?", a = "dagran thaurissan" },
    { q = "Who is the princess held captive near Emperor Thaurissan?", a = "moira bronzebeard" },
    { q = "What is the name of the bar found deep inside Blackrock Depths?", a = "the grim guzzler" },
    { q = "What boss runs the tavern inside Blackrock Depths?", a = "phalanx" },
    { q = "What boss in Blackrock Depths is a fire elemental in a lava chamber?", a = "incendius" },
    { q = "What key is required to open the prison cells in Blackrock Depths?", a = "shadowforge key" },
    { q = "Who is the elemental boss guarding the Black Anvil in Blackrock Depths?", a = "lord incendius" },
    { q = "What is the name of the arena-style event with random bosses in Blackrock Depths?", a = "ring of law" },
    { q = "Which boss in Blackrock Depths drops the Ironfoe mace?", a = "emperor thaurissan" },
    { q = "What boss performs trials in the Ring of Law?", a = "high interrogator gerstahn" },
    { q = "What is the name of the gnome imprisoned by the Dark Iron dwarves in BRD?", a = "kernobee" },
    { q = "What is the name of the construct boss guarding the vault in Blackrock Depths?", a = "fineous darkvire" },
    { q = "Which NPC can teleport players to the Molten Core from within Blackrock Depths?", a = "lothos riftwaker" },
    { q = "What is the name of the lava-filled forge in Blackrock Depths?", a = "black anvil" },
    { q = "What is the name of the main residential area inside Blackrock Depths?", a = "shadowforge city" },
    { q = "What is the name of the fiery golem boss in the Grim Guzzler?", a = "plugger spazzring" },
    { q = "What item is used to summon the boss from the vault in Blackrock Depths?", a = "coffer key" },
    { q = "Who is the king of the Dark Iron dwarves?", a = "emperor thaurissan" },
    { q = "Which boss drops the Hand of Justice trinket in Blackrock Depths?", a = "general angerforge" },
    { q = "What is the name of the necromantic school located in Western Plaguelands?", a = "scholomance" },
    { q = "Who is the headmaster of Scholomance?", a = "darkmaster gandling" },
    { q = "What undead creature is Gandling known for summoning during his fight?", a = "skeletons" },
    { q = "What is the name of the lich boss found in the Great Ossuary of Scholomance?", a = "ras frostwhisper" },
    { q = "What is the name of the room where Ras Frostwhisper is fought?", a = "the ossuary" },
    { q = "What cult runs Scholomance?", a = "cult of the damned" },
    { q = "What is the name of the ghost boss who drops the Soulstealer's Bindings?", a = "kirtonos the herald" },
    { q = "Which boss in Scholomance uses bats in her encounter?", a = "lady illucia barov" },
    { q = "Which item is used to summon Kirtonos the Herald?", a = "blood of innocents" },
    { q = "What is the name of the crypt where Scholomance is hidden?", a = "caer darrow" },
    { q = "Which boss guards the Viewing Room in Scholomance?", a = "alexei barov" },
    { q = "Which boss pair rules over the Viewing Room?", a = "the barov family" },
    { q = "What is the name of the female ghost boss in Scholomance?", a = "jandice barov" },
    { q = "What is Jandice Barov known for doing during her encounter?", a = "duplicating herself" },
    { q = "What item is required to open the hidden door to Ras Frostwhisper?", a = "skeleton key" },
    { q = "What type of magic is Ras Frostwhisper most associated with?", a = "frost" },
    { q = "What is the name of the area where summoners perform dark rituals in Scholomance?", a = "summoning room" },
    { q = "What class-specific questline leads players into Scholomance for a robe?", a = "warlock" },
    { q = "Who gives the original quest to infiltrate Scholomance?", a = "commander ashlam valorfist" },
    { q = "What is the name of the imprisoned instructor in Scholomance who teaches necromancy?", a = "instructor malicia" },
    { q = "What is the name of the human city overrun by undead in the Eastern Plaguelands?", a = "stratholme" },
    { q = "What is the name of the final boss in Stratholme's undead side?", a = "baron rivendare" },
    { q = "What type of mount does Baron Rivendare ride?", a = "deathcharger" },
    { q = "What is the name of the undead horse that can drop as a mount in Stratholme?", a = "deathcharger's reins" },
    { q = "Which boss in Stratholme leads the Crimson Legion?", a = "balnazzar" },
    { q = "What demonic boss disguises himself as Grand Crusader Dathrohan?", a = "balnazzar" },
    { q = "What is the name of the gate separating Stratholme’s Scarlet and undead wings?", a = "elders' square" },
    { q = "Who leads the Scarlet Crusade in Stratholme?", a = "grand crusader dathrohan" },
    { q = "What is the name of the key needed to open Stratholme’s side gates?", a = "key to the city" },
    { q = "What is the name of the room where Baron Rivendare is fought?", a = "service entrance" },
    { q = "What boss in Stratholme summons waves of skeletal minions?", a = "baroness anastari" },
    { q = "Which boss is found inside the chapel of the Scarlet Bastion?", a = "cannon master willey" },
    { q = "Which demon possesses Grand Crusader Dathrohan?", a = "balnazzar" },
    { q = "What boss drops the powerful tank trinket 'Mark of the Champion'?", a = "baron rivendare" },
    { q = "What boss in Stratholme uses a cannon during the fight?", a = "cannon master willey" },
    { q = "What undead banshee boss is found in the city square?", a = "baroness anastari" },
    { q = "What boss uses shadow bolts and raises skeletons from graves?", a = "nerub'enkan" },
    { q = "Which boss guards the ziggurat on the undead side?", a = "maleki the pallid" },
    { q = "What is the name of the elite abomination boss in Stratholme?", a = "ramstein the gorger" },
    { q = "What rare mount can drop from Baron Rivendare?", a = "deathcharger's reins" },
    { q = "What ancient night elf city is Dire Maul built upon?", a = "eadrath" },
    { q = "What is the name of the ogre king found in Dire Maul North?", a = "king gordok" },
    { q = "Which powerful demon is imprisoned in Dire Maul East?", a = "alzzin the wildshaper" },
    { q = "What is the name of the tribute run mechanic involving sparing bosses?", a = "gordok tribute" },
    { q = "Which boss is known for summoning treants and corrupting nature?", a = "alzzin the wildshaper" },
    { q = "What is the name of the imprisoned arcane entity in Dire Maul West?", a = "immol'thar" },
    { q = "Which faction uses Dire Maul West as a prison for Immol'thar?", a = "highborne" },
    { q = "Which boss do you free by deactivating pylons in Dire Maul West?", a = "immol'thar" },
    { q = "What ghostly boss appears after Immol'thar is defeated?", a = "prince tortheldrin" },
    { q = "What is the name of the ogre tribe that controls Dire Maul North?", a = "gordok" },
    { q = "What is the name of the elemental lord who rules over Molten Core?", a = "ragnaros" },
    { q = "Who is the first boss encounter in Molten Core?", a = "lucifron" },
    { q = "What is the name of the water elemental boss in Molten Core?", a = "gehennas" },
    { q = "Which Molten Core boss drops the Eye of Sulfuras?", a = "ragnaros" },
    { q = "What item is required to summon Majordomo Executus?", a = "aqual quintessence" },
    { q = "Which Molten Core boss is known for summoning flamewaker adds?", a = "golemagg the incinerator" },
    { q = "What is the name of the legendary two-handed mace forged from Ragnaros’s essence?", a = "sulfuras, hand of ragnaros" },
    { q = "What is the name of the ancient core hound boss in Molten Core?", a = "magmadar" },
    { q = "Which boss must be defeated before Ragnaros can be summoned?", a = "majordomo executus" },
    { q = "What raid entrance is located deep within Blackrock Mountain?", a = "molten core" },
    { q = "What is the name of the black dragon boss in Onyxia's Lair?", a = "onyxia" },
    { q = "What zone is the entrance to Onyxia’s Lair located in?", a = "dustwallow marsh" },
    { q = "Who is Onyxia's father?", a = "deathwing" },
    { q = "What disguise does Onyxia use while infiltrating Stormwind?", a = "lady katrana prestor" },
    { q = "What is the name of the attunement questline to access Onyxia’s Lair for Alliance players?", a = "the great masquerade" },
    { q = "Which Stormwind noble is revealed to be Onyxia in disguise?", a = "katrana prestor" },
    { q = "What item begins the attunement quest for Horde players?", a = "warlord's command" },
    { q = "What phase of the Onyxia encounter involves her flying into the air?", a = "phase two" },
    { q = "Which class received the Tier 2 helm from Onyxia?", a = "all" },
    { q = "What rare mount can drop from Onyxia?", a = "onyxia's lair scale cloak" },
    { q = "Who is the final boss of Blackwing Lair?", a = "nefarian" },
    { q = "What is the name of the corrupted black dragon who rules Blackwing Lair?", a = "nefarian" },
    { q = "What boss in Blackwing Lair involves controlling the minds of players to destroy eggs?", a = "razorgore the untamed" },
    { q = "What is the name of Nefarian’s sister who appears in Blackwing Lair?", a = "vaelastrasz" },
    { q = "Which boss is known as the 'Broodlord' in Blackwing Lair?", a = "broodlord lashlayer" },
    { q = "What boss uses class call mechanics to disrupt raid groups?", a = "nefarian" },
    { q = "What is the name of the room filled with suppression devices in Blackwing Lair?", a = "suppression room" },
    { q = "What item allows entry to Blackwing Lair through UBRS?", a = "blackhand's command" },
    { q = "Which boss is fought on a platform over lava and uses knockbacks?", a = "chromaggus" },
    { q = "What dragonflight does Nefarian belong to?", a = "black dragonflight" },
    { q = "What is the name of the final boss of Zul'Gurub?", a = "hakkar" },
    { q = "What is the name of the blood god worshiped by the Gurubashi trolls?", a = "hakkar" },
    { q = "Which boss in Zul’Gurub is associated with bats?", a = "jindo the hexxer" },
    { q = "What is the name of the tiger boss in Zul'Gurub?", a = "high priest thekal" },
    { q = "What mount can drop from High Priest Thekal?", a = "zulian tiger" },
    { q = "Which faction sends players into Zul’Gurub for reputation rewards?", a = "zandalar tribe" },
    { q = "What item drops from Hakkar and is used to summon world buffs?", a = "heart of hakkar" },
    { q = "Which boss must be killed within a time window or resurrects?", a = "high priest thekal" },
    { q = "What rare raptor mount drops in Zul'Gurub?", a = "raptor reins" },
    { q = "What is the name of the bat-riding priestess in Zul'Gurub?", a = "high priestess jeklik" },
    { q = "What fortress serves as the Horde's main base in Hellfire Peninsula?", a = "thrallmar" },
    { q = "What is the name of the Alliance stronghold in Hellfire Peninsula?", a = "honor hold" },
    { q = "What massive structure connects Hellfire Peninsula to the rest of Outland?", a = "the dark portal" },
    { q = "Who is the pit lord commander of the Legion forces in Hellfire Peninsula?", a = "magtheridon" },
    { q = "What is the name of the winged fel orc leader in Hellfire Citadel?", a = "kargath bladefist" },
    { q = "What prison lies beneath Hellfire Citadel?", a = "the shattered halls" },
    { q = "What fel-infused crystals rain from the sky in Hellfire Peninsula?", a = "hellfire spineleaf" },
    { q = "Which demon hunter NPC is found battling Legion forces in Hellfire Peninsula?", a = "altruis the sufferer" },
    { q = "What is the name of the first Outland PvP zone objective in Hellfire?", a = "hellfire fortifications" },
    { q = "Which Naaru leads the Alliance efforts in Hellfire Peninsula?", a = "kaaru" },
    { q = "What native species of giants control water flow in Zangarmarsh?", a = "coilfang naga" },
    { q = "What is the name of the central fungal basin in Zangarmarsh?", a = "serpent lake" },
    { q = "Which raid is located within Coilfang Reservoir?", a = "serpentshrine cavern" },
    { q = "Which Draenei city is built around a mushroom in Zangarmarsh?", a = "telredor" },
    { q = "Which Horde-aligned outpost is located on the north side of Zangarmarsh?", a = "zabra'jin" },
    { q = "Who is the naga matron ruling over Serpentshrine Cavern?", a = "lady vashj" },
    { q = "What environmental resource is being drained by the naga in Zangarmarsh?", a = "water" },
    { q = "What spore-based faction resides in Zangarmarsh?", a = "sporeggar" },
    { q = "What is the name of the heroic dungeon in Zangarmarsh where you confront hydras and naga?", a = "underbog" },
    { q = "Which creatures explode upon death and are used for Sporeggar rep farming?", a = "fungal giants" },
    { q = "What ancient draenei city lies in ruins at the heart of Terokkar Forest?", a = "auchindoun" },
    { q = "Which avian race is native to Skettis in Terokkar?", a = "arakkoa" },
    { q = "What is the name of the bone-strewn canyon near Auchindoun?", a = "bone wastes" },
    { q = "What is the neutral city shared by both factions in Terokkar?", a = "shattrath" },
    { q = "Which Naaru leads the Aldor faction in Shattrath?", a = "kaaru" },
    { q = "What rival faction opposes the Aldor in Shattrath?", a = "scryers" },
    { q = "What secretive faction resides in Skettis?", a = "the arakkoa" },
    { q = "Which dungeon in Auchindoun involves disrupting a dark summoning ritual?", a = "shadow labyrinth" },
    { q = "What is the name of the spy-themed dungeon inside Auchindoun?", a = "mana tombs" },
    { q = "Which imprisoned demon is the final boss in Shadow Labyrinth?", a = "murmur" },
    { q = "What is the name of the orc city located in Nagrand?", a = "garadar" },
    { q = "Which ogre faction inhabits the area north of Halaa?", a = "warmaul" },
    { q = "What is the name of the PvP-contested town in Nagrand?", a = "halaa" },
    { q = "Which elemental spirits do the orcs of Nagrand revere?", a = "ancestors" },
    { q = "What is the name of the elite gronn encountered in Nagrand?", a = "gruul the dragonkiller" },
    { q = "What floating islands dominate the sky above Nagrand?", a = "elemental platforms" },
    { q = "Which famous orc shaman gives quests in Garadar?", a = "greatmother geyah" },
    { q = "Who is the leader of the Broken warriors near Telaar?", a = "nobundo" },
    { q = "Which rare elite is a clefthoof matriarch in Nagrand?", a = "bach'lor" },
    { q = "What is the name of the arena located in Nagrand?", a = "ring of trials" },
    { q = "What dragonflight has a presence in Blade's Edge Mountains?", a = "netherwing" },
    { q = "Which orc clan resides in the stronghold of Thunderlord Village?", a = "thunderlord" },
    { q = "What is the name of the ogre capital in Blade's Edge?", a = "ogri'la" },
    { q = "What creature impales dragons on spikes throughout the zone?", a = "gronn" },
    { q = "Which Naaru-led faction is based in the Skyguard outposts?", a = "sha'tari skyguard" },
    { q = "Which infamous pit lord's children are hunted in Blade's Edge quests?", a = "gruul" },
    { q = "What is the name of the Alliance outpost in Blade’s Edge?", a = "evergrove" },
    { q = "Which area is the base of operations for the ogres of Ogri'la?", a = "blade's edge plateau" },
    { q = "What is the name of the arena event inside Gruul’s Lair?", a = "high king maulgar" },
    { q = "Which creatures have enslaved the nether dragons in Blade’s Edge?", a = "dragonmaw orcs" },
    { q = "What is the name of the floating Naaru base in Netherstorm?", a = "area 52" },
    { q = "What is the name of the raid instance located in Netherstorm?", a = "the eye" },
    { q = "Which blood elf prince commands the Eye?", a = "kael'thas sunstrider" },
    { q = "What are the massive purple domes scattered throughout Netherstorm called?", a = "eco-domes" },
    { q = "Which ethereal faction conducts arcane experiments in the area?", a = "consortium" },
    { q = "What is the name of the Arcane Sanctum leading into Tempest Keep?", a = "the botanica" },
    { q = "Which gnome town is located near the Eye?", a = "area 52" },
    { q = "Which dungeon in Tempest Keep is overrun with constructs?", a = "the mechanar" },
    { q = "What is the name of the Naaru ship taken over by Kael'thas?", a = "tempest keep" },
    { q = "What floating island in Netherstorm houses the Eye?", a = "the tempest keep" },
    { q = "What is the name of Illidan’s fortress in Shadowmoon Valley?", a = "black temple" },
    { q = "Which ancient draenei holy site lies in ruins in Shadowmoon Valley?", a = "karabor" },
    { q = "What is the name of the massive volcano in Shadowmoon Valley?", a = "the hand of gul'dan" },
    { q = "Which fel orc faction serves Illidan in Shadowmoon?", a = "shadowmoon clan" },
    { q = "What is the name of the Aldor outpost in Shadowmoon?", a = "altar of sha'tar" },
    { q = "Which Naaru leads the Scryers' presence in Shadowmoon?", a = "seer kanai" },
    { q = "Which boss rules the Black Temple raid?", a = "illidan stormrage" },
    { q = "What demon hunter ally can be found aiding the Scryers?", a = "altruis the sufferer" },
    { q = "Which elite outdoor dragon patrols near the Black Temple?", a = "doomwalker" },
    { q = "What is the name of the Ata'mal crystals' location?", a = "ata'mal terrace" },
    { q = "What is the name of the main Alliance stronghold in Borean Tundra?", a = "valiance keep" },
    { q = "Which tauren tribe resides in Borean Tundra?", a = "taunka" },
    { q = "What is the name of the Horde base in Borean Tundra?", a = "warsong hold" },
    { q = "Which dragonflight has a presence at the Coldarra?", a = "blue dragonflight" },
    { q = "Who is the blue dragon aspect residing in the Nexus?", a = "malygos" },
    { q = "What is the name of the Kirin Tor agent found in Coldarra?", a = "keristrasza" },
    { q = "What is the name of the nerubian fortress in southern Borean Tundra?", a = "azjol-nerub" },
    { q = "What icy cave system houses the gnome base Fizzcrank Airstrip?", a = "the geyser fields" },
    { q = "What Titan facility is buried beneath the region near Coldarra?", a = "the nexus" },
    { q = "What is the name of the floating island home to Malygos?", a = "coldarra" },
    { q = "What is the name of the vrykul capital in Howling Fjord?", a = "utgarde keep" },
    { q = "What is the main Alliance town in Howling Fjord?", a = "valgarde" },
    { q = "What is the name of the Horde settlement on the cliffs of Howling Fjord?", a = "vengeance landing" },
    { q = "Which dragonflight is tied to the drake riders in Utgarde?", a = "proto-dragons" },
    { q = "What is the name of the Titan watchers' excavation site in Howling Fjord?", a = "baelgun's excavation site" },
    { q = "What vrykul king rules from Utgarde Keep?", a = "ymiron" },
    { q = "What is the name of the sea witch who leads the kvaldir?", a = "skeld drakewing" },
    { q = "Which elite proto-drake is encountered outside Utgarde Pinnacle?", a = "skadi the ruthless" },
    { q = "What ancient order conducts necromantic rituals in the fjord?", a = "the scourge" },
    { q = "Which faction's airship crashes near the fjord’s cliffs?", a = "skybreaker" },
    { q = "What is the name of the drakkari fortress in Grizzly Hills?", a = "drak'tharon keep" },
    { q = "Which furbolg tribe is native to Grizzly Hills?", a = "graymist" },
    { q = "Which group of worgen stalks the forest of Grizzly Hills?", a = "bloodmoon cultists" },
    { q = "What is the name of the Horde base in Grizzly Hills?", a = "conquest hold" },
    { q = "Which ancient barrow holds imprisoned furbolg spirits?", a = "ursoc's den" },
    { q = "Which ancient bear spirit is resurrected in Grizzly Hills?", a = "ursoc" },
    { q = "What river cuts through the middle of Grizzly Hills?", a = "blue sky logging grounds" },
    { q = "Which Titan construct guards a path to Zul'Drak?", a = "drakuru" },
    { q = "Which Alliance settlement is located in the central hills?", a = "amberpine lodge" },
    { q = "What is the name of the PvP zone in Grizzly Hills?", a = "venture bay" },
    { q = "What is the name of the ancient dragon burial site in Dragonblight?", a = "dragonblight" },
    { q = "Which Wyrmrest Temple leader belongs to the red dragonflight?", a = "alexstrasza" },
    { q = "Which Lich King fortress looms over northern Dragonblight?", a = "naxxramas" },
    { q = "What is the name of the event where the Wrathgate opens?", a = "the wrathgate" },
    { q = "Which faction betrays the Horde at the Wrathgate?", a = "royal apothecary society" },
    { q = "Who is the leader of the bronze dragonflight present in Dragonblight?", a = "nozdormu" },
    { q = "What is the name of the blue dragonflight stronghold in Dragonblight?", a = "the nexus" },
    { q = "Which city is the Horde's primary base in Dragonblight?", a = "agmar's hammer" },
    { q = "What is the name of the Titan keeper buried beneath Wyrmrest Temple?", a = "galakrond" },
    { q = "Which Alliance base is closest to the Wrathgate?", a = "fordragon hold" },
    { q = "What is the name of the massive troll city in Zul'Drak?", a = "gundrak" },
    { q = "Which troll tribe dominates Zul'Drak?", a = "drakkari" },
    { q = "What is the name of the loa god of death in Zul'Drak?", a = "mamm'toth" },
    { q = "What is the name of the frost troll demigod sacrificed by the Drakkari?", a = "rhunok" },
    { q = "What is the final boss of the Gundrak dungeon?", a = "gal'darah" },
    { q = "Which zone borders Zul'Drak to the west?", a = "grizzly hills" },
    { q = "Which undead faction invades Zul'Drak from Icecrown?", a = "the scourge" },
    { q = "Which neutral faction opposes the Drakkari in Zul'Drak?", a = "argent crusade" },
    { q = "What is the name of the necropolis hovering over Zul'Drak?", a = "voltarus" },
    { q = "What large troll structure forms a wall across southern Zul'Drak?", a = "the drak'sotra" },
    { q = "Which two factions compete for control in Sholazar Basin?", a = "oracle and frenzyheart" },
    { q = "Which Titan facility lies hidden in Sholazar Basin?", a = "the makers' overlook" },
    { q = "Which Titan keeper is imprisoned in Sholazar Basin?", a = "freya" },
    { q = "What is the name of the gorloc faction in Sholazar?", a = "the oracles" },
    { q = "What is the name of the aggressive wolvar tribe in Sholazar?", a = "frenzyheart" },
    { q = "Which Titan facility connects Sholazar to Storm Peaks?", a = "the makers' perch" },
    { q = "Which Avatar of a Titan is summoned in the final quest chain?", a = "avatar of freya" },
    { q = "What rare mechanical construct patrols the basin?", a = "ironbound proto-drake" },
    { q = "What is the name of the river that runs through Sholazar?", a = "river's heart" },
    { q = "Which famous NPC falls from the sky in Sholazar?", a = "hemet nesingwary" },
    { q = "What is the name of the massive Titan city in Storm Peaks?", a = "ulduar" },
    { q = "Who is the keeper imprisoned deep within Ulduar?", a = "yogg-saron" },
    { q = "Which Titan construct guards the Archivum in Ulduar?", a = "archivum system" },
    { q = "Which dragonflight has a stronghold called the Temple of Storms?", a = "storm dragons" },
    { q = "Who is the watcher that turns hostile in Ulduar?", a = "loken" },
    { q = "What is the name of Thorim’s mount in Storm Peaks?", a = "veranus" },
    { q = "Which faction operates from K3 in Storm Peaks?", a = "argent crusade" },
    { q = "What is the name of the area where Loken rules?", a = "the halls of lightning" },
    { q = "What is the name of the giant who forged the Keepers' weapons?", a = "brann bronzebeard" },
    { q = "Which imprisoned Old God influences Storm Peaks?", a = "yogg-saron" },
    { q = "What is the name of the Lich King's citadel in Icecrown?", a = "icecrown citadel" },
    { q = "Who leads the Ashen Verdict in Icecrown?", a = "tirion fordring" },
    { q = "What is the name of the elite undead dragon inside Icecrown Citadel?", a = "sindragosa" },
    { q = "Which famous dreadlord is fought in the Frozen Halls?", a = "mal'ganis" },
    { q = "What is the name of the Argent Crusade’s base in Icecrown?", a = "argent vanguard" },
    { q = "Which daily quest hub involves gunships and air combat?", a = "the shadow vault" },
    { q = "What is the name of the area where Bolvar lies imprisoned?", a = "the frozen throne" },
    { q = "Which Scourge general guards the entrance to the Citadel?", a = "deathbringer saurfang" },
    { q = "Which creature is created from blood magic within the Citadel?", a = "blood-queen lana'thel" },
    { q = "What is the name of the gauntlet event with Muradin and Saurfang?", a = "gunship battle" },
    { q = "Which Classic potion restores both health and mana instantly?", a = "major rejuvenation potion" },
    { q = "What is the name of the Classic flask that increases spell power?", a = "flask of supreme power" },
    { q = "Which food buff in Classic increases your stamina by 10?", a = "smoked desert dumplings" },
    { q = "Which elixir in Classic increases agility by 25?", a = "elixir of the mongoose" },
    { q = "Which rare Classic potion makes the user invisible for 18 seconds?", a = "limited invulnerability potion" },
    { q = "What is the name of the Classic flask that increases resistances to all schools?", a = "flask of the titans" },
    { q = "Which potion removes polymorph effects in Classic?", a = "free action potion" },
    { q = "Which Classic elixir boosts fire resistance by 40?", a = "greater fire protection potion" },
    { q = "Which food grants a spirit buff and is cooked with tender wolf meat?", a = "soothing turtle bisque" },
    { q = "Which powerful raid flask increases health by 1200 in Classic?", a = "flask of the titans" },
    { q = "Which TBC flask increases both spell power and healing?", a = "flask of mighty restoration" },
    { q = "Which food buff grants 30 spell power and 20 spirit in TBC?", a = "blackened basilisk" },
    { q = "Which TBC potion restores health and grants a short dodge buff?", a = "fel blossom" },
    { q = "Which TBC elixir increases hit rating?", a = "elixir of major agility" },
    { q = "Which resistance potion is required for Hydross the Unstable?", a = "greater nature protection potion" },
    { q = "Which flask in TBC increases melee attack power by 120?", a = "flask of relentless assault" },
    { q = "Which TBC alchemy discovery flask increases overall stats by 20?", a = "flask of chromatic wonder" },
    { q = "Which food in TBC increases stamina and spirit and is made with talbuk meat?", a = "talbuk steak" },
    { q = "Which TBC potion reduces threat generation?", a = "fel mana potion" },
    { q = "Which elixir in TBC boosts armor and is often used by tanks?", a = "elixir of major defense" },
    { q = "Which Wrath flask increases spell power by 125?", a = "flask of the frost wyrm" },
    { q = "Which Wrath food grants 40 spell power and 40 stamina?", a = "firecracker salmon" },
    { q = "Which potion instantly restores 3,000 mana in Wrath?", a = "runic mana potion" },
    { q = "Which flask in Wrath boosts attack power by 180?", a = "flask of endless rage" },
    { q = "Which Wrath food gives 40 strength and is favored by melee DPS?", a = "hearty rhino" },
    { q = "What is the name of the powerful Wrath healing potion?", a = "runic healing potion" },
    { q = "Which Wrath elixir boosts critical strike rating and is made with icethorn?", a = "elixir of deadly strikes" },
    { q = "Which Wrath flask boosts HP by 1300 and is used by tanks?", a = "flask of stoneblood" },
    { q = "Which Wrath recipe allows cooking a feast for 5 people?", a = "great feast" },
    { q = "Which flask in Wrath grants bonus to all stats and persists through death?", a = "flask of the north" },
    { q = "Which rare Blacksmithing item grants immunity to fear effects in Classic?", a = "stronghold gauntlets" },
    { q = "Which Classic gathering profession allows harvesting Fadeleaf?", a = "herbalism" },
    { q = "Which Engineering item in Classic creates a target dummy?", a = "ez-thro dynamite" },
    { q = "Which profession creates the Arcanite Reaper?", a = "blacksmithing" },
    { q = "Which Classic cooking recipe restores health and grants a 10 spirit buff?", a = "dragonbreath chili" },
    { q = "Which Leatherworking armor set boosts fire resistance and is used in Molten Core?", a = "fire resistance gear" },
    { q = "Which rare tailoring set increases intellect and spell damage in Classic?", a = "truefaith vestments" },
    { q = "Which Classic Engineering item teleports the user to Gadgetzan?", a = "goblin transporter" },
    { q = "Which Classic crafting profession allows creation of Darkmoon Cards?", a = "inscription" },
    { q = "Which profession creates the Goblin Rocket Helmet?", a = "engineering" },
    { q = "Which profession crafts epic BoP weapons like Dragonstrike and Lionheart Executioner in TBC?", a = "blacksmithing" },
    { q = "Which specialization in Leatherworking focuses on elemental resist gear?", a = "elemental leatherworking" },
    { q = "Which TBC profession crafts spellthread for tailors’ pants?", a = "tailoring" },
    { q = "Which profession allows you to cut the Crimson Spinel gem?", a = "jewelcrafting" },
    { q = "Which TBC gathering profession is required to mine Khorium?", a = "mining" },
    { q = "Which TBC profession creates the epic Flying Machine mount?", a = "engineering" },
    { q = "Which TBC leatherworking set is highly sought after for rogues and hunters?", a = "nethercobra set" },
    { q = "Which TBC recipe creates the Flask of Chromatic Wonder?", a = "alchemy" },
    { q = "Which tailoring specialization is required to craft the Primal Mooncloth set?", a = "mooncloth tailoring" },
    { q = "Which crafting profession is required to make the Figurine: Living Ruby Serpent?", a = "jewelcrafting" },
    { q = "Which Wrath crafting profession creates leg enchants like Sapphire Spellthread?", a = "tailoring" },
    { q = "Which Wrath profession unlocks epic rings like Runed Signet of the Kirin Tor?", a = "jewelcrafting" },
    { q = "Which Wrath profession provides Nitro Boosts as a belt enchant?", a = "engineering" },
    { q = "Which Wrath profession grants passive bonuses from Mixology?", a = "alchemy" },
    { q = "Which Wrath gathering profession can extract Crystallized Life from herbs?", a = "herbalism" },
    { q = "Which profession creates the epic flying mount Mechano-Hog?", a = "engineering" },
    { q = "Which Wrath-only profession uses pigments to craft glyphs?", a = "inscription" },
    { q = "Which profession lets you create Iceblade Arrows?", a = "engineering" },
    { q = "Which Wrath tailoring set is ideal for healers and grants spirit and intellect?", a = "glacial set" },
    { q = "Which Wrath profession-specific bonus grants additional sockets?", a = "blacksmithing" },
    { q = "What is the name of the epic nether drake mount earned from the Netherwing faction?", a = "reins of the violet netherwing drake" },
    { q = "Which rare mount drops from Kael'thas Sunstrider in Magisters' Terrace?", a = "ashes of al'ar" },
    { q = "Which talbuk mount is unlocked through exalted reputation with the Mag'har?", a = "great white talbuk" },
    { q = "Which PvP flying mount is awarded from Arena Season 1 Gladiator rank?", a = "merciless gladiator's nether drake" },
    { q = "Which TBC mount is earned through Cenarion Expedition reputation?", a = "cenarion war hippogryph" },
    { q = "Which large flying mount is sold in Shadowmoon Valley after obtaining Artisan Riding?", a = "swift red gryphon" },
    { q = "Which giant elephant-like mount can be purchased in Nagrand?", a = "great grey elekk" },
    { q = "Which Engineering-only flying mount is crafted in TBC?", a = "flying machine" },
    { q = "Which red riding nether ray is bought from Sha'tari Skyguard?", a = "swift red nether ray" },
    { q = "Which rare blue drake mount drops from Malygos in The Eye of Eternity?", a = "reins of the blue drake" },
    { q = "Which Time-Lost flying mount drops from a rare spawn in Storm Peaks?", a = "reins of the time-lost proto-drake" },
    { q = "Which mount drops from Sartharion with three drakes alive?", a = "reins of the black drake" },
    { q = "Which epic flying mount is a reward for completing the Wrath Dungeon Hero meta-achievement?", a = "red proto-drake" },
    { q = "Which skeletal drake mount is awarded for completing Glory of the Raider (10-player)?", a = "plagued proto-drake" },
    { q = "Which frostwyrm is awarded for completing the Icecrown Citadel 25-player meta?", a = "icy blue proto-drake" },
    { q = "Which sea turtle mount is fished up during Northrend fishing?", a = "sea turtle" },
    { q = "Which Argent Tournament faction grants access to the Silver Covenant Hippogryph?", a = "the silver covenant" },
    { q = "Which mount drops from Skadi the Ruthless in Utgarde Pinnacle?", a = "reins of the blue proto-drake" },
    { q = "Which Engineering-only ground mount was added in Wrath?", a = "mechano-hog" },
    { q = "What is the name of the epic undead horse mount from Baron Rivendare?", a = "deathcharger's reins" },
    { q = "Which rare raptor mount drops in Zul'Gurub?", a = "swift razzashi raptor" },
    { q = "Which epic mount is a reward from the Alterac Valley Stormpike faction?", a = "stormpike battle charger" },
    { q = "Which black-colored mechanical mount drops from Gnomeregan?", a = "mechanostrider" },
    { q = "Which epic tiger mount drops from High Priest Thekal?", a = "swift zulian tiger" },
    { q = "Which mount requires exalted reputation with Darnassus?", a = "swift frostsaber" },
    { q = "Which PvP mount is purchased with rank 11 in Classic's honor system?", a = "black war steed" },
    { q = "Which black dragon mount was a reward for completing the Blackwing Lair questline?", a = "black qiraji resonating crystal" },
    { q = "What stance must a Warrior be in to use Overpower?", a = "battle stance" },
    { q = "Which Warrior ability generates rage when struck by enemies?", a = "bloodrage" },
    { q = "Which Classic Warrior quest rewards the Whirlwind Axe?", a = "whirlwind weapon quest" },
    { q = "Which Warrior ability is used to interrupt spellcasting?", a = "pummel" },
    { q = "What is the name of the Warrior’s taunt that hits 3 nearby enemies?", a = "challenging shout" },
    { q = "Which talent tree provides the Mortal Strike ability?", a = "arms" },
    { q = "Which racial ability synergizes well with Warrior’s rage generation?", a = "berserking" },
    { q = "Which Warrior shout increases attack power for the party?", a = "battle shout" },
    { q = "Which Classic Warrior ability reduces threat temporarily?", a = "fading shout" },
    { q = "Which weapon type benefits from the Poleaxe Specialization talent?", a = "axes" },
    { q = "Which Mage spell conjures food for mana regeneration?", a = "conjure food" },
    { q = "Which Classic Mage ability removes curses?", a = "remove lesser curse" },
    { q = "Which Mage spell can teleport the caster to Ironforge?", a = "teleport: ironforge" },
    { q = "Which Mage specialization focuses on Fireball and Pyroblast?", a = "fire" },
    { q = "Which Classic trinket is required for the Mage Water Elemental quest?", a = "crystal of zin-malor" },
    { q = "What ability gives Mages temporary immunity to all magic?", a = "ice block" },
    { q = "Which AOE spell freezes enemies in place for 8 seconds?", a = "frost nova" },
    { q = "What is the name of the Mage’s mana shield spell?", a = "mana shield" },
    { q = "Which spell gives Mages 30% chance to resist spell interruption?", a = "arcane resilience" },
    { q = "Which Classic Mage item is used to complete the Wand of Biting Cold quest?", a = "soul shard of the banished" },
    { q = "Which Warlock pet is used primarily for tanking?", a = "voidwalker" },
    { q = "Which Classic Warlock quest rewards the Dreadsteed mount?", a = "dreadsteed questline" },
    { q = "Which Warlock curse reduces healing effects on the target?", a = "curse of tongues" },
    { q = "Which talent tree allows Warlocks to summon a Felguard?", a = "demonology" },
    { q = "Which Warlock spell drains health from the target?", a = "drain life" },
    { q = "Which Warlock debuff causes periodic fire damage?", a = "immolate" },
    { q = "Which reagent is required for summoning demons?", a = "soul shard" },
    { q = "Which Classic Warlock ability sacrifices the Voidwalker to gain a shield?", a = "sacrifice" },
    { q = "Which Warlock spell summons a group member to their location?", a = "ritual of summoning" },
    { q = "Which Warlock racial mount is visually different from others?", a = "felsteed" },
    { q = "Which Hunter ability allows the taming of beasts?", a = "tame beast" },
    { q = "Which Classic Hunter quest rewards the Rhok'delar bow?", a = "ancient sinew wrapped lamina questline" },
    { q = "Which Hunter trap deals fire damage over time?", a = "immolation trap" },
    { q = "Which Hunter ability increases movement speed after a critical hit?", a = "pathfinding" },
    { q = "What is the name of the Hunter’s melee attack that slows the target?", a = "wing clip" },
    { q = "Which Hunter pet family can learn Dash and Bite in Classic?", a = "cats" },
    { q = "Which Hunter aspect regenerates mana while out of combat?", a = "aspect of the viper" },
    { q = "Which consumable is required to feed your pet?", a = "food" },
    { q = "Which ranged weapon is rewarded from the quest in Molten Core?", a = "rhok'delar" },
    { q = "Which Hunter ability increases ranged critical strike chance?", a = "trueshot aura" },
    { q = "Which Paladin ability grants immunity to all damage?", a = "divine shield" },
    { q = "Which Paladin mount is earned through a quest at level 60?", a = "charger" },
    { q = "Which Paladin seal restores mana on melee hit?", a = "seal of wisdom" },
    { q = "Which blessing increases a target’s mana regeneration?", a = "blessing of wisdom" },
    { q = "Which Classic talent tree gives access to Holy Shock?", a = "holy" },
    { q = "Which Paladin aura reflects holy damage to attackers?", a = "retribution aura" },
    { q = "Which Paladin ability reduces all damage taken by the group?", a = "blessing of sanctuary" },
    { q = "Which Paladin spell resurrects a dead player?", a = "redemption" },
    { q = "Which Alliance race is the only one that can be a Paladin in Classic?", a = "dwarf" },
    { q = "Which Paladin judgment reduces the target’s attack speed?", a = "judgement of the crusader" },
    { q = "Which Rogue ability allows opening of locked chests and doors?", a = "lockpicking" },
    { q = "Which Rogue skill requires being behind the target to use?", a = "backstab" },
    { q = "Which finishing move stuns the enemy based on combo points?", a = "kidney shot" },
    { q = "Which Rogue poison slows movement speed?", a = "crippling poison" },
    { q = "Which Classic Rogue quest rewards the Thistle Tea recipe?", a = "venom questline" },
    { q = "Which Rogue talent allows opening with Garrote from stealth while invisible?", a = "camouflage" },
    { q = "Which Rogue racial bonus increases stealth level?", a = "shadowmeld" },
    { q = "Which Rogue ability resets the cooldown of all abilities?", a = "preparation" },
    { q = "Which Rogue specialization tree improves poisons and daggers?", a = "assassination" },
    { q = "Which Rogue ability removes all movement impairing effects?", a = "vanish" },
    { q = "Which Priest spell restores health over time to a friendly target?", a = "renew" },
    { q = "Which ability lets Priests reduce damage taken on a target?", a = "power word: shield" },
    { q = "Which Classic Priest racial spell is unique to Dwarves?", a = "fear ward" },
    { q = "Which Classic Priest spell increases spell damage and healing?", a = "shadowform" },
    { q = "Which Priest quest rewards the Benediction staff?", a = "anathema/benediction questline" },
    { q = "Which Priest spell reduces an enemy’s healing received?", a = "mana burn" },
    { q = "Which Classic Priest racial spell is exclusive to Undead?", a = "devouring plague" },
    { q = "Which Classic talent tree focuses on Holy Nova and healing?", a = "holy" },
    { q = "Which spell allows a Priest to resurrect a dead player?", a = "resurrection" },
    { q = "Which ability breaks fear and is often used in PvP?", a = "desperate prayer" },
    { q = "Which Shaman weapon buff adds extra Nature damage on hit?", a = "rockbiter weapon" },
    { q = "Which Shaman totem removes poison effects?", a = "poison cleansing totem" },
    { q = "Which talent enables Shaman to dual wield weapons?", a = "dual wield" },
    { q = "Which Shaman ability restores mana to party members?", a = "mana spring totem" },
    { q = "Which totem slows enemies that attack the Shaman?", a = "earthbind totem" },
    { q = "Which Classic Shaman questline rewards the Water Totem?", a = "call of water" },
    { q = "Which weapon enchant causes wind-based procs and extra attacks?", a = "windfury weapon" },
    { q = "Which Shaman shock spell interrupts spellcasting?", a = "earth shock" },
    { q = "Which Shaman talent reduces the cast time of Lightning Bolt?", a = "convection" },
    { q = "Which Druid form is used for stealth and melee DPS?", a = "cat form" },
    { q = "Which Druid form provides high armor and threat generation?", a = "bear form" },
    { q = "Which Classic Druid spell allows swimming and breathing underwater?", a = "aquatic form" },
    { q = "Which Druid travel form becomes available at level 30?", a = "travel form" },
    { q = "Which Classic Druid talent allows shifting forms to remove snare effects?", a = "nature's grasp" },
    { q = "Which Druid ability restores mana and health over time to party members?", a = "innervate" },
    { q = "Which Druid spell can resurrect a dead player in combat?", a = "rebirth" },
    { q = "Which Druid talent tree focuses on healing spells?", a = "restoration" },
    { q = "Which Alliance race is the only one that can be a Druid in Classic?", a = "night elf" },
    { q = "Which Classic Druid ability roots enemies in place?", a = "entangling roots" },
}

shuffle(trivia)

local currentQuestionIndex = 0
local questionTimer = 0
local answered = false
local nextQuestionDelay = 0
local noAnswerPending = false

local function SyncNearbyFollowerEmote(sourceCreature, emoteId)
    local nearby = sourceCreature:GetCreaturesInRange(EMOTE_RADIUS)
    for _, npc in ipairs(nearby) do
        if npc:GetEntry() == FOLLOWER_NPC_ENTRY then
            npc:PerformEmote(emoteId)
        end
    end
end
-- Trivia logic
local function AskNextQuestion(creature)
    currentQuestionIndex = math.random(1, #trivia)
    answered = false
    questionTimer = QUESTION_INTERVAL
    local q = trivia[currentQuestionIndex].q
    creature:SendUnitSay("[Trivia] " .. q, 0)
    creature:PerformEmote(1)
    SyncNearbyFollowerEmote(creature, 0)
end

local function OnUpdate(eventId, delay, calls, creature)
    if nextQuestionDelay > 0 then
        nextQuestionDelay = nextQuestionDelay - (delay / 1000)
        return
    end

    if questionTimer <= 0 or answered then
        AskNextQuestion(creature)
        lastCountdownTime = QUESTION_INTERVAL
    else
        questionTimer = questionTimer - (delay / 1000)

        -- Countdown announcement every 10 seconds
        local roundedTime = math.floor(questionTimer)
        if roundedTime > 0 and roundedTime % 10 == 0 and roundedTime < lastCountdownTime then
            creature:SendUnitSay("[Trivia] " .. roundedTime .. " seconds remaining!", 0)
            creature:PerformEmote(10)
            SyncNearbyFollowerEmote(creature, 10)
            lastCountdownTime = roundedTime
        end
    end
end


-- Listen to /say and check for answers
local function OnPlayerSay(event, player, msg, type, lang)
    if type ~= CHAT_MSG_SAY or currentQuestionIndex == 0 or answered then return end

    local lowerMsg = string.lower(msg)
    local answer = trivia[currentQuestionIndex].a

    if lowerMsg ~= answer then return end

    local playerName = player:GetName()
    local guid = player:GetGUIDLow()

    -- Check if NPC is nearby
    local nearby = player:GetCreaturesInRange(LISTEN_RADIUS)
    for _, creature in ipairs(nearby) do
        if creature:GetEntry() == NPC_ENTRY then
            answered = true
            nextQuestionDelay = ANSWER_DELAY
            questionTimer = 0
            -- Cast spell 54395 on the player
            creature:CastSpell(player, 54395, true)
            creature:CastSpell(player, 25465, true)
            -- Check if player already exists
            local row = CharDBQuery("SELECT correct_answers, streak FROM quizmaster_stats WHERE player_id = " .. guid)
            local newScore = 1
            local newStreak = 1

            if row then
                local oldStreak = row:GetUInt32(1)
                newStreak = oldStreak + 1
                CharDBExecute("UPDATE quizmaster_stats SET correct_answers = correct_answers + 1, streak = " .. newStreak .. " WHERE player_id = " .. guid)
            else
                CharDBExecute("INSERT INTO quizmaster_stats (player_id, correct_answers, streak) VALUES (" .. guid .. ", 1, 1)")
            end

            -- Reset streaks for all other players
            CharDBExecute("UPDATE quizmaster_stats SET streak = 0 WHERE player_id != " .. guid .. " AND streak > 0")

            -- Re-fetch to display updated correct_answers
            local updated = CharDBQuery("SELECT correct_answers FROM quizmaster_stats WHERE player_id = " .. guid)
            if updated then
                newScore = updated:GetUInt32(0)
            end
            creature:SendUnitSay("[Trivia] The correct answer was... ", 0)

            creature:RegisterEvent(function(eventId, delay, calls, delCreature)
                delCreature:SendUnitSay("[Trivia] '" .. answer.. "', " .. playerName .. " got the right answer! Total correct: " .. newScore .. ", Streak: " .. newStreak, 0)
                delCreature:PerformEmote(4)
            end, 1000, 1)
            SyncNearbyFollowerEmote(creature, 4)


            break
        end
    end

    -- Progressive hint logic
    local revealedLetters = {}

    local function ResetMaskedAnswer(answer)
        revealedLetters = {}
        for i = 1, #answer do
            revealedLetters[i] = false
        end
    end

    local function RevealNextLetters(answer)
        local unrevealed = {}
        for i = 1, #answer do
            if not revealedLetters[i] and answer:sub(i, i) ~= " " then
                table.insert(unrevealed, i)
            end
        end

        local toReveal = math.max(1, math.floor(#answer * 0.1))
        for i = 1, math.min(toReveal, #unrevealed) do
            local idx = table.remove(unrevealed, math.random(1, #unrevealed))
            revealedLetters[idx] = true
        end
    end

    local function GetMaskedAnswer(answer)
        local out = {}
        for i = 1, #answer do
            local ch = answer:sub(i, i)
            if ch == " " then
                table.insert(out, " ")
            elseif revealedLetters[i] then
                table.insert(out, ch)
            else
                table.insert(out, "_")
            end
        end
        return table.concat(out, " ")
    end

    -- Override AskNextQuestion to reset hint tracking
    local originalAskNextQuestion = AskNextQuestion
    AskNextQuestion = function(creature)
        local answer = trivia[currentQuestionIndex] and trivia[currentQuestionIndex].a or ""
        ResetMaskedAnswer(answer)
        originalAskNextQuestion(creature)
    end

    -- Enhance OnUpdate with delayed hint display logic
    local originalOnUpdate = OnUpdate
    OnUpdate = function(eventId, delay, calls, creature)
        local prevCountdown = math.floor(questionTimer)
        originalOnUpdate(eventId, delay, calls, creature)
        local newCountdown = math.floor(questionTimer)

        -- Only do this at valid 10-second intervals and after original logic
        if newCountdown % 10 == 0 and newCountdown > 0 and newCountdown ~= prevCountdown then
            if newCountdown <= 40 then
                local answer = trivia[currentQuestionIndex] and trivia[currentQuestionIndex].a or ""
                RevealNextLetters(answer)
                local masked = GetMaskedAnswer(answer)
                creature:SendUnitSay("[Hint] " .. masked, 0)
            end
            if newCountdown == 10 and not answered then
                creature:RegisterEvent(function(eventId, delay, calls, timedCreature)
                    -- Main NPC says the line and casts its spell
                    timedCreature:SendUnitSay("[Trivia] No correct guesses parsed. Moving on!", 0)
                    timedCreature:CastSpell(timedCreature, FAIL_SPELL_ID, true)  -- Replace CUSTOM_SPELL_ID
                    timedCreature:PerformEmote(18)
                    -- Make all nearby follower NPCs cast spell 71495 on themselves
                    local nearby = timedCreature:GetCreaturesInRange(EMOTE_RADIUS)
                    for _, npc in ipairs(nearby) do
                        if npc:GetEntry() == FOLLOWER_NPC_ENTRY then
                            npc:CastSpell(npc, 71495, true)
                            npc:PerformEmote(18)
                        end
                    end
                end, 8300, 1)
            end
        end
    end



-- Init when creature spawns
local function OnSpawn(event, creature)
    currentQuestionIndex = 0
    questionTimer = 5
    nextQuestionDelay = 0
    creature:RegisterEvent(OnUpdate, 1000, 0)  -- every second
end

RegisterCreatureEvent(NPC_ENTRY, 5, OnSpawn)        -- On spawn
RegisterPlayerEvent(18, OnPlayerSay)                -- On player chat
