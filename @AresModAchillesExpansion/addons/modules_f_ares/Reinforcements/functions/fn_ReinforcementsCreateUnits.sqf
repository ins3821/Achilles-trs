#include "\achilles\modules_f_ares\module_header.hpp"

#define FIRST_SPECIFIC_LZ_OR_RP_OPTION_INDEX 4

disableSerialization;

private _spawnPosition = position _logic;

comment "// allocate data arrays";
private _sides = [];
private _side_names = [];
for "_i" from 0 to 2 do
{
	_sides pushBack (_i call BIS_fnc_sideType);
	_side_names pushBack (_i call BIS_fnc_sideName);
};
if (uiNamespace getVariable ["Achilles_var_nestedList_vehicleFactions", []] isEqualTo []) then
{
	comment "// allocate data arrays";
	private _factions = [];
	private _vehicle_categories = [];
	private _vehicles = [];
	private _groups = [];
	for "_" from 1 to (count _sides) do
	{
		_factions pushBack [];
		_vehicle_categories pushBack [];
		_vehicles pushBack [];
		_groups pushBack [];
	};

	comment "// get all factions";
	{
		private _side_id = [_x, "side", 4] call BIS_fnc_returnConfigEntry;
		if (_side_id <= 2 and _side_id >= 0) then
		{
			(_factions select _side_id) pushBack configName _x;
			(_vehicle_categories select _side_id) pushBack [];
			(_vehicles select _side_id) pushBack [];
			(_groups select _side_id) pushBack [];
		};
	} forEach ((configFile >> "CfgFactionClasses") call Achilles_fnc_returnChildren);
	comment "// sort by display names";
	for "_side_id" from 0 to (count _sides - 1) do
	{
		_factions set [_side_id, [(_factions select _side_id), [], {getText (configfile >> "CfgFactionClasses" >> _x >> "displayName")}] call BIS_fnc_sortBy];
	};

	comment "// get all vehicles";
	{
		private _type = configName _x;
		private _side_id = [_x, "side", 4] call BIS_fnc_returnConfigEntry;
		if ([_x, "scope", 0] call BIS_fnc_returnConfigEntry == 2 and _side_id <= 2) then
		{
			if (_type isKindOf "Tank" or _type isKindOf "Car" or _type isKindOf "Helicopter" or _type isKindOf "Plane"or _type isKindOf "Ship") then
			{
				if (([_type, true] call BIS_fnc_crewCount) - ([_type, false] call BIS_fnc_crewCount) > 0) then
				{
					private _faction = getText (_x >> "faction");
					private _faction_id = (_factions select _side_id) find _faction;
					if (_faction_id >= 0) then
					{
						private _vehicle_category = [_x, "editorSubcategory", "EdSubcat_Default"] call BIS_fnc_returnConfigEntry;
						private _vehicle_category_id = (_vehicle_categories select _side_id select _faction_id) find _vehicle_category;
						if (_vehicle_category_id >= 0) then
						{
							(_vehicles select _side_id select _faction_id select _vehicle_category_id) pushBack _x;
						} else
						{
							(_vehicle_categories select _side_id select _faction_id) pushBack _vehicle_category;
							(_vehicles select _side_id select _faction_id) pushBack [_x];
						};
					};
				};
			};
		};
	} forEach ((configFile >> "CfgVehicles") call Achilles_fnc_returnChildren);

	comment "// get all groups";
	{
		private _side_id = [_x, "side", 4] call BIS_fnc_returnConfigEntry;
		if (_side_id <= 2) then
		{
			private _cfg = _x;
			{
				{
					{
						if ({not (getText (_x >> "vehicle") isKindOf "Man")} count (_x call Achilles_fnc_returnChildren) == 0) then
						{
							private _faction = getText (_x >> "faction");
							private _faction_id = (_factions select _side_id) find _faction;
							if (_faction_id >= 0) then
							{
								(_groups select _side_id select _faction_id) pushBack _x;
							};
						};
					} forEach (_x call Achilles_fnc_returnChildren); comment "// for each group";
				} forEach (_x call Achilles_fnc_returnChildren); comment "// for each group category";
			} forEach (_x call Achilles_fnc_returnChildren); comment "// for each faction";
		};
	} forEach ((configFile >> "CfgGroups") call Achilles_fnc_returnChildren);
	comment "// sort by display names";
	for "_side_id" from 0 to (count _sides - 1) do
	{
		for "_faction_id" from 0 to (count (_factions select _side_id) - 1) do
		{
			(_groups select _side_id) set [_faction_id, [(_groups select _side_id select _faction_id), [], {getText (_x >> "displayName")}] call BIS_fnc_sortBy];
			for "_vehicle_category_id" from 0 to (count (_vehicle_categories select _side_id select _faction_id) - 1) do
			{
				(_vehicles select _side_id select _faction_id) set[_vehicle_category_id, [(_vehicles select _side_id select _faction_id select _vehicle_category_id), [], {getText (_x >> "displayName")}] call BIS_fnc_sortBy];
			};
		};
	};

	comment "// remove empty factions";
	private _vehicle_factions = +_factions;
	private _group_factions = +_factions;
	for "_side_id" from 0 to (count _sides - 1) do
	{
		for "_faction_id" from (count (_factions select _side_id) - 1) to 0 step -1 do
		{
			if (count (_vehicles select _side_id select _faction_id) == 0) then
			{
				(_vehicle_factions select _side_id) deleteAt _faction_id;
				(_vehicle_categories select _side_id) deleteAt _faction_id;
				(_vehicles select _side_id) deleteAt _faction_id;
			};
			if (count (_groups select _side_id select _faction_id) == 0) then
			{
				(_group_factions select _side_id) deleteAt _faction_id;
				(_groups select _side_id) deleteAt _faction_id;
			};
		};
	};
	uiNamespace setVariable ["Achilles_var_nestedList_vehicleFactions", _vehicle_factions];
	uiNamespace setVariable ["Achilles_var_nestedList_vehicleCategories", _vehicle_categories];
	uiNamespace setVariable ["Achilles_var_nestedList_vehicles", _vehicles];
	uiNamespace setVariable ["Achilles_var_nestedList_groupFactions", _group_factions];
	uiNamespace setVariable ["Achilles_var_nestedList_groups", _groups];
};

