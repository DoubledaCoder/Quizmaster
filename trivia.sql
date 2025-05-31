-- Required to keep track of player stats. You do not need to do anything else.
CREATE TABLE `acore_characters`.`quizmaster_stats` (
    `player_id` INT UNSIGNED UNIQUE DEFAULT NULL,
    `correct_answers` INT DEFAULT 0,
    `streak` INT DEFAULT 0
);



---------------------------ACORE_WORLD
-- QUIZMASTER 
-- MUST RUN ALL THESE
DELETE FROM `creature_template` WHERE (`entry` = 2069424);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `scale`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(2069424, 0, 0, 0, 0, 0, 'Logictonk', 'Quizmaster!', '', 0, 1, 1, 0, 1015, 1, 1, 1.14286, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 2, '', 0);

DELETE FROM `creature_template_model` WHERE (`CreatureID` = 2069424) AND (`Idx` IN (0));
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(2069424, 0, 29001, 1, 1, 0);

DELETE FROM `creature_equip_template` WHERE (`CreatureID` = 2069424);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(2069424, 1, 15278, 15278, 15278, 0);


UPDATE `creature_template` SET `npcflag` = 0, `type_flags` = 2 WHERE (`entry` = 2069424);
UPDATE `creature_template` SET `scale` = 0.75 WHERE (`entry` = 2069424);
UPDATE `creature_template` SET `faction` = 35 WHERE (`entry` = 2069424);



--SETUP TEST EXAMPLE ON THE OFF MAP ISLAND OFF COAST OF TANARIS. Not required but best first experience!
-- .go xyz -11820.909 -4747.388 6.90528 1 
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES (5302212, 33880, 0, 0, 1, 0, 0, 1, 1, 0, -11822.2, -4731.42, 6.12463, 5.02987, 300, 0, 0, 5647, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES (5302211, 33880, 0, 0, 1, 0, 0, 1, 1, 0, -11819.4, -4726.58, 6.84722, 4.894, 300, 0, 0, 5647, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES (5302210, 33880, 0, 0, 1, 0, 0, 1, 1, 0, -11827, -4728.08, 6.1179, 4.84766, 300, 0, 0, 5647, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES (5302207, 2069424, 0, 0, 1, 0, 0, 1, 1, 1, -11823.1, -4728.34, 6.2676, 4.90479, 300, 0, 0, 42, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