comment "// get LZs";
private _allLzsUnsorted = allMissionObjects "Ares_Module_Reinforcements_Create_Lz";
if (_allLzsUnsorted isEqualTo []) exitWith {[localize "STR_AMAE_NO_LZ"] call Achilles_fnc_ShowZeusErrorMessage};
private _allLzs = [_allLzsUnsorted, [], { _x getVariable ["SortOrder", 0]; }, "ASCEND"] call BIS_fnc_sortBy;
private _lzOptions = [localize "STR_AMAE_RANDOM", localize "STR_AMAE_NEAREST", localize "STR_AMAE_FARTHEST", localize "STR_AMAE_LEAST_USED"];
_lzOptions append (_allLzs apply {name _x});

comment "// get RPs";
private _allRpsUnsorted = allMissionObjects "Ares_Module_Reinforcements_Create_Rp";
if (_allRpsUnsorted isEqualTo []) exitWith {[localize "STR_AMAE_NO_RP"] call Achilles_fnc_ShowZeusErrorMessage};
private _allRps = [_allRpsUnsorted, [], { _x getVariable ["SortOrder", 0]; }, "ASCEND"] call BIS_fnc_sortBy;
private _rpOptions = [localize "STR_AMAE_RANDOM", localize "STR_AMAE_NEAREST", localize "STR_AMAE_FARTHEST", localize "STR_AMAE_LEAST_USED"];
_rpOptions append (_allRps apply {name _x});

comment "// Show the user the dialog";
private _dialogResult =
[
	localize "STR_AMAE_SPAWN_UNITS",
	[
		["COMBOBOX", localize "STR_AMAE_SIDE", _side_names, 0, false, [["LBSelChanged","SIDE"]]],
		["COMBOBOX", [localize "STR_AMAE_VEHICLE", localize "STR_AMAE_FACTION"] joinString " ", [], 0, false, [["LBSelChanged","VEHICLE_FACTION"]]],
		["COMBOBOX", localize "STR_AMAE_VEHICLE_CATEGORY", [], 0, false, [["LBSelChanged","VEHICLE_CATEGORY"]]],
		["COMBOBOX", localize "STR_AMAE_VEHICLE", [], 0, false, [["LBSelChanged","VEHICLE"]]],
		["COMBOBOX", localize "STR_AMAE_VEHICLE_BEHAVIOUR", [localize "STR_AMAE_RTB_DESPAWN", localize "STR_AMAE_STAY_AT_LZ"]],
		["COMBOBOX", localize "STR_AMAE_LZ_DZ", _lzOptions],
		["COMBOBOX", localize "STR_AMAE_TYPE",[localize "STR_A3_CfgWaypoints_Land",localize "STR_AMAE_FASTROPING",localize "STR_AMAE_PARADROP"]],
		["COMBOBOX", [localize "STR_AMAE_GROUP", localize "STR_AMAE_FACTION"] joinString " ", [], 0, false, [["LBSelChanged","GROUP_FACTION"]]],
		["COMBOBOX", localize "STR_AMAE_INFANTRY_GROUP", [], 0, false, [["LBSelChanged","GROUP"]]],
		["COMBOBOX", localize "STR_AMAE_UNIT_RP", _rpOptions],
		["COMBOBOX", localize "STR_AMAE_UNIT_BEHAVIOUR", [localize "STR_AMAE_DEFAULT", localize "STR_AMAE_RELAXED", localize "STR_AMAE_CAUTIOUS", localize "STR_AMAE_COMBAT"]]
	],
	"Achilles_fnc_RscDisplayAttributes_Create_Reinforcement"
] call Achilles_fnc_ShowChooseDialog;

if (_dialogResult isEqualTo []) exitWith {};

_dialogResult params ["_side_id","_veh_fac_id","_veh_cat_id","_veh_id","_veh_beh","_lzdz_loc","_lzdz_type","_grp_fac_id","_grp_id","_rp_loc","_grp_beh"];
private _vehicle = configName ((uiNamespace getVariable "Achilles_var_nestedList_vehicles") select _side_id select _veh_fac_id select _veh_cat_id select _veh_id);
private _grp_cfg = (uiNamespace getVariable "Achilles_var_nestedList_groups") select _side_id select _grp_fac_id select _grp_id;
systemChat str _vehicle;
systemChat str _grp_cfg;

/*
comment "//Get dialog results";
private _side = _sides select (_dialogResult select 0);
private _infantryGroup = Ares_var_reinforcement_infantry_group;
private _vehicleType = Ares_var_reinforcement_vehicle_class;
private _dialogVehicleBehaviour = _dialogResult select 4;
private _dialogLzAlgorithm = _dialogResult select 5;
private _dialogRpAlgorithm = _dialogResult select 8;
private _dialogUnitBehaviour = _dialogResult select 9;
private _lzSize = 20;	comment "// TODO make this a dialog parameter?";
private _rpSize = 20;	comment "// TODO make this a dialog parameters?";

comment "// Choose the LZ based on what the user indicated";
private _lz = switch (_dialogLzAlgorithm) do
{
	case 0: comment "// Random";
	{
		_allLzs call BIS_fnc_selectRandom
	};
	case 1: comment "// Nearest";
	{
		[_spawnPosition, _allLzs] call Ares_fnc_GetNearest
	};
	case 2: comment "// Furthest";
	{
		[_spawnPosition, _allLzs] call Ares_fnc_GetFarthest
	};
	case 3: comment "// Least used";
	{
		private _temp = _allLzs call BIS_fnc_selectRandom; comment "// Choose randomly to start.";
		{
			if (_x getVariable ["Ares_Lz_Count", 0] < _temp getVariable ["Ares_Lz_Count", 0]) then
			{
				_temp = _x;
			};
		} forEach _allLzs;
        _temp
	};
	default comment "// Specific LZ.";
	{
		_allLzs select (_dialogLzAlgorithm - FIRST_SPECIFIC_LZ_OR_RP_OPTION_INDEX)
	};
};

comment "// Now that we've chosen an LZ, increment the count for it.";
_lz setVariable ["Ares_Lz_Count", (_lz getVariable ["Ares_Lz_Count", 0]) + 1];


comment "// create the transport vehicle";
private _vehicleInfo = [_spawnPosition, 0, _vehicleType, _side] call BIS_fnc_spawnVehicle;
private _vehicle = _vehicleInfo select 0;
private _vehicleGroup = _vehicleInfo select 2;
comment "//_vehicleDummyWp = _vehicleGroup addWaypoint [position _vehicle, 0];";
private _vehicleUnloadWp = _vehicleGroup addWaypoint [position _lz, _lzSize];
if (_vehicle isKindOf "Air" and (_dialogResult select 6 > 0)) then
{
	_vehicleUnloadWp setWaypointType "SCRIPTED";
	private _script = ["\achilles\functions_f_achilles\scripts\fn_wpParadrop.sqf", "\achilles\functions_f_achilles\scripts\fn_wpFastrope.sqf"] select (_dialogResult select 6 == 1);
	_vehicleUnloadWp setWaypointScript _script;
} else
{
	_vehicleUnloadWp setWaypointType "TR UNLOAD";
};

// Make the driver full skill. This makes him less likely to do dumb things
// when they take contact.
(driver (vehicle (leader _vehicleGroup))) setSkill 1;

if (_vehicleType isKindOf "Air") then
{
	// Special settings for helicopters. Otherwise they tend to run away instead of land
	// if the LZ is hot.
	{
		_x allowFleeing 0; // Especially for helos... They're very cowardly.
	} forEach (crew (vehicle (leader _vehicleGroup)));
	_vehicleUnloadWp setWaypointTimeout [0,0,0];
}
else
{
	_vehicleUnloadWp setWaypointTimeout [5,10,20]; // Give the units some time to get away from truck
};

// Generate the waypoints for after the transport drops off the troops.
if (_dialogVehicleBehaviour == 0) then
{
	// RTB and despawn.
	private _vehicleReturnWp = _vehicleGroup addWaypoint [_spawnPosition, 0];
	_vehicleReturnWp setWaypointTimeout [2,2,2]; // Let the unit stop before being despawned.
	_vehicleReturnWp setWaypointStatements ["true", "deleteVehicle (vehicle this); {deleteVehicle _x} foreach thisList;"];
};

// Add vehicle to curator
[(units _vehicleGroup) + [(vehicle (leader _vehicleGroup))]] call Ares_fnc_AddUnitsToCurator;

private _CrewTara = [_vehicleType,false] call BIS_fnc_crewCount;
private _CrewBrutto =  [_vehicleType,true] call BIS_fnc_crewCount;
private _CrewNetto = _CrewBrutto - _CrewTara;

// create infantry group and resize it to the given cargo space if needed
_infantryGroup = [_spawnPosition, _side, _infantryGroup] call BIS_fnc_spawnGroup;
// delete remaining units if vehicle is overcrouded
private _infantry_list = units _infantryGroup;
if (count _infantry_list > _CrewNetto) then
{
	_infantry_list resize _CrewNetto;
	private _infantry_to_delete = (units _infantryGroup) - _infantry_list;
	{deleteVehicle _x} forEach _infantry_to_delete;
};

switch (_dialogUnitBehaviour) do
{
	case 1: // Relaxed
	{
		_infantryGroup setBehaviour "SAFE";
		_infantryGroup setSpeedMode "LIMITED";
	};
	case 2: // Cautious
	{
		_infantryGroup setBehaviour "AWARE";
		_infantryGroup setSpeedMode "LIMITED";
	};
	case 3: // Combat
	{
		_infantryGroup setBehaviour "COMBAT";
		_infantryGroup setSpeedMode "NORMAL";
	};
};

// Choose a RP for the squad to head to once unloaded and set their waypoint.
if (count _allRps > 0) then
{
	// Choose the RP based on the algorithm the user selected
	private _rp = switch (_dialogRpAlgorithm) do
	{
		case 0: // Random
		{
    		_allRps call BIS_fnc_selectRandom;
		};
		case 1: // Nearest
		{
			[position _lz, _allRps] call Ares_fnc_GetNearest;
		};
		case 2: // Furthest
		{
			[position _lz, _allRps] call Ares_fnc_GetFarthest;
		};
		case 3: // Least Used
		{
			private _temp = _allRps call BIS_fnc_selectRandom; // Choose randomly to begin with.
			{
				if (_x getVariable ["Ares_Rp_Count", 0] < _temp getVariable ["Ares_Rp_Count", 0]) then
				{
					_temp = _x;
				}
			} forEach _allRps;
            _temp
		};
		default
		{
			_allRps select (_dialogRpAlgorithm - FIRST_SPECIFIC_LZ_OR_RP_OPTION_INDEX);
		};
	};

	// Now that we've chosen an RP, increment the count for it.
	_rp setVariable ["Ares_Rp_Count", (_rp getVariable ["Ares_Rp_Count", 0]) + 1];

	private _infantryRpWp = _infantryGroup addWaypoint [position _rp, _rpSize];
}
else
{
	private _infantryMoveOnWp = _infantryGroup addWaypoint [position _lz, _rpSize];
};

// Load the units into the vehicle.
{
	_x moveInCargo (vehicle (leader _vehicleGroup));
} foreach _infantry_list;

// Add infantry to curator
[(units _infantryGroup)] call Ares_fnc_AddUnitsToCurator;

if (_vehicle getVariable ["Achilles_var_noFastrope", false]) exitWith
{
	["ACE3 or AR is not loaded!"] call Achilles_fnc_showZeusErrorMessage;
	{deleteVehicle _x} forEach _infantry_list;
};

if (count _allRps > 0) then
{
	[objNull, "Transport dispatched to LZ. Squad will head to RP."] call bis_fnc_showCuratorFeedbackMessage;
}
else
{
	[objNull, "Transport dispatched to LZ. Squad will stay at LZ."] call bis_fnc_showCuratorFeedbackMessage;
};
*/

#include "\achilles\modules_f_ares\module_footer.hpp"
