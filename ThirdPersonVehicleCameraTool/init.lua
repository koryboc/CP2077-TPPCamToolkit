--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: init.lua
Version: 2026-07-29, 21:31 UTC+01:00 (MEZ)

Copyright (c) 2026, Roy Bock aka koryboc
All rights reserved.
______________________________________________

Naming Conventions in this codebase:
 - SCREAMINGCASE:        Constant single-word variables
 - SCREAMING_SNAKE_CASE: Constant multi-word variables
 - PascalCase:           Constant arrays or interface variables
 - camelCase:            Local multi-word variables and functions (non-constants)
 - flatcase:             Local single-word variables, functions, or single-letter interface variables (non-constants)
 - Exceptions:           Game- or Lua-defined names and terms

Examples:
 - presets                   (single-word variable)
 - presets.loadTask          (plus multi-word variable)
 - presets.loadTask.IsActive (plus interface variable)
 - DevLevels                 (constant array)
 - DevLevels.DISABLED        (plus constant variable)
 - vehicleName               (local multi-word variable)
 - i, x, v                   (local single-character variables)

Development Environment:
 - Editor:    Visual Studio Code
 - Extension: sumneko.lua
   - Set `"Lua.runtime.version": "LuaJIT"` in `User Settings (JSON)`
   - Set `"Lua.codeLens.enable" = true`    in `User Settings (JSON)`
   - Make sure to open the entire project folder in VS Code
--]]


--#region 🚧 Core Definitions

---Represents available developer debug modes used to control logging and feedback behavior.
---@alias DevLevelType 0|1|2|3|4|5

---Represents available logging levels for categorizing message severity.
---@alias LogLevelType 0|1|2

---Represents metadata associated with a specific log level.
---@class ILogMeta
---@field TAG string # Text tag prefix shown in console or log output (e.g. "[Error]").
---@field ICON string # Unicode icon code representing the log level visually.
---@field TOAST integer # Toast notification type constant from `ImGui.ToastType`.

---Represents a parsed version number in structured format.
---@class IVersion
---@field Major number # Major version number (required).
---@field Minor number # Minor version number (optional, defaults to 0 if missing).
---@field Build number # Build number (optional, defaults to 0 if missing).
---@field Revision number # Revision number (optional, defaults to 0 if missing).

---Represents a recurring asynchronous timer.
---@class IAsyncTimer
---@field Interval number # The time interval in seconds between each callback execution.
---@field Time number # The next scheduled execution time (typically os.clock() + interval).
---@field Callback fun(id: integer) # The function to be executed when the timer triggers; receives the timer's unique ID.
---@field IsActive boolean # True if the timer is currently active, false if paused or canceled.

---Represents a default parameter variable.
---@class IDefaultParam
---@field Default any # The default value for this parameter. Can be a number, boolean, or table depending on context.
---@field Min number? # The minimum allowed value (for numeric params only).
---@field Max number? # The maximum allowed value (for numeric params only).
---@field Step number? # The step size used for value adjustments (for numeric params only).
---@field Tip string # A short explanatory note or hint describing the purpose or effect of this parameter.

---Represents a global options structure.
---@class IOptionData
---@field DisplayName string # The display name.
---@field Description string? # The description.
---@field Tooltip string # The value tooltip.
---@field Default boolean|number # The default value.
---@field Value (boolean|number)? # The current value.
---@field Min number? # The minimum value.
---@field Max number? # The maximum value.
---@field Speed number? # Adjust sensitivity for ImGui controls; lower values allow finer adjustments.
---@field Values string[]? # An array of selectable options.
---@field Dependency string? # An option key to check if its value is not default to determine whether this option should be visible.
---@field GameOptionPath string? # The path used when linking this option to a game configuration entry.
---@field GameOptionKey string? # The specific key within the game configuration path.
---@field IsGameOption boolean? # Determines whether this is treated as game INI option.
---@field IsGameTweak boolean? # Determines whether this is treated as game tweak.
---@field IsUnavailable boolean? # Determines whether this option is currently not available.

---Represents a single game setting option with its associated metadata and values.
---@class IGameConfigOption
---@field Group string # The settings group path this option belongs to.
---@field Name string # The internal name of the option.
---@field Type string # The data type of the option (e.g., "Bool", "Int", "Float", etc.).
---@field Value boolean|number|string # The current value of the option.
---@field DefaultValue boolean|number|string # The game's default value for this option.
---@field MinValue number? # The minimum allowed value (for numeric options only).
---@field MaxValue number? # The maximum allowed value (for numeric options only).
---@field StepValue number? # The step size used for value adjustments in numeric options.
---@field Index integer? # The current index for list-type options.
---@field DefaultIndex integer? # The default index for list-type options.
---@field Values (number|string)[]? # The available values for list-type options.

---Represents the state of a preset loader task.
---@class IPresetLoaderTask
---@field IsActive boolean? # True if the task is currently running.
---@field StartTime number? # Timestamp when the task started.
---@field EndTime number? # Timestamp when the task finished or last finished.
---@field Duration number? # Total elapsed time of the task. The sum of all individual run durations.
---@field Finalizer function? # Function called when all tasks have finished.

---Represents a camera offset configuration with rotation and positional data.
---@class IOffsetData
---@field a number # The camera's angle in degrees.
---@field x number # The offset on the X-axis.
---@field y number # The offset on the Y-axis.
---@field z number # The offset on the Z-axis.
---@field d number # The offset of the camera distance.

---Represents a vehicle camera preset.
---@class ICameraPreset
---@field ID string? # The camera ID used for the vehicle.
---@field Close IOffsetData? # The offset data for close camera view.
---@field Medium IOffsetData? # The offset data for medium camera view.
---@field Far IOffsetData? # The offset data for far camera view.
---@field IsDefault boolean? # Determines whether this camera preset is a default one.
---@field IsJoined boolean? # Determines whether this camera preset was newly generated as a default.
---@field IsVanilla boolean? # Determines whether this camera preset comes from a vanilla vehicle.
---@field IsLegacy boolean? # Determines whether this camera preset is a legacy preset.

---Represents usage statistics for a camera preset.
---@class IPresetUsage
---@field First number # Timestamp of the first time this preset was applied.
---@field Last number # Timestamp of the most recent time this preset was applied.
---@field Total number # Total number of times this preset has been applied.

---Represents a single camera preset entry used in the editor, including its metadata and file state.
---@class IEditorPreset
---@field Preset ICameraPreset # The actual preset data (angles and offsets).
---@field Key string # Internal identifier for lookups and invalid name detection.
---@field Name string # User-modifiable display name of the preset.
---@field Token integer # Adler-53 checksum of `Preset`, used to detect changes.
---@field IsPresent boolean # True if a corresponding preset file exists on disk.

---Represents pending actions for a modified camera preset within the editor workflow.
---@class IEditorTasks
---@field Rename boolean # True if the preset has been renamed but the file itself still needs to be renamed.
---@field Validate boolean # True if angles or offsets have changed, used to highlight buttons.
---@field Apply boolean # True if there are unapplied changes ready to be applied in-game.
---@field Save boolean # True if there are unsaved modifications that need to be written to disk.
---@field Restore boolean # True if saving will revert the preset back to its default configuration.

---Holds multiple versions of a vehicle camera preset within the editor.
---Each version represents a different state in the edit/apply/save workflow.
---@class IEditorBundle
---@field Nexus IEditorPreset # Immutable default preset for the mounted vehicle.
---@field Flux IEditorPreset # Live preset reflecting current UI edits.
---@field Pivot IEditorPreset # Snapshot of Flux at the last apply action.
---@field Finale IEditorPreset # Snapshot of Flux at the last save action.
---@field Tasks IEditorTasks # Flags for pending rename, validate, apply, save, or restore actions.

---Aliases for commonly used standard library functions to simplify code.
---@diagnostic disable-next-line: lowercase-global
format, rep, concat, insert, remove, sort, unpack, abs, ceil, floor, band, bor, lshift, rshift =
	string.format,
	string.rep,
	table.concat,
	table.insert,
	table.remove,
	table.sort,
	table.unpack,
	math.abs,
	math.ceil,
	math.floor,
	bit32.band,
	bit32.bor,
	bit32.lshift,
	bit32.rshift

---Loads all static UI and log string constants from `text.lua` into the global `Text` table.
---This is the most efficient way to manage display strings separately from logic and code.
---@type table<string, string>
local Text = (function()
	local base = dofile("text.lua")
	local ok, addon = pcall(dofile, "addons/lang_text.lua")
	if ok and type(addon) == "table" then
		for k in pairs(base) do
			if k ~= "GUI_TITLE" and k ~= "GUI_NAME" then
				local v = addon[k]
				if type(v) == "string" then
					base[k] = v
				end
			end
		end
	end
	return base
end)()

---Developer mode levels used to control the verbosity and behavior of debug output.
---@type table<string, DevLevelType>
local DevLevels = {
	---No debug output (default).
	DISABLED = 0,

	---Logs output to the CET console only.
	BASIC = 1,

	---Same as BASIC, but keeps the overlay visible even when CET is hidden.
	OVERLAY = 2,

	---Same as OVERLAY, but adds a ruler at the bottom of the screen.
	RULER = 3,

	---Same as RULER, but also shows pop-up alerts on screen.
	ALERT = 4,

	---Same as ALERT, but with extended technical output and additional logging to file.
	FULL = 5
}

---Log levels used to classify the severity of log messages.
---@type table<string, LogLevelType>
local LogLevels = {
	---General informational output.
	INFO = 0,

	---Non-critical issues or unexpected behavior.
	WARN = 1,

	---Critical failures or important errors that need attention.
	ERROR = 2
}

---Contains textual tags, toast icons, and toast types for each log level.
---@type table<LogLevelType, ILogMeta>
local LogMeta = {
	[LogLevels.INFO] = {
		TAG = "[Info]",
		ICON = "\u{f11be}",
		TOAST = ImGui.ToastType and ImGui.ToastType.Info or 0
	},
	[LogLevels.WARN] = {
		TAG = "[Warn]",
		ICON = "\u{f0d64}",
		TOAST = ImGui.ToastType and ImGui.ToastType.Warning or 0
	},
	[LogLevels.ERROR] = {
		TAG = "[Error]",
		ICON = "\u{f0e1c}",
		TOAST = ImGui.ToastType and ImGui.ToastType.Error or 0
	}
}

---Provides predefined integer ABGR color constants used for UI theming and styling.
local Colors = {
	---Deep black.
	BLACK = 0xab000000,

	---Pure white.
	WHITE = 0xabffffff,

	---Pure Cyan.
	CYAN = 0xffffff00,

	---Pure green.
	GREEN = 0xff00ff00,

	---Pure orange.
	ORANGE = 0xff0080ff,

	---Pure red.
	RED = 0xff0000ff,

	---Pure yellow.
	YELLOW = 0xff00ffff,

	---Medium gray.
	DARKGRAY = 0xab404040,

	---A warm, golden brown with rich amber tones.
	CARAMEL = 0xab295c7a,

	---A dark, cool green with subtle blue undertones.
	FIR = 0xab849833,

	---A deep, muted red with a subtle brown undertone.
	GARNET = 0xab3d297a,

	---A deep, muted purple with rich red undertones and a cool, berry-like hue.
	MULBERRY = 0xab68297a,

	---A muted yellow-green with an earthy, natural tone.
	OLIVE = 0xab297a68
}

---Predefined folder paths for storing camera presets.
local PresetFolders = {
	---Folder containing base presets representing the standard/default settings.
	DEFAULTS = "defaults",

	---Folder containing presets for modded/custom vehicles.
	CUSTOM = "presets",

	---Folder containing presets for legacy modded/custom vehicles.
	CUSTOM_LEGACY = "presets/legacy",

	---Folder containing presets for vanilla vehicles.
	VANILLA = "presets-vanilla"
}

---Provides a table of Preset Explorer search filter commands.
local ExplorerCommands = {
	---Presets of vehicles that are available in the game.
	INSTALLED = ":installed",

	---Presets of custom vehicles that are available in the game.
	MODDED = ":installed_mods",

	---Presets of vehicles not available in the game.
	UNAVAILABLE = ":not_installed",

	---Presets of vehicles that were actively used.
	ACTIVE = ":active",

	---Presets of vehicles that exist but have never been used.
	INACTIVE = ":unused",

	---Presets of standard vehicles that come with the base game.
	VANILLA = ":vanilla"
}

---Default parameter constants, including TweakDB keys, variables, and their values.
local DefaultParams = {
	---Indexed TweakDB keys where the first entry applies to four-wheeled vehicles and the second to two-wheeled vehicles.
	---@type table<integer, string>
	Keys = {
		"Camera.VehicleTPP_DefaultParams",
		"Camera.VehicleTPP_2w_DefaultParams"
	},

	---Defines all constant default parameters for vehicle camera configuration.
	---Each key represents the internal name of a parameter, mapped to a structured definition table.
	---These values are static and never modified at runtime.
	---`Default` may be a single value or a two-element table specifying separate defaults
	---for four-wheeled and two-wheeled vehicles.
	---@type table<string, IDefaultParam>
	Vars = {
		airFlowDistortion = {
			Default = true,
			Tip = Text.GUI_ASET_AFD_TIP
		},
		autoCenterMaxSpeedThreshold = {
			Default = 20,
			Min = 0,
			Max = 300,
			Tip = Text.GUI_ASET_ACMST_TIP
		},
		autoCenterSpeed = {
			Default = 5,
			Min = 0,
			Max = 10,
			Tip = Text.GUI_ASET_ACS_TIP
		},
		cameraBoomExtensionSpeed = {
			Default = 3,
			Min = 0,
			Max = 10,
			Tip = Text.GUI_ASET_CBES_TIP
		},
		cameraMaxPitch = {
			Default = 80,
			Min = 0,
			Max = 90,
			Tip = Text.GUI_ASET_CMAXP_TIP
		},
		cameraMinPitch = {
			Default = -28,
			Min = -90,
			Max = 0,
			Tip = Text.GUI_ASET_CMINP_TIP
		},
		cameraSphereRadius = {
			Default = 1,
			Min = 0.2,
			Max = 5,
			Step = 0.01,
			Tip = Text.GUI_ASET_CSR_TIP
		},
		collisionDetection = {
			Default = true,
			Tip = Text.GUI_ASET_CD_TIP
		},
		drivingDirectionCompensation = {
			Default = true,
			Tip = Text.GUI_ASET_DDC_TIP
		},
		drivingDirectionCompensationAngle = {
			Default = 100,
			Min = -180,
			Max = 180,
			Tip = Text.GUI_ASET_DDCA_TIP
		},
		drivingDirectionCompensationAngleSmooth = {
			Default = 70,
			Min = -180,
			Max = 180,
			Tip = Text.GUI_ASET_DDCAS_TIP
		},
		drivingDirectionCompensationAngularVelocityMin = {
			Default = 150,
			Min = 0,
			Max = 500,
			Tip = Text.GUI_ASET_DDCAVM_TIP
		},
		drivingDirectionCompensationSpeedCoef = {
			Default = 1,
			Min = 0,
			Max = 5,
			Tip = Text.GUI_ASET_DDCSC_TIP
		},
		drivingDirectionCompensationSpeedMax = {
			Default = 120,
			Min = 0,
			Max = 300,
			Tip = Text.GUI_ASET_DDCSX_TIP
		},
		drivingDirectionCompensationSpeedMin = {
			Default = 4,
			Min = 0,
			Max = 100,
			Tip = Text.GUI_ASET_DDCSN_TIP
		},
		elasticBoomAcceleration = {
			Default = true,
			Tip = Text.GUI_ASET_EBA_TIP
		},
		elasticBoomAccelerationExpansionLength = {
			Default = 0.5,
			Min = 0,
			Max = 5,
			Step = 0.01,
			Tip = Text.GUI_ASET_EBAEL_TIP
		},
		elasticBoomForwardAccelerationCoef = {
			Default = 10,
			Min = 0,
			Max = 20,
			Tip = Text.GUI_ASET_EBAFAC_TIP
		},
		elasticBoomSpeedExpansionLength = {
			Default = 0.5,
			Min = 0,
			Max = 5,
			Step = 0.01,
			Tip = Text.GUI_ASET_EBSEL_TIP
		},
		elasticBoomSpeedExpansionSpeedMax = {
			Default = 20,
			Min = 0,
			Max = 300,
			Tip = Text.GUI_ASET_EBSESX_TIP
		},
		elasticBoomSpeedExpansionSpeedMin = {
			Default = 10,
			Min = 0,
			Max = 100,
			Tip = Text.GUI_ASET_EBSESN_TIP
		},
		elasticBoomVelocity = {
			Default = true,
			Tip = Text.GUI_ASET_EBV_TIP
		},
		fov = {
			Default = 69,
			Min = 40,
			Max = 120,
			Tip = Text.GUI_ASET_FOV_TIP
		},
		headLookAtCenterYawThreshold = {
			Default = { 100, 140 },
			Min = 0,
			Max = 180,
			Tip = Text.GUI_ASET_HLACYT_TIP
		},
		headLookAtMaxPitchDown = {
			Default = { 40, 10 },
			Min = 0,
			Max = 90,
			Tip = Text.GUI_ASET_HLAMPD_TIP
		},
		headLookAtMaxPitchUp = {
			Default = { 0, 30 },
			Min = 0,
			Max = 90,
			Tip = Text.GUI_ASET_HLAMPU_TIP
		},
		headLookAtMaxYaw = {
			Default = { 70, 100 },
			Min = 0,
			Max = 180,
			Tip = Text.GUI_ASET_HLAMY_TIP
		},
		headLookAtRotationSpeed = {
			Default = { 0.8, 2 },
			Min = 0.1,
			Max = 5,
			Step = 0.01,
			Tip = Text.GUI_ASET_HLARS_TIP
		},
		inverseCameraInputBreakThreshold = {
			Default = 30,
			Min = 0,
			Max = 180,
			Tip = Text.GUI_ASET_ICIBT_TIP
		},
		lockedCamera = {
			Default = false,
			Tip = Text.GUI_ASET_LC_TIP
		},
		slopeAdjustement = {
			Default = true,
			Tip = Text.GUI_ASET_SA_TIP
		},
		slopeCorrectionInAirDampFactor = {
			Default = 0.1,
			Min = 0,
			Max = 1,
			Step = 0.01,
			Tip = Text.GUI_ASET_SCIADF_TIP
		},
		slopeCorrectionInAirFallCoef = {
			Default = 2,
			Min = 0,
			Max = 5,
			Tip = Text.GUI_ASET_SCIAFC_TIP
		},
		slopeCorrectionInAirPitchMax = {
			Default = 30,
			Min = 0,
			Max = 90,
			Tip = Text.GUI_ASET_SCIAPX_TIP
		},
		slopeCorrectionInAirPitchMin = {
			Default = -30,
			Min = -90,
			Max = 0,
			Tip = Text.GUI_ASET_SCIAPN_TIP
		},
		slopeCorrectionInAirRaiseCoef = {
			Default = 0.5,
			Min = 0,
			Max = 2,
			Step = 0.01,
			Tip = Text.GUI_ASET_SCIARC_TIP
		},
		slopeCorrectionInAirSpeedMax = {
			Default = 10,
			Min = 0,
			Max = 100,
			Tip = Text.GUI_ASET_SCIASX_TIP
		},
		slopeCorrectionInAirStrength = {
			Default = 20,
			Min = 0,
			Max = 50,
			Tip = Text.GUI_ASET_SCIAS_TIP
		},
		slopeCorrectionOnGroundPitchMax = {
			Default = 30,
			Min = 0,
			Max = 90,
			Tip = Text.GUI_ASET_SCOGPX_TIP
		},
		slopeCorrectionOnGroundPitchMin = {
			Default = -30,
			Min = -90,
			Max = 0,
			Tip = Text.GUI_ASET_SCOGPN_TIP
		},
		slopeCorrectionOnGroundStrength = {
			Default = 4,
			Min = 0,
			Max = 10,
			Tip = Text.GUI_ASET_SCOGS_TIP
		}
	}
}

---Camera-related metadata including levels and variable names.
local CameraData = {
	---All camera levels, e.g. `High_Close`, `High_DriverCombatMedium`, `Low_Far`, and so on.
	Levels = {
		"High_Close",
		"High_Medium",
		"High_Far",
		"High_DriverCombatClose",
		"High_DriverCombatMedium",
		"High_DriverCombatFar",
		"Low_Close",
		"Low_Medium",
		"Low_Far",
		"Low_DriverCombatClose",
		"Low_DriverCombatMedium",
		"Low_DriverCombatFar"
	},

	---All camera variable names, e.g. `boomLengthOffset`, `height`, `lookAtOffset`, and so on.
	Vars = {
		"airFlowDistortionSizeHorizontal",
		"airFlowDistortionSizeVertical",
		"airFlowDistortionSpeedMax",
		"airFlowDistortionSpeedMin",
		"baseBoomLength",
		"boomLengthOffset",
		"defaultRotationPitch",
		"distance",
		"height",
		"lookAtOffset"
	}
}

---Maps vehicle preset IDs to camera paths that are considered invalid.
---If a camera ID exists in the map and a corresponding camera level is
---found, the next operation should be aborted.
---@type table<string, table<string, boolean>>
local CameraDataInvalidLevelMap = {
	["4w_Medium_Preset"] = {
		High_DriverCombatClose = true,
		High_DriverCombatMedium = true,
		High_DriverCombatFar = true,
		Low_Close = true,
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["4w_SubCompact_Preset"] = {
		High_DriverCombatClose = true,
		High_DriverCombatMedium = true,
		High_DriverCombatFar = true,
		Low_Close = true,
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["Default_Preset"] = {
		High_DriverCombatClose = true,
		High_DriverCombatMedium = true,
		High_DriverCombatFar = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["v_utility4_kaukaz_bratsk_Preset"] = {
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["v_utility4_militech_behemoth_Preset"] = {
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	}
}

---Contains base camera levels and corresponding offset keys for presets.
local PresetInfo = {
	---Constant array of base camera levels (`Close`, `Medium`, and `Far`).
	Levels = { "Close", "Medium", "Far" },

	---Constant array of `IOffsetData` keys (`a`, `x`, `y`, `z`, and `d`).
	Offsets = { "a", "x", "y", "z", "d" }
}

---Holds global mod state and runtime flags.
local state = {
	---Current developer mode level controlling debug output and behavior.
	devMode = DevLevels.DISABLED,

	---Determines whether the mod is enabled.
	isModEnabled = true,

	---The current game version.
	gameVersion = nil,

	---Indicates whether the running game version meets the minimum required version.
	isGameCompatible = false,

	---The current game version.
	cetVersion = nil,

	---Indicates whether the running CET version meets the minimum required version.
	isCetCompatible = false,

	---Indicates whether the running CET version supports all required features.
	isCetTopical = false,

	---Determines whether `Codeware` is installed.
	isCodewareAvailable = false,

	---Determines whether `FovControl` is installed.
	isFovControlAvailable = false
}

---Manages recurring asynchronous timers and their status.
local async = {
	---Stores all active recurring async timers, indexed by their unique ID.
	---@type table<integer, IAsyncTimer>
	timers = {},

	---Auto-incrementing ID used to assign unique keys to each timer.
	idCounter = 0,

	---Indicates whether at least one recurring timer is active.
	---Used to skip unnecessary processing in `onUpdate` event when no timers exist.
	isActive = false
}

---Stores persistent and transient caches for various data.
---@type table<string, table<number, any>>
local caches = {
	---Persistent cache for storing reusable or computed values across sessions.
	---Unlike `transient`, it retains data throughout the CET runtime.
	persistent = {},

	---Temporary cache mostly used to store vehicle-related data during an active session.
	---This cache is cleared or rebuilt when the vehicle context changes.
	transient = {}
}

---Holds user options and some default parameters.
local config = {
	---Global option data.
	---@type table<string, IOptionData>
	options = {
		---Mod-only option: moves the camera closer to motorcycles; prevents editing motorcycle presets while enabled.
		closerBikes = {
			DisplayName = Text.GUI_GSET_CLOSER_BIKES,
			Tooltip = Text.GUI_GSET_CLOSER_BIKES_TIP,
			Default = 1,
			Min = 1,
			Max = 4,
			Values = {
				Text.GUI_OFF,
				Text.GUI_ON,
				Text.GUI_LEFT,
				Text.GUI_RIGHT
			}
		},

		---Mod-only options: fine-tunes the close bike camera presets.
		closerBikesA = {
			DisplayName = Text.GUI_GSET_CLO_BIKES_OSET_A,
			Tooltip = Text.GUI_GSET_CLO_BIKES_OSET_TIP,
			Default = 0,
			Min = -30,
			Max = 70,
			Speed = 1,
			Dependency = "closerBikes"
		},

		closerBikesX = {
			DisplayName = Text.GUI_GSET_CLO_BIKES_OSET_X,
			Tooltip = Text.GUI_GSET_CLO_BIKES_OSET_TIP,
			Default = 0,
			Min = -1,
			Max = 1,
			Speed = 0.01,
			Dependency = "closerBikes"
		},

		closerBikesZ = {
			DisplayName = Text.GUI_GSET_CLO_BIKES_OSET_Z,
			Tooltip = Text.GUI_GSET_CLO_BIKES_OSET_TIP,
			Default = 0,
			Min = -1,
			Max = 1,
			Speed = 0.01,
			Dependency = "closerBikes"
		},

		closerBikesD = {
			DisplayName = Text.GUI_GSET_CLO_BIKES_OSET_D,
			Tooltip = Text.GUI_GSET_CLO_BIKES_OSET_TIP,
			Default = 0,
			Min = -1,
			Max = 2,
			Speed = 0.01,
			Dependency = "closerBikes"
		},

		---Mod-only option: enables or disables all vanilla presets.
		noVanilla = {
			DisplayName = Text.GUI_GSET_VAN_PSETS,
			Tooltip = Text.GUI_GSET_VAN_PSETS_TIP,
			Default = false
		},

		---Game option: enables or disables auto-hiding of nearby objects.
		autoHideDistanceNear = {
			DisplayName = Text.GUI_GSET_OHIDE_NEAR,
			Tooltip = Text.GUI_GSET_OHIDE_NEAR_TIP,
			Default = true,
			GameOptionPath = "Streaming/Culling/AutoHideDistanceNear",
			GameOptionKey = "Enabled",
			IsGameOption = true
		},

		---Game tweak: adjusts the field of view.
		fov = {
			DisplayName = Text.GUI_GSET_FOV,
			Description = Text.GUI_GSET_FOV_DESC,
			Tooltip = Text.GUI_GSET_FOV_TIP,
			Default = DefaultParams.Vars.fov.Default,
			Min = 1, --Real minimum: 0.338
			Max = 172, --Real maximum: 172.186
			Speed = 1,
			IsGameTweak = true
		},

		---Game tweak: toggles automatic camera reset.
		lockedCamera = {
			DisplayName = Text.GUI_GSET_AUTO_CENTER,
			Tooltip = Text.GUI_GSET_AUTO_CENTER_TIP,
			Default = DefaultParams.Vars.lockedCamera.Default,
			IsGameTweak = true
		},

		---Game tweak: adjusts the zoom.
		zoom = {
			DisplayName = Text.GUI_GSET_ZOOM,
			Description = Text.GUI_GSET_ZOOM_DESC,
			Tooltip = Text.GUI_GSET_ZOOM_TIP,
			Default = 1.0,
			Min = 1.0,
			Max = 30.0,
			Speed = 0.05,
			IsGameTweak = true
		}
	},

	---Advanced option data.
	advancedOptions = {},

	---Determines whether the Global Settings window is open.
	isOpen = false,

	---Determines whether the Advanced Settings window is open.
	isAdvancedOpen = false,

	---Determines whether Global Settings have been modified.
	isUnsaved = false,

	---Determines whether Advanced Settings have been modified.
	isAdvancedUnsaved = false,

	---Active instance of the Native Settings UI mod, if present.
	nativeInstance = nil,

	---Options from this mod registered in Native Settings UI.
	nativeOptions = {}
}

---Manages camera presets including loading, active state, and usage statistics.
local presets = {
	---Holds the state of the asynchronous preset loading task.
	---@type IPresetLoaderTask
	loaderTask = {},

	---Container for all camera presets.
	---@type table<string, ICameraPreset>
	collection = {},

	---Container for original camera presets.
	---@type table<string, ICameraPreset>
	restoreCollection = nil,

	---Determines whether a preset is currently loaded and active.
	isAnyActive = false,

	---List of camera preset IDs that were modified at runtime to enable selective restoration.
	---@type string[]
	restoreStack = {},

	---Stores original custom parameter values before resetting them to global defaults.
	---Keys are TweakDB paths (string), and values are the original values.
	---Allows potential restoration of vehicle-specific parameters on shutdown.
	---@type table<string, any>
	restoreParams = {},

	---A mapping of preset names to their usage statistics.
	---@type table<string, IPresetUsage>
	usage = {},

	---Determines whether preset usage state has been modified.
	isUsageUnsaved = false
}

---Holds GUI-related flags and temporary UI states.
local gui = {
	---Indicates whether the CET overlay UI should be temporarily disabled.
	---Used to trigger `ImGui.BeginDisabled(true)` in frames where no user interaction
	---is allowed, e.g., during loading sequences or pending asynchronous operations.
	isOverlayLocked = false,

	---Indicates whether the overlay is currently suppressed by an
	---in-game menu, so it can't be visible if CET isn't open either.
	isOverlaySuppressed = false,

	---Determines whether the CET overlay is open.
	isOverlayOpen = false,

	---Tracks whether each registered window is being rendered for the first frame.
	---Used to perform one-time setup operations per window, such as preventing automatic item selection or setting initial focus.
	hasInitialized = {},

	---Forces a one-frame skip in `onDraw` so a window using `ImGuiWindowFlags.AlwaysAutoResize` can shrink again.
	forceMetricsReset = true,

	---Indicates whether window bounds validation is currently active.
	isValidating = false,

	---When set to true, disables dynamic window padding
	---adjustments and uses the fixed `gui.paddingWidth` value.
	isPaddingLocked = false,

	---Current horizontal padding value used for centering UI elements.
	---Dynamically adjusted based on available window width.
	paddingWidth = 0,

	---Indicates whether there are active toast notifications pending.
	areToastsPending = false,

	---Maps `ImGui.ToastType` to their combined message strings.
	---@type table<ImGui.ToastType, string>
	toasterBumps = {},

	---Horizontal offset for the on-screen ruler position.
	rulerOffset = 0
}

---Stores per-vehicle editor state and recently used bundles.
local editor = {
	---Holds per-vehicle editor state for all mounted and recently edited vehicles.
	---The key is always the vehicle name and appearance name, separated by an asterisk (*).
	---Each entry tracks editor data and preset version states for the given vehicle.
	---@type table<string, IEditorBundle>
	bundles = {},

	---Stores the most recently accessed editor bundle.
	---@type IEditorBundle
	lastBundle = nil,

	---Determines whether overwriting the preset file is allowed.
	isOverwriteConfirmed = false,
}

---Container for optional addon data.
---@type table<string, any>
local addons = {
	---Holds a lookup table of crowd vehicles if the addon is available.
	---Each key is the vehicle name and the value is always `true`.
	---Set to `false` if the addon is not installed.
	---@type table<string, boolean>|boolean
	crowdLookup = nil
}

---Tracks state of the Preset Explorer UI.
local explorer = {
	---Determines whether the Preset Explorer is open.
	isOpen = false,

	---Search query entered in the Preset Explorer.
	searchText = ExplorerCommands.INSTALLED,

	---Number of files currently displayed in the file browser.
	totalVisible = 0
}

--#endregion

--#region 🔧 Utility Functions

---Checks whether the provided argument is of the specified type.
---@param t string # The expected type name.
---@param v any # The value to check against the specified type.
---@return boolean # True if the argument match the specified type, false otherwise.
local function isType(t, v)
	return type(v) == t
end

---Checks whether all provided arguments is of type `function`.
---@param n any # Value to check.
---@return boolean # True if the argument is a function, false otherwise.
local function isFunction(n)
	return isType("function", n)
end

---Checks whether the provided argument is of type `boolean`.
---@param b any # Value to check.
---@return boolean # True if the argument is a voolean, false otherwise.
local function isBoolean(b)
	return isType("boolean", b)
end

---Checks whether all provided arguments is of type `number`.
---@param n any # Value to check.
---@return boolean # True if the argument is a number, false otherwise.
local function isNumber(n)
	return isType("number", n)
end

---Checks whether the provided argument is of type `string`.
---@param s any # Value to check.
---@return boolean # True if the argument is a string, false otherwise.
local function isString(s)
	return isType("string", s)
end

---Checks whether the provided argument is a non-empty string.
---Returns false if the argument is not a string or is an empty string.
---@param s any # Value to check.
---@return boolean # True if the argument is a non-empty string, false otherwise.
local function isStringValid(s)
	return isString(s) and #s > 0
end

---Checks whether the provided argument is of type `table`.
---@param t any # Value to check.
---@return boolean # True if the argument is a table, false otherwise.
local function isTable(t)
	return isType("table", t)
end

---Checks whether the provided argument is a non-empty table.
---Returns false if the argument is not a table or is an empty table.
---@param t any # Value to check.
---@return boolean # True if the argument is a non-empty table, false otherwise.
local function isTableValid(t)
	return isTable(t) and next(t) ~= nil
end

---Checks whether the provided argument is of type 'userdata'.
---@param u any Value to check.
---@return boolean # True if the argument is an userdata, false otherwise.
local function isUserdata(u)
	return isType("userdata", u)
end

---Attempts to determine a human-readable type name of a userdata value.
---@param v any # The value to check. Must be userdata to return a result.
---@return string? # A type name string if available, otherwise nil.
local function getUserdataType(v)
	if not isUserdata(v) then return nil end
	local mt = getmetatable(v)
	if isTable(mt) then
		local x = mt.__name or mt.__type or mt.__tag
		if isStringValid(x) then
			return x
		end
	end
	local s = tostring(v)
	return s:sub(1, 3) ~= "0x" and s or nil
end

---Checks whether the provided argument is of the specified custom type.
---@param t string # The expected type name.
---@param v any # The value to check against the specified type.
---@return boolean # True if the argument match the specified type, false otherwise.
local function isUserdataType(t, v)
	if t == nil then return false end
	return t == getUserdataType(v)
end

---Checks whether the provided argument is of type `Vector3`.
---@param v any # Value to check.
---@return boolean # True only if the argument is Vector3.
local function isVector3(v)
	return isUserdataType("sol.Vector3", v)
end

---Checks whether a value is nil or considered empty (string or table).
---@param v any # The value to check.
---@return boolean # True if the value is nil, an empty string, or an empty table.
local function nilOrEmpty(v)
	if v == nil then return true end
	local t = type(v)
	if t == "string" then return #v == 0 end
	if t == "table" then return next(v) == nil end
	return false
end

---Checks whether all provided arguments are of the specified type.
---@param t string # The expected type name.
---@param ... any # A variable number of values to check against the specified type.
---@return boolean # True if all arguments match the specified type, false otherwise.
local function areType(t, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not isType(t, v) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `number`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are numbers, false otherwise.
local function areNumber(...)
	return areType("number", ...)
end

---Checks whether all provided arguments are of type `string`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are strings, false otherwise.
local function areString(...)
	return areType("string", ...)
end

---Checks whether all provided arguments are a non-empty strings.
---Returns false if any argument is not a string or is an empty string.
---@param ... any # Values to check.
---@return boolean # True if all arguments are non-empty strings, false otherwise.
local function areStringValid(...)
	for i = 1, select("#", ...) do
		local s = select(i, ...)
		if not isStringValid(s) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `table`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are tables, false otherwise.
local function areTable(...)
	return areType("table", ...)
end

---Checks whether all provided arguments are non-empty tables.
---Returns false if any argument is not a table or is an empty table.
---@param ... any # Values to check.
---@return boolean # True if all arguments are non-empty tables, false otherwise.
local function areTableValid(...)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		if not isTableValid(t) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of the specified custom type.
---@param t string # The expected type name (a custom `__name` string).
---@param ... any # A variable number of values to check against the specified type.
---@return boolean # True if all arguments match the specified type, false otherwise.
local function areUserdataType(t, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not isUserdataType(t, v) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `Vector3`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are `Vector3`, false otherwise.
local function areVector3(...)
	return areUserdataType("sol.Vector3", ...)
end

---Determines whether a table is a pure sequence (array) with contiguous integer keys 1..#t.
---Returns false if any key is non-numeric or if there are gaps in the numeric index.
---@param t table # The table to test (nil or non-table will be treated as not an array).
---@return boolean # True if `t` is an array of length `#t` with no non-numeric keys.
local function isArray(t)
	if not isTable(t) then return false end
	local n = #t
	local c = 0
	for i in pairs(t) do
		if not isNumber(i) then
			return false
		end
		c = c + 1
	end
	return c == n
end

---Checks whether the given value represents a valid number (integer or float).
---@param x number|string # The value to check.
---@return boolean # True if the value can be converted to a number, false otherwise.
local function isNumeric(x)
	return tonumber(x) ~= nil
end

---Checks whether all provided values represent valid numbers (integers or floats).
---@param ... number|string # The values to check.
---@return boolean # True if all values can be converted to numbers, false otherwise.
local function areNumeric(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not isNumeric(v) then
			return false
		end
	end
	return true
end

---Returns the first non-nil value between two arguments.
---Unlike the Lua `or` operator, this function treats `false` as a valid value
---and will only fall back when `value` is actually `nil`.
---@param value any # Primary value to check.
---@param fallback any # Fallback value to use if `value` is nil.
---@return any # Returns `value` unless it is nil, in which case `fallback` is returned.
local function coalesce(value, fallback)
	if value == nil then
		return fallback
	end
	return value
end

---Rounds a floating-point number to a specified number of decimal places.
---Includes a small epsilon correction (1e-9) to mitigate floating-point inaccuracies.
---@param value number # The numeric value to round.
---@param digits number? # Optional number of decimal digits to keep. Defaults to 0 if omitted or invalid.
---@return number # The rounded numeric value.
local function roundF(value, digits)
	if not isNumber(value) then return 0 end
	digits = isNumber(digits) and digits or 0
	local factor = 10 ^ abs(digits)
	local scaled = value * factor
	local result = (scaled >= 0) and floor(scaled + 0.5) or ceil(scaled - 0.5)
	return result / factor
end

---Returns a string format pattern for representing numeric values with adaptive precision.
---If the number is less than 1, the number of decimal places is determined dynamically
---based on the negative order of magnitude (e.g., 0.1 → "%.1f", 0.01 → "%.2f").
---For numbers greater than or equal to 1, the format "%.0f" is returned for integer rounding.
---@param value number # The numeric value for which to determine the format.
---@return string # The format pattern suitable for string.format.
local function getPrecision(value)
	if isNumber(value) and value > 0 and value < 1 then
		return "%." .. abs(floor(math.log(value, 10))) .. "f"
	end
	return "%.0f"
end

---Calculates a recommended step size for a numeric value based on its decimal precision.
---This can be used to automatically determine a suitable increment for sliders or numeric inputs.
---@param value number # The numeric value to analyze. Can be an integer or float.
---@return number # Recommended step size. For integers, returns 1. For floats, returns 10^-n where n is the number of decimal places.
local function getStep(value)
	if not isNumber(value) then return 1 end

	local str = tostring(value)
	local dec = str:match("%.(%d+)")
	if not dec then return 1 end

	local len = #dec
	local step = 10 ^ (-len)
	return step >= 1 and 1 or step
end

---Checks whether a numeric value lies within a specified inclusive range.
---@param value number # The value to check.
---@param min number? # The minimum allowed value. Defaults to -infinity if not a number.
---@param max number? # The maximum allowed value. Defaults to infinity if not a number.
---@return boolean # True if `value` is within [min, max], otherwise false.
local function inRange(value, min, max)
	if not isNumber(value) then return false end
	if not isNumber(min) then min = -math.huge end
	if not isNumber(max) then max = math.huge end
	return value >= min and value <= max
end

---Clamps a numeric value to be within a specified range.
---@param value number # The value to clamp.
---@param min number? # The minimum allowed value. Defaults to -infinity if not a number.
---@param max number? # The maximum allowed value. Defaults to infinity if not a number.
---@return number # The clamped value within [min, max].
local function clamp(value, min, max)
	if not isNumber(value) then return 0 end
	if not isNumber(min) then min = -math.huge end
	if not isNumber(max) then max = math.huge end
	return math.min(math.max(value, min), max)
end

---Compares two values as alphanumeric strings.
---Strings are compared alphabetically, but numeric substrings are
---compared as numbers to ensure natural ordering.
---For example, "foo2" < "foo13".
---@param a any # First value to compare.
---@param b any # Second value to compare.
---@return boolean # True if `a` should come before `b`, false otherwise.
local function alphaNumericCompare(a, b)
	a, b = tostring(a), tostring(b)
	local ai, bi = 1, 1
	while ai <= #a and bi <= #b do
		local aPart = a:match("^%D*", ai)
		local bPart = b:match("^%D*", bi)
		if aPart ~= bPart then
			return aPart < bPart
		end

		ai = ai + #aPart
		bi = bi + #bPart

		local aNum = a:match("^%d+", ai)
		local bNum = b:match("^%d+", bi)
		if aNum and bNum then
			aNum, bNum = tonumber(aNum), tonumber(bNum)
			if aNum ~= bNum then
				return aNum < bNum
			end
		elseif aNum then
			return true
		elseif bNum then
			return false
		end

		ai = ai + (aNum and #tostring(aNum) or 0)
		bi = bi + (bNum and #tostring(bNum) or 0)
	end
	return #a < #b
end

---Compares two values for equality, including support for numbers with tolerance and nested tables.
---Performs deep comparison for tables and numeric tolerance (1e-4) for numbers or number-like strings.
---Also supports booleans, nil, functions, userdata, and threads using standard equality (`==`).
---Handles recursive tables safely using a visited map to prevent infinite loops.
---@param a any # The first value to compare.
---@param b any # The second value to compare.
---@param visited? table<any, any> # Internal cache to handle cyclic table references (do not provide manually).
---@return boolean # True if values are considered equal, false otherwise.
local function equals(a, b, visited)
	if a == b then return true end
	if type(a) ~= type(b) then return false end

	if isNumber(a) then
		return abs(a - b) < 1e-4
	elseif isString(a) and areNumeric(a, b) then
		local na, nb = tonumber(a), tonumber(b)
		return abs(na - nb) < 1e-4
	elseif isTable(a) then
		visited = visited or {}
		if visited[a] and visited[a] == b then
			return true
		end
		visited[a] = b

		for k, va in pairs(a) do
			if not equals(va, b[k], visited) then
				return false
			end
		end
		for k, vb in pairs(b) do
			if not equals(vb, a[k], visited) then
				return false
			end
		end
		return true
	elseif areVector3(a, b) then
		return equals(a.x, b.x) and equals(a.y, b.y) and equals(a.z, b.z)
	end

	return false
end

---Checks if a given value is equal to any of the provided comparison values.
---@param x any # The value to compare.
---@param ... any # A variable number of values to compare against.
---@return boolean True # if `a` equals at least one of the provided values, otherwise false.
local function equalsAny(x, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if equals(x, v) then
			return true
		end
	end
	return false
end

---Checks whether a given value is contained within another value.
---For strings and numbers, it checks containment (prefix match for numbers, substring for strings).
---For tables, it distinguishes between arrays and key-value tables:
--- - Arrays: checks if any value equals the target.
--- - Key-value tables: checks if the key equals the target.
---@param x any # The container value (string, number, or table).
---@param v any # The value to search for.
---@return boolean # True if the value is found, false otherwise.
local function contains(x, v)
	if x == nil or v == nil then return false end
	if x == v then return true end

	if isUserdata(x) then
		local s = tostring(x)
		return contains(s, v)
	end

	if areNumeric(x, v) then
		local xs, vs = tostring(x), tostring(v)
		return #xs >= #vs and xs:sub(1, #vs) == vs
	end

	if isString(x) then
		local vs = tostring(v)
		return #x >= #vs and x:find(vs, 1, true) ~= nil
	end

	if not isTable(x) then return false end

	if isArray(x) then
		for _, e in ipairs(x) do
			if equals(e, v) then
				return true
			end
		end
		return false
	end

	for k, _ in pairs(x) do
		if equals(k, v) then
			return true
		end
	end

	return false
end

---Checks if a string starts or ends with a given affix.
---@param s string # The string to check.
---@param v string # The prefix or suffix to match.
---@param atEnd boolean # If true, checks suffix (ends with); if false, checks prefix (starts with).
---@param caseInsensitive boolean? # If true, ignores case when comparing.
---@return boolean # True if the condition is met, false otherwise.
local function hasAffix(s, v, atEnd, caseInsensitive)
	if not s or not v then return false end
	s, v = tostring(s), tostring(v)
	if caseInsensitive then
		s = s:lower()
		v = v:lower()
	end
	local len = #v
	if #s == len then return s == v end
	if #s < len then return false end
	return (atEnd and s:sub(-len) or s:sub(1, len)) == v
end

---Checks if a string starts with a given prefix.
---@param s string # The string to check.
---@param v string # The prefix to match.
---@param caseInsensitive boolean? # True if string comparisons ignore letter case.
---@return boolean # True if `s` starts with `v`, false otherwise.
local function startsWith(s, v, caseInsensitive)
	return hasAffix(s, v, false, caseInsensitive)
end

---Checks if a string ends with a specified suffix.
---@param s string # The string to check.
---@param v string # The suffix to look for.
---@param caseInsensitive boolean? # True if string comparisons ignore letter case.
---@return boolean Returns # True if the `s` ends with the specified `v`, otherwise false.
local function endsWith(s, v, caseInsensitive)
	return hasAffix(s, v, true, caseInsensitive)
end

---Checks if a given filename string ends with `.lua`.
---@param s string # The value to check, typically a string representing a filename.
---@return boolean # True if the filename ends with `.lua`, otherwise false.
local function hasLuaExt(s)
	return endsWith(s, ".lua", true)
end

---Returns the file name with a `.lua` extension. If the input already ends with `.lua`, it is returned unchanged.
---@param s string # The input value to be converted to a Lua file name.
---@return string # The file name with `.lua` extension, or an empty string if the input is nil.
local function ensureLuaExt(s)
	if not isStringValid(s) then return "" end
	return hasLuaExt(s) and s or s .. ".lua"
end

---Removes the `.lua` extension from a filename if present.
---@param s string # The filename to process.
---@return string # The filename without `.lua` extension, or the original string if no `.lua` extension is found.
local function trimLuaExt(s)
	if not isStringValid(s) then return "" end
	return hasLuaExt(s) and s:sub(1, -5) or s
end

---Truncates a string in the middle if it exceeds a maximum length and inserts "..." to indicate omitted content.
---@param s string # The original string.
---@param length integer # The maximum allowed length of the returned string.
---@return string # The truncated string with "..." in the middle if needed.
local function truncateMiddle(s, length)
	if not isStringValid(s) then return "" end
	if not isNumber(length) or length < 6 or #s <= length then return s end
	local half = floor((length - 3) / 2)
	return s:sub(1, half) .. "..." .. s:sub(#s - half + 1)
end

---Capitalizes the first letter of each word in a string.
---@param s string # The input string to process.
---@return string # The string with each word's first letter capitalized.
local function capitalizeWords(s)
	if not isStringValid(s) then return "" end
	return s:gsub("(%w)([%w']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end) or s
end

---Converts a camelCase string into a human-readable title.
---@param s string # The camelCase string to convert.
---@return string # A title-cased string with spaces inserted before uppercase letters.
local function camelToHuman(s)
	if not isStringValid(s) then return "" end
	s = s:gsub("(%l)(%u)", "%1 %2")
	s = s:gsub("^%l", string.upper)
	return s
end

---Splits a string into a list of substrings using a specified separator.
---@param s string? # The input string to split. If nil, returns an empty table.
---@param sep string? # The separator to split by (default: ",").
---@param trim boolean? # If true, trims whitespace from each resulting entry.
---@return string[] # A list of substrings resulting from the split.
local function split(s, sep, trim)
	if not s then return {} end
	s = tostring(s)
	sep = sep or ","
	local t = {}
	for v in s:gmatch("([^" .. sep .. "]+)") do
		insert(t, trim and v:match("^%s*(.-)%s*$") or v)
	end
	return t
end

---Removes a substring from a string either globally, only at the start, or only at the end.
---@param s string The input string to process.
---@param sub string The substring to remove.
---@param mode number? # 1 = start only, -1 = end only, or anything else = remove all.
---@param caseInsensitive boolean? # If true, ignores case when matching the substring. Has no effect if mode is nil (removal anywhere).
---@return string The modified string with the specified removal.
local function strip(s, sub, mode, caseInsensitive)
	if not areString(s, sub) or #sub == 0 or #s < #sub then return s end

	if mode == 1 then
		if startsWith(s, sub, caseInsensitive) then
			return s:sub(#sub + 1)
		end
	elseif mode == -1 then
		if endsWith(s, sub, caseInsensitive) then
			return s:sub(1, - #sub - 1)
		end
	else
		local seek = sub:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		return (s:gsub(seek, ""))
	end

	return s
end

---Returns a shortened version of the input string by removing a number of trailing underscore-separated parts.
---The number of parts removed depends on how many underscores are in the string.
---@param s string # The input string (e.g., "v_sport2_porsche_911turbo_player").
---@return string # The shortened string (e.g., "v_sport2_porsche_911turbo").
local function chopUnderscoreParts(s)
	if not isStringValid(s) then return "" end
	local t = {}
	for p in s:gmatch("[^_]+") do
		insert(t, p)
	end
	local n = floor(#t / 1.25)
	return concat(t, "_", 1, n)
end

---Concatenates multiple path segments into a single path using '/' as separator.
---@vararg string # The path segments to combine.
---@return string # The combined path. Returns an empty string if no arguments are given.
local function combine(...)
	local len = select("#", ...)
	if len < 1 then return "" end
	if len == 1 then return select(1, ...) end
	return concat({ ... }, "/")
end

---Ordered pairs iterator that returns key–value pairs sorted either by key or by one or more given fields.
---If multiple sort fields are provided, they are applied in order of priority (left to right).
---If all compared values are equal, the key itself is used as a final fallback for ordering.
---@param t table # Source table to iterate over.
---@param ... string # Optional sort fields inside each table entry. The first has highest priority.
---@return function # Iterator function returning sorted key–value pairs.
local function opairs(t, ...)
	t = isTable(t) and t or {}
	local sortKeys = { ... }
	local sorted = {}

	for k in pairs(t) do
		insert(sorted, k)
	end

	if #sortKeys > 0 then
		sort(sorted, function(a, b)
			local va, vb = t[a], t[b]

			for _, field in ipairs(sortKeys) do
				local da = (va and va[field]) or ""
				local db = (vb and vb[field]) or ""
				if da ~= db then
					return alphaNumericCompare(da, db)
				end
			end

			return alphaNumericCompare(a, b)
		end)
	else
		sort(sorted, alphaNumericCompare)
	end

	local i = 0
	return function()
		i = i + 1
		local k = sorted[i]
		if k ~= nil then
			return k, t[k]
		end
	end
end

---Creates a deep copy of a given table, including nested subtables.
---@param t table # The table to copy.
---@param seen table? # Internal table to track already-copied references (prevents cycles).
---@return table # A new table with the same structure and values as the original.
local function clone(t, seen)
	if not isTable(t) then return t end
	if seen and seen[t] then return seen[t] end

	local result = {}
	seen = seen or {}
	seen[t] = result

	for k, v in pairs(t) do
		result[k] = clone(v, seen)
	end

	return result
end

---Merges multiple tables into a cloned base table.
---Each additional table overrides existing values in order of appearance.
---@param base table # The base table to clone.
---@param ... table # One or more tables whose values override those in the cloned base.
---@return table # A merged clone containing values from all provided tables.
local function merge(base, ...)
	local merged = clone(base) or {}
	for i = 1, select("#", ...), 1 do
		local t = select(i, ...)
		if isTableValid(t) then
			for k, v in pairs(t) do
				merged[k] = clone(v)
			end
		end
	end
	return merged
end

---Ensures a nested table path exists and returns the deepest subtable if `t` is a valid table.
---@param t table # The table to access.
---@param ... any # Keys leading to the nested table
---@return any # The final nested subtable if `t` is a table; otherwise nil.
local function deep(t, ...)
	if not isTable(t) then return nil end
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		t[k] = t[k] or {}
		t = t[k]
	end
	return t
end

---Safely retrieves a nested value from a table (e.g., table[one][two][three]).
---Returns a default value if any level is missing or invalid.
---@param t table # The root table to access.
---@param fallback any # The fallback value if the lookup fails.
---@param ... any # One or more keys representing the path.
---@return any # The nested value if it exists, or the default value.
local function get(t, fallback, ...)
	if not isTable(t) then return fallback end
	local v = t
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		if not isTable(v) or k == nil then
			return fallback
		end
		v = rawget(v, k)
	end
	return v == nil and fallback or v
end

---Returns the value at the specified index from a variable list of arguments.
---If the index is beyond the number of available arguments, the last value is returned instead.
---@param i number # The index of the value to retrieve (1-based).
---@param ... any # A variable number of values to select from.
---@return any # The value at index `i`, or the last value if `i` is too large.
local function pick(i, ...)
	local len = select("#", ...)
	return select(i < len and i or len, ...)
end

---Returns the i-th element of a table or the value itself if it's not a table.
---@param x any # A table or any other value.
---@param i integer # Index to access if values is a table.
---@return any # The element at index i if values is a table, otherwise values itself.
local function pluck(x, i)
	return isTable(x) and x[i] or x
end

---Converts any value to a readable string representation.
---For numbers, a trimmed 3-digit float format is used (e.g., 1.000 → "1", 3.140 → "3.14").
---For tables, the output is compact, recursively formatted, and uses sorted keys.
---Numeric keys in non-array tables are automatically converted to hexadecimal.
---Can optionally produce pretty-printed output with indentation.
---@param x any # The value to serialize.
---@param pretty boolean? # Optional. If true, output is formatted with line breaks and indentation.
---@param hexNums boolean? # Optional. If true, numbers are serialized in hexadecimal
---@param indent integer? # Internal indentation level (do not provide manually).
---@return string # The serialized string representation of `x`.
local function serialize(x, pretty, hexNums, indent)
	hexNums = hexNums or false
	indent = indent or 0

	if not isTable(x) then
		if isString(x) then
			return format("%q", x:gsub("\n", "\\n"))
		elseif isNumeric(x) then
			local str = format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")
			return hexNums and format("0x%04X", str) or str
		elseif isVector3(x) then
			return format("Vector3{x=%s,y=%s,z=%s}",
				serialize(x.x, pretty, hexNums, indent),
				serialize(x.y, pretty, hexNums, indent),
				serialize(x.z, pretty, hexNums, indent))
		else
			return tostring(x)
		end
	end

	if areNumber(x.Major, x.Minor, x.Build, x.Revision) then
		if x.Revision > 0 then
			return format("%d.%d.%d.%d", x.Major, x.Minor, x.Build, x.Revision)
		elseif x.Build > 0 then
			return format("%d.%d.%d", x.Major, x.Minor, x.Build)
		else
			return format("%d.%d", x.Major, x.Minor)
		end
	end

	local isArr = isArray(x)
	local parts = {}
	for k, v in opairs(x) do
		local key
		if isString(k) and k:match("^[%a_][%w_]*$") then
			key = k
		else
			key = format("[%s]", serialize(k, pretty, not isArr and isNumeric(k), indent))
		end
		local value = serialize(v, pretty, hexNums, indent + 1)
		if pretty then
			parts[#parts + 1] = format("%s%s = %s", rep("\t", indent + 1), key, value)
		else
			parts[#parts + 1] = format("%s=%s", key, value)
		end
	end

	if #parts > 0 then
		if pretty then
			return format("{\n%s\n%s}", concat(parts, ",\n"), rep("\t", indent))
		end
		return format("{%s}", concat(parts, ","))
	end
	return "{}"
end

---Deserializes a string or a Lua file into a function without executing it.
---Returns a callable function representing the code and an optional error message.
---@param x string # A Lua code string or a path to a Lua file.
---@param isFile boolean? # Whether `x` is a path to a Lua file.
---@return function? # Callable function that executes the code when called.
---@return string? # Error message if the code could not be loaded.
local function deserialize(x, isFile)
	if not isStringValid(x) then return nil, nil end

	if isFile then
		local ok, result = pcall(loadfile, x)
		return ok and result or nil
	end

	local str = x:match("^%s*return") and x or "return " .. x
	local ok, result = pcall(loadstring, str)
	return ok and result or nil
end

---Computes an Adler-53 checksum over one or more values without allocating a new table.
---
---This function implements a custom 53-bit variant of the Adler checksum algorithm,
---designed by me through minimal mathematical adjustments to the original.
---
---It improves upon Adler-32 by using a much larger prime modulus and a wider final hash space,
---which significantly reduces the chance of hash collisions, even with shorter inputs.
---
---The result fits within Lua's numeric precision limit for integers (53 bits), making it safe
---to use as a numeric key or identifier without loss of accuracy.
---
---Compared to Adler-32, Adler-53 offers:
--- - A larger prime modulus (2^26-5) for better distribution
--- - Full use of Lua's 53-bit integer precision
--- - Improved robustness against uniform or repeating byte patterns
---
---This makes it suitable for identifying or caching structured values, serialized content,
---or any use case where a compact and deterministic hash is required.
---@param ... any # One or more values to include in the checksum calculation.
---@return integer # 53-bit checksum combining all arguments.
local function checksum(...)
	local prime = 0x3fffffb
	local a, b = 1, 0
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		local s = serialize(v)
		for j = 1, #s do
			local x = s:byte(j)
			a = (a + x) % prime
			b = (b + a) % prime
		end
	end
	return floor(b * 2 ^ 26 + a)
end

---Checks whether a file with the given name exists and is readable.
---@param path string # The full or relative path to the file.
---@return boolean # True if the file exists and is readable, false otherwise.
local function fileExists(path)
	if not isString(path) then return false end
	local handle = io.open(path, "r")
	if handle then
		handle:close()
		return true
	end
	return false
end

---Parses a version string or returns an existing `IVersion` table.
---Accepts version formats like "[v]Major[.Minor[.Build[.Revision]]]".
---@param x table|string # A version input as a string, or IVersion table.
---@return IVersion # A table with Major, Minor, Build, and Revision fields as numbers.
local function parseVersion(x)
	if isTable(x) and isNumber(x.Major) then ---@cast x IVersion
		return x
	end
	if not isString(x) then
		x = tostring(x) ---@cast x string
	end
	local v1, v2, v3, v4 = x:match("^v?(%d+)%.?(%d*)%.?(%d*)%.?(%d*)$")
	return {
		Major = tonumber(v1) or 0,
		Minor = tonumber(v2) or 0,
		Build = tonumber(v3) or 0,
		Revision = tonumber(v4) or 0
	}
end

---Compares two version strings in "[v]Major[.Minor[.Build[.Revision]]]" format.
---Returns 1 if a > b, -1 if a < b, or 0 if equal.
---@param a IVersion|string # First version.
---@param b IVersion|string # Second version.
---@return integer # 1 if `a > b`, -1 if `a < b`, 0 if equal.
local function compareVersion(a, b)
	local v1 = parseVersion(a)
	local v2 = parseVersion(b)
	for _, k in ipairs({
		"Major",
		"Minor",
		"Build",
		"Revision"
	}) do
		local n1 = v1[k] or 0
		local n2 = v2[k] or 0
		if n1 > n2 then
			return 1
		elseif n1 < n2 then
			return -1
		end
	end
	return 0
end

---Checks if the current game version is less than or equal to the specified version.
---@param current IVersion|string # The version string to compare.
---@param require IVersion|string # Maxmium required version in "[v]major[.minor[.build[.revision]]]" format.
---@return boolean # True if the runtime version is <= the specified version, false otherwise.
local function isVersionAtMost(current, require)
	return compareVersion(current, require) <= 0
end

---Checks if the runtime version is greater than or equal to a specified minimum version.
---@param current IVersion|string # The version string to compare.
---@param require IVersion|string # Minimum required version in "[v]major[.minor[.build[.revision]]]" format.
---@return boolean # True if the runtime version is >= the specified version, false otherwise.
local function isVersionAtLeast(current, require)
	return compareVersion(current, require) >= 0
end

---Retrieves the current game version `string` or a parsed `IVersion` table.
---@return IVersion # Parsed version object if `asString` is false/nil, otherwise the version string.
local function getGameVersion()
	local sys = Game.GetSystemRequestsHandler()
	local str = sys and sys:GetGameVersion()
	local ver = parseVersion(str)
	if ver.Minor < 10 then
		ver.Minor = ver.Minor * 10
	end
	return ver
end

---Retrieves the current CET (runtime) version `string` or a parsed `IVersion` table.
---@return IVersion # Parsed version object if `asString` is false/nil, otherwise the version string.
local function getRuntimeVersion()
	return parseVersion(GetVersion())
end

---Initializes a table in the database.
---Creates the table if it does not exist.
---@param tableName string # Name of the table to create.
---@param ... string # Column definitions, each as a separate string.
local function sqliteInit(tableName, ...)
	assert(isStringValid(tableName) and select("#", ...) > 0, Text.THROW_SQL_INIT)
	local columns = concat({ ... }, ", ")
	local query = format("CREATE TABLE IF NOT EXISTS %s(%s);", tableName, columns)
	db:exec(query)
end

---Begins a transaction.
local function sqliteBegin()
	db:exec("BEGIN;")
end

---Commits a transaction.
local function sqliteCommit()
	db:exec("COMMIT;")
end

---Rebuilds the database file to reclaim free space and remove deleted content.
local function sqliteVacuum()
	return db:exec("VACUUM;")
end

---Returns an iterator over the rows of a table.
---Each yielded row is an array (table) of column values.
---@param tableName string # Name of the table.
---@param ... string # Optional column names to select, defaults to `*`.
---@return (fun(): table)? # Iterator returning a row table or nil when finished.
local function sqliteRows(tableName, ...)
	if not isStringValid(tableName) then return end
	local columns = select("#", ...) > 0 and concat({ ... }, ", ") or "*"
	local query = format("SELECT %s FROM %s;", columns, tableName)
	return db:rows(query)
end

---Inserts or updates a row by primary key.
---If a conflict on the key occurs, the existing row will be updated.
---@param tableName string # Name of the table to insert into.
---@param keyColumn string # Column that acts as the primary key.
---@param colValPairs table # Key-value table of columns and their values.
---@return boolean? # True on success, nil on failure.
local function sqliteUpsert(tableName, keyColumn, colValPairs)
	assert(areStringValid(tableName, keyColumn) and isTableValid(colValPairs), Text.THROW_SQL_UPSERT)
	local fields, values, updates = {}, {}, {}
	for c, v in pairs(colValPairs) do
		insert(fields, c)
		if isBoolean(v) or isNumber(v) then
			insert(values, tostring(v))
		else
			if not isString(v) then
				v = serialize(v)
			end
			v = v:gsub("'", "''")
			insert(values, "'" .. v .. "'")
		end
		insert(updates, c .. "=excluded." .. c)
	end
	local query = format("INSERT INTO %s(%s) VALUES(%s) ON CONFLICT(%s) DO UPDATE SET %s;",
		tableName,
		concat(fields, ","),
		concat(values, ","),
		keyColumn,
		concat(updates, ","))
	return db:exec(query)
end

---Deletes a row from the table using a specific key.
---@param tableName string # Name of the table.
---@param keyColumn string # Column used as the key.
---@param keyValue any # Value of the key to delete.
local function sqliteDelete(tableName, keyColumn, keyValue)
	assert(areStringValid(tableName, keyColumn, keyValue), Text.THROW_SQL_DELETE)
	db:exec(format("DELETE FROM %s WHERE %s='%s';", tableName, keyColumn, keyValue:gsub("'", "''")))
end

---Checks whether a cache (persistent or transient) contains any non-empty value.
---@param persistent boolean? # If true, check the persistent cache; otherwise check the transient cache.
---@return boolean # True if at least one entry exists and is not nil or empty, false otherwise.
local function isCachePopulated(persistent)
	local cache = persistent and caches.persistent or caches.transient
	for _, value in pairs(cache) do
		if not nilOrEmpty(value) then
			return true
		end
	end
	return false
end

---Retrieves a sub-cache from `caches.persistent` or `caches.transient`, initializing it with a default if it does not exist.
---@param id number # Unique ID of the sub-cache to retrieve.
---@param persistent boolean? # Optional. If true, use persistent cache; defaults to transient.
---@return any # The existing or initialized value of the sub-cache.
local function getCache(id, persistent)
	assert(id, Text.THROW_CACHE_ID)
	return persistent and caches.persistent[id] or caches.transient[id]
end

---Sets a sub-cache in `caches.persistent` or `caches.transient`, creating it if needed.
---@param id number # Unique ID of the sub-cache to set.
---@param value any # The value to store in the cache.
---@param persistent boolean? # Optional. If true, use persistent cache; defaults to transient.
---@return any # The stored value.
local function setCache(id, value, persistent)
	assert(id, Text.THROW_CACHE_ID)
	if not id then return value end
	if persistent then
		caches.persistent[id] = value
	else
		caches.transient[id] = value
	end
	return value
end

---Resets either the `caches.persistent` or `caches.transient` by replacing it with a new empty table.
---@param persistent boolean? # If true, reset the persistent cache; otherwise reset the transient cache.
local function resetCache(persistent)
	if persistent then
		caches.persistent = {}
	else
		caches.transient = {}
	end
end

---Logs and displays messages based on the current `state.devMode` level.
---Messages can be written to the log file, printed to the console, or shown as in-game alerts.
---@param lvl LogLevelType # Logging level (0 = Info, 1 = Warning, 2 = Error).
---@param id integer # The ID used for location tracing.
---@param fmt string # A format string for the message.
---@vararg any # Additional arguments for formatting the message. Tables and userdata will be serialized automatically.
local function log(lvl, id, fmt, ...)
	if state.devMode < DevLevels.BASIC then return end

	lvl = clamp(lvl, LogLevels.INFO, LogLevels.ERROR)

	if nilOrEmpty(fmt) then
		lvl = LogLevels.ERROR
		fmt = "Format string in log() is empty!"
	end

	local cache = getCache(0x8069, true) or {}
	local hash = checksum(lvl, id, fmt, ...)
	local now = os.time()
	if cache[hash] and cache[hash] >= now then return end

	local cutoff = now - 60
	for k, v in pairs(cache) do
		if v < cutoff then
			cache[k] = nil
		end
	end

	cache[hash] = now + 5
	setCache(0x8069, cache, true)

	local len = select("#", ...)
	local tag = LogMeta[lvl].TAG
	local str
	if len < 1 then
		str = fmt
	else
		local args = {}
		for i = 1, len do
			local v = select(i, ...)
			args[i] = (isTable(v) or isUserdata(v)) and serialize(v) or v
		end
		local ok, result = pcall(format, fmt, unpack(args))
		str = ok and result or Text.LOG_FORMAT_INVALID
	end
	local msg = format("[%s]  [%04X]  %s  %s", Text.GUI_NAME, id or 0, tag, str)

	if state.devMode >= DevLevels.FULL then
		(lvl == LogLevels.ERROR and spdlog.error or spdlog.info)(msg)
	end

	if state.devMode >= DevLevels.ALERT then
		if state.isCetTopical then
			local toast = format("%s %s", LogMeta[lvl].ICON, str)
			local kind = LogMeta[lvl].TOAST
			gui.toasterBumps[kind] = gui.toasterBumps[kind] and (gui.toasterBumps[kind] .. "\n\n" .. toast) or toast
			gui.areToastsPending = true
		else
			local player = Game.GetPlayer()
			if player then
				player:SetWarningMessage(msg, 5)
			end
		end
	end

	print(msg)
end

---Forces a log message to be emitted using a temporary `state.devMode` override.
---Useful for outputting messages regardless of the current developer mode setting.
---Internally calls `log()` with the given parameters, then restores the previous `state.devMode`.
---@param mode DevLevelType # Temporary development mode to use.
---@param lvl LogLevelType # Log level passed to `log()`.
---@param id integer # The ID used for location tracing.
---@param fmt string # Format string for the message.
---@vararg any # Optional arguments for formatting the message. Tables and userdata will be serialized automatically.
local function logF(mode, lvl, id, fmt, ...)
	if mode < DevLevels.BASIC and mode < DevLevels.OVERLAY then return end
	local prev = state.devMode
	state.devMode = prev < mode and mode or prev
	log(lvl, id, fmt, ...)
	state.devMode = prev
end

---Logs a formatted message if the current `state.devMode` meets or exceeds the specified threshold.
---Internally calls `log()` with the given parameters.
---@param mode DevLevelType # Minimum development mode required to output the log.
---@param lvl LogLevelType # Log level passed to `log()`.
---@param id integer # The ID used for location tracing.
---@param fmt string # Format string for the message.
---@vararg any # Optional arguments for formatting the message. Tables and userdata will be serialized automatically.
local function logIf(mode, lvl, id, fmt, ...)
	if state.devMode == DevLevels.DISABLED or state.devMode < mode then return end
	log(lvl, id, fmt, ...)
end

---Stops and removes an active async timer with the given ID.
---Has no effect if the ID is invalid or already cleared.
---@param target number|boolean # The timer ID to stop, or a boolean to stop all timers.
local function asyncStop(target)
	if not target then return end
	if isBoolean(target) then
		for id in pairs(async.timers) do
			async.timers[id] = nil
		end
	elseif isNumber(target) then
		async.timers[target] = nil
	end
	async.isActive = isTableValid(async.timers)
end

---Creates a recurring async timer that executes a callback every `interval` seconds.
---The first execution happens only after the initial interval has passed, not immediately at creation time.
---The callback receives the timer ID as its only argument.
---@param interval number # Time in seconds between executions (absolute value is used).
---@param callback fun(id: integer) # Function to execute each cycle.
---@return integer timerID # Unique ID of the created timer, or -1 if invalid parameters were passed.
local function asyncRepeat(interval, callback)
	if not callback then return -1 end

	async.idCounter = async.idCounter + 1

	local id = async.idCounter
	local time = abs(tonumber(interval) or 0)
	async.timers[id] = {
		Interval = time,
		Callback = callback,
		Time = time,
		IsActive = true
	}

	async.isActive = true

	return id
end

---Executes the callback immediately once, then creates a recurring async timer that executes the callback every `interval` seconds.
---@param interval number # Time in seconds between executions (absolute value is used).
---@param callback fun(id: integer) # Function to execute each cycle.
---@return integer timerID # Unique ID of the created timer, or -1 if invalid parameters were passed.
local function asyncRepeatBurst(interval, callback)
	if not callback then return -1 end
	local id = asyncRepeat(interval, callback)
	callback(id)
	return id
end

---Creates a one-shot async timer that executes a callback once after `delay` seconds.
---@param delay number # Time in seconds before execution (absolute value is used).
---@param callback fun(id: integer?) # Function to execute once after the delay.
---@return integer timerID # Unique ID of the created timer, or -1 if invalid parameters were passed.
local function asyncOnce(delay, callback)
	if not callback then return -1 end
	return asyncRepeat(delay, function(id)
		asyncStop(id)
		callback(id)
	end)
end


---Asynchronously downloads a file via HTTP GET and writes its body to disk.
---Fails silently (returns from the callback) if the response status is not 200,
---if the `Content-Type` header does not match `contentType`, or if the target
---file cannot be opened for writing.
---@param fileUrl string # The URL to fetch the file from.
---@param filePath string # The full or relative path the response body is written to.
---@param contentType? string # Optional expected `Content-Type`; skips the check if nil.
---@param onSuccess? fun(data: string) # Optional callback invoked with the response body after a successful write.
local function asyncDownloadFile(fileUrl, filePath, contentType, onSuccess)
	---@diagnostic disable: undefined-global

	if not isUserdata(AsyncHttpClient) then return end

	local httpListener = NewProxy({
		onResponse = {
			args = {
				"handle:HttpResponse"
			},
			callback = function(response)
				local status = response:GetStatusCode()
				if status ~= 200 then
					logF(DevLevels.ALERT, LogLevels.ERROR, 0, Text.LOG_DL_STAT_FAIL, status)
					return false
				end

				local type = response:GetHeader("Content-Type")
				if contentType ~= nil and type ~= contentType then
					logF(DevLevels.ALERT, LogLevels.ERROR, 0, Text.LOG_DL_TYPE_MISM, contentType, type)
					return false
				end

				local data = response:GetText()
				if not data then return false end

				local file = io.open(filePath, "w")
				if not file then return false end
				file:write(data)
				file:close()
				if isFunction(onSuccess) then ---@cast onSuccess function
					onSuccess(data)
				end

				return true
			end
		}
	})

	local callback = HttpCallback.Create(httpListener:Target(), httpListener:Function("onResponse"))
	if callback ~= nil then
		AsyncHttpClient.Get(callback, fileUrl)
	end

	---@diagnostic enable undefined-global
end

--#endregion

--#region 🔦 Game Metadata

---Retrieves a value from the game settings database using the appropriate getter.
---Supports both Lua type names ("boolean", "number") and native game types ("Bool", "Int", "Float").
---@param path string # The configuration group path (e.g. "Streaming/Culling/AutoHideDistanceNear").
---@param key string # The specific setting key inside the group.
---@param kind string # Optional type identifier ("boolean", "number", "Bool", "Int", "Float").
---@return any # The retrieved value or nil if the type is unsupported or unavailable.
local function getGameOption(path, key, kind)
	if equalsAny(kind, "boolean", "Bool") then
		return GameOptions.GetBool(path, key)
	elseif kind == "Int" then
		return GameOptions.GetInt(path, key)
	elseif kind == "Float" then
		return GameOptions.GetFloat(path, key)
	elseif kind == "number" then
		local raw = GameOptions.Get(path, key)
		if not isNumeric(raw) then return nil end
		return tostring(raw):find("%.") and GameOptions.GetFloat(path, key) or GameOptions.GetInt(path, key)
	elseif equalsAny(kind, "string", "String") then
		return GameOptions.Get(path, key)
	end
	return nil
end

---Sets a game INI configuration option only if its value has changed.
---Supports automatic or explicit type selection for safe updates.
---If the optional `kind` parameter is omitted, the function infers it from the Lua type of `value`.
---@param path string # The configuration path (e.g. "Streaming/Culling/AutoHideDistanceNear").
---@param key string # The option key within the given path.
---@param value any # The new value to assign.
---@param kind? string # Optional explicit type ("Bool", "Int", "Float", "String", or Lua types "boolean", "number", "string"). Defaults to `type(value)`.
local function setGameOption(path, key, value, kind)
	kind = kind or type(value)

	local current = getGameOption(path, key, kind)
	if current == nil or current == value then return end

	if equalsAny(kind, "boolean", "Bool") then
		GameOptions.SetBool(path, key, value)
	elseif kind == "Int" then
		GameOptions.SetInt(path, key, value)
	elseif kind == "Float" then
		GameOptions.SetFloat(path, key, value)
	elseif kind == "number" then
		if value % 1 ~= 0 then
			if abs(current - value) > 1e-4 then
				GameOptions.SetFloat(path, key, value)
			end
		else
			GameOptions.SetInt(path, key, value)
		end
	elseif equalsAny(kind, "string", "String") then
		GameOptions.Set(path, key, value)
	end
end

---Retrieves detailed information about a specific game setting option from the settings system.
---Returns an empty table if the requested option is invalid or unavailable.
---@param group string # The group identifier of the game setting.
---@param option string # The option name within the specified group.
---@param fresh boolean? # If true, forces retrieval from the settings system instead of using cached data.
---@return IGameConfigOption # The structured information for the given game option.
local function getUserSettingsOption(group, option, fresh)
	if not areStringValid(group, option) then return {} end

	local cache = getCache(0xf7f7, true) or {}
	local id = checksum(group, option)
	if fresh ~= true and cache[id] then return cache[id] end

	local sys = Game.GetSettingsSystem()
	local var = sys and sys:HasVar(group, option) and sys:GetVar(group, option)
	if not var then return {} end

	local kind = var:GetType().value
	local value = var:GetValue()
	if isUserdata(value) then
		value = Game.NameToString(value)
	end

	local result = {
		Group = group,
		Name = option,
		Type = kind,
		Value = value
	}

	if equals(kind, "Bool") then
		result.DefaultValue = var:GetDefaultValue()
	elseif equalsAny(kind, "Int", "Float") then
		result.DefaultValue = var:GetDefaultValue()
		result.MinValue = var:GetMinValue()
		result.MaxValue = var:GetMaxValue()
		result.StepValue = var:GetStepValue()
	elseif equalsAny(kind, "IntList", "FloatList", "NameList", "StringList") then
		local values = var:GetValues() or {}
		if startsWith(kind, "Name") then
			for i, v in ipairs(values) do
				values[i] = Game.NameToString(v)
			end
		end
		local defIndex = var:GetDefaultIndex() + 1
		result.DefaultValue = values[defIndex]
		result.Index = var:GetIndex() + 1
		result.DefaultIndex = defIndex
		result.Values = values
	end

	cache[id] = result
	setCache(0xf7f7, cache, true)
	return result
end

---Retrieves the current third-person vehicle camera height setting from the settings system.
---@return string? # The current value of the third-person vehicle camera height setting, or nil if not found.
local function getUserSettingsCameraHeight()
	local settings = getUserSettingsOption("/controls/vehicle", "VehicleTPPCameraHeight", true)
	---@cast settings table<string, string>
	return isTableValid(settings) and settings.Value or nil
end

---Converts the FOV value between internal and settings formats, applying fallback logic when FovControl is unavailable.
---If `FovControl` is missing, returns the value directly (rounded if not in settings format).
---@param value number # The FOV value to convert.
---@param isSettingsFormat boolean? # True to convert from internal to settings format, false to convert from settings to internal.
---@return number # The converted FOV value, rounded if appropriate.
local function changeFovFormat(value, isSettingsFormat)
	if not state.isFovControlAvailable then
		return isSettingsFormat and value or roundF(value)
	end
	--Ensures that 101 maps back to the internal default 69.
	if isSettingsFormat and value == 101 then
		return 69
	end
	---@diagnostic disable-next-line: undefined-global
	local fov = FovControl.ConvertFormat(value or 0, isSettingsFormat)
	return isSettingsFormat and fov or roundF(fov)
end

--#endregion

--#region 🚗 Vehicle Metadata

---Returns a list of all player vehicles from the game database.
---@return TDBID[] # An array of all vehicle records.
local function getPlayerVehicles()
	local cache = getCache(0x4003, true)
	if cache then return cache end
	return setCache(0x4003, TweakDB:GetFlat("Vehicle.vehicle_list.list") or {}, true)
end

---Returns the number of vanilla vehicles in the game, depending on the game version.
---@return number # The total count of vanilla vehicles.
local function getVanillaVehicleCount()
	local cache = getCache(0x0a00, true)
	if cache then return cache end
	return setCache(0x0a00, isVersionAtMost(state.gameVersion, "2.21") and 85 or 105, true)
end

---Finds the name (including `Vehicle.` prefix) of a vehicle based on its TweakDB ID.
---@param tid TDBID # The TweakDB ID of the vehicle to look up.
---@return string? # The vehicle name if found and valid, otherwise nil.
local function findVehicleName(tid)
	local hash = tid and tid.hash
	if not hash then return nil end

	local cache = getCache(0xaad0) or {}
	if cache[hash] then return cache[hash] end

	local result = TDBID.ToStringDEBUG(tid)
	if not result then
		local vehicles = getPlayerVehicles()
		for _, v in ipairs(vehicles) do
			if v.hash == hash then
				result = TDBID.ToStringDEBUG(v)
				break
			end
		end
	end
	if not result then return nil end

	cache[hash] = result
	setCache(0xaad0, cache)
	return result
end

---Retrieves all appearance entries for a given vehicle name.
---Note: On the first call after starting a new CET session, the returned data may be nil.
---This appears to be caused by delayed (lazy) loading of vehicle appearance data or a CET-related issue.
---It is essential to verify the returned data to ensure all expected appearances have been successfully loaded.
---@param name string # The vehicle name identifier.
---@return VehicleAppearance[]? # A list of appearance entries if available, which may initially be incomplete or empty if the data is not yet fully loaded.
local function getVehicleApperances(name)
	if not isStringValid(name) then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x8d0c, Text.LOG_ARG_INVALID)
		return nil
	end

	local cache = getCache(0x2bce) or {}
	if cache[name] then return cache[name] end

	local key = format("Vehicle.%s.entityTemplatePath", name)
	local path = TweakDB:GetFlat(key)
	local depot = path and Game.GetResourceDepot()
	local loader = depot and depot:LoadResource(path)
	local resource = loader and loader:GetResource()
	if not resource then return nil end

	local result = resource.appearances
	cache[name] = result
	setCache(0x2bce, cache)
	return result
end

---Builds a map of all unique player vehicle and appearance names. Optionally skips vanilla vehicles.
---Note: On the first call in a new CET session, the returned data is often incomplete.
---This behavior appears to be related to delayed (lazy) loading of vehicle appearances or an internal CET quirk.
---It may be necessary to call this function repeatedly across several frames until all expected entries are present.
---@param customOnly boolean # If true, only custom vehicles will be included.
---@return table? # A table where keys are vehicle or appearance identifiers and values are true. Returns nil if no vehicles are found.
---@return number # The total number of collected identifiers. Can be used to detect when all entries have been loaded.
local function getAllUniqueVehicleIdentifiers(customOnly)
	local vehicles = getPlayerVehicles()
	if nilOrEmpty(vehicles) then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x7a6e, Text.LOG_ARG_INVALID)
		return nil, -1
	end

	local start = customOnly and getVanillaVehicleCount() + 1 or 1
	local length = #vehicles
	if start > length then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x7a6e, Text.LOG_ARG_OUT_OF_RANGE)
		return nil, -1
	end

	local result = {}
	local amount = 0
	for i = start, length do
		local name = TDBID.ToStringDEBUG(vehicles[i])
		name = name and name:gsub("^Vehicle%.", "")
		if not name or result[name] then goto continue end

		result[name] = true
		amount = amount + 1

		local apps = getVehicleApperances(name)
		if not apps then goto continue end

		for _, raw in ipairs(apps) do
			local cname = raw and raw.name
			if cname then
				local appName = Game.NameToString(cname)
				if not result[appName] then
					result[appName] = true
					amount = amount + 1
				end
			end
		end

		::continue::
	end
	return result, amount
end

---Checks if the player is currently inside a vehicle.
---@return boolean # True if the player exists and is mounted in a vehicle, otherwise false.
local function isVehicleMounted()
	local player = Game.GetPlayer()
	return player ~= nil and Game.GetMountedVehicle(player) ~= nil
end

---Retrieves the vehicle the player is currently mounted in, if any.
---Internally retrieves the player instance and checks for an active vehicle.
---@return Vehicle? # The currently mounted vehicle instance, or nil if the player is not mounted.
local function getMountedVehicle()
	local cache = getCache(0xecd7)
	if isUserdata(cache) then return cache end

	local player = Game.GetPlayer()
	if not player then --Can happen on creepy old CET.
		logIf(DevLevels.ALERT, LogLevels.WARN, 0xecd7, Text.LOG_PLAYER_UNDEFINED)
		return nil
	end

	return setCache(0xecd7, Game.GetMountedVehicle(player))
end

---Determines the status of a mounted vehicle.
---@return integer # Vehicle status code:
--- - -1: No valid vehicle found (missing TDBID)
--- - 0: Crowd vehicle (vanilla, but not part of the player vehicle list)
--- - 1: Player vanilla vehicle (index <= 105, or <= 85 on game version <= 2.21)
--- - 2: Custom/modded vehicle (index above threshold)
local function getVehicleStatus()
	local cache = getCache(0xddf2)
	if cache then return cache end

	local r = -1
	local veh = getMountedVehicle()
	local tid = veh and veh:GetTDBID()
	if tid then
		local hash = tid.hash

		--0x51e42042: q000_v_nomad_car
		--0x48b1463d: q001_archer_hella
		if hash == 0x51e42042 or hash == 0x48b1463d then
			return setCache(0xddf2, 1)
		end

		local vehicles = getPlayerVehicles()
		for i, v in ipairs(vehicles) do
			if v.hash == tid.hash then
				--Workaround for mods that add vanilla crowd vehicles to the player's list,
				--causing them to be detected as mods — now resolved through an external
				--optional lookup addon that only loads on demand.
				local lookup = addons.crowdLookup
				if lookup == nil then
					local path = "addons/crowd_lookup.lua"
					if fileExists(path) then
						local chunk = deserialize(path, true)
						if chunk then
							local ok, result = pcall(chunk)
							if ok and isTableValid(result) then
								lookup = result
							end
						end
					end
					addons.crowdLookup = lookup or false
				end
				if lookup then ---@cast lookup table<string, boolean>
					local str = findVehicleName(tid)
					if str and lookup[str] then
						r = 0
						break
					end
				end

				--Decide whether it's a vanilla player or a custom player vehicle.
				r = i <= getVanillaVehicleCount() and 1 or 2
				break
			end
		end

		--Everything else is considered a vanilla crowd vehicle.
		r = r > 0 and r or 0
	end

	return setCache(0xddf2, r)
end

---Retrieves the list of third-person camera preset keys for the mounted vehicle.
---Each key is in the form "Camera.VehicleTPP_<CameraID>_<Level>".
---@return string[]? # Array of camera preset keys, or nil if not found.
local function getVehicleCameraKeys()
	local cache = getCache(0xe98c)
	if isTableValid(cache) then return cache end

	local veh = getMountedVehicle()
	local vid = veh and veh:GetRecordID()
	if not vid then
		logIf(DevLevels.ALERT, LogLevels.ERROR, 0xe98c, Text.LOG_VEH_REC_ID_MISS)
		return nil
	end

	local vname = findVehicleName(vid)
	if not vname then
		logIf(DevLevels.ALERT, LogLevels.ERROR, 0xe98c, Text.LOG_VEH_REC_NAME_MISS)
		return nil
	end

	local record = TweakDB:GetFlat(vname .. ".tppCameraPresets")
	if not isTable(record) then return nil end ---@cast record table

	local list = {}
	for _, v in ipairs(record) do
		local name = TDBID.ToStringDEBUG(v)
		if not name then goto continue end

		insert(list, name)

		::continue::
	end

	if isTableValid(list) then
		return setCache(0xe98c, list)
	end

	return nil
end

---Attempts to retrieve the custom camera ID associated with the mounted vehicle.
---@return string? # The extracted custom camera ID (e.g., "lotus_camera") or nil if not found.
local function getCustomVehicleCameraID()
	local cache = getCache(0x4509)
	if isString(cache) then return isStringValid(cache) and cache or nil end

	local keys = getVehicleCameraKeys()
	if not isTable(keys) then return nil end ---@cast keys string[]

	local ids = {}
	local seen = {}
	for _, v in ipairs(keys) do
		--Strip known suffix.
		local id = v:gsub("%.tppCameraPresets%$[%x]+$", "")

		--Iteratively remove known prefixes.
		repeat
			local prev = id
			id = strip(id, ".", 1)
			id = strip(id, "_", 1)
			id = strip(id, "VehicleTPP", 1, true)
			id = strip(id, "Camera", 1, true)
			id = strip(id, "Vehicle", 1, true)
		until id == prev

		--Remove known suffixes.
		for _, s in ipairs(CameraData.Levels) do
			id = strip(id, s, -1, true)
			id = strip(id, ".", -1)
			id = strip(id, "_", -1)
		end

		--Only insert non-empty ID.
		if #id > 0 and not seen[id] then
			insert(ids, id)
			seen[id] = true
		end
	end

	--Filter vanilla defaults.
	for _, p in pairs(presets.collection) do
		if not p.IsDefault or p.IsJoined or not isString(p.ID) then
			goto continue
		end

		for i = #ids, 1, -1 do
			if startsWith(p.ID, ids[i]) then
				remove(ids, i)
				break
			end
		end

		::continue::
	end

	if isTableValid(ids) then
		return setCache(0x4509, tostring(ids[1]))
	end

	--Caches negative results to avoid repeated lookups when nothing is found.
	setCache(0x4509, "")
	return nil
end

---Attempts to retrieve the camera ID associated with the mounted vehicle.
---@return string? # The extracted camera ID (e.g., "4w_911") or nil if not found.
local function getVehicleCameraID()
	local cache = getCache(0xe9aa)
	if isString(cache) then return cache end

	local keys = getVehicleCameraKeys()
	if not isTable(keys) then return nil end ---@cast keys string[]

	--Works in 99.9 percent of cases.
	for _, v in pairs(keys) do
		local match = v:match("^[%a]+%.VehicleTPP_([%w_]+)_[%w_]+_[%w_]+")
		if match then
			return setCache(0xe9aa, match)
		end
	end

	--Rock-solid solution for obfuscated TweakDB key overrides.
	local result = getCustomVehicleCameraID()
	return result and setCache(0xe9aa, result) or nil
end

---Builds a robust and reliable map for vehicle camera TweakDB keys based on their internal data.
---This method is especially useful when keys are obfuscated (e.g., modded content with hashed or unreadable key names).
---@return table<string, string>? # A map from camera preset names (e.g., "High_Close") to raw TweakDB key strings.
local function getVehicleCameraMap()
	local cache = getCache(0xca33)
	if isTableValid(cache) then return cache end

	local keys = getVehicleCameraKeys()
	if not isTable(keys) then return nil end ---@cast keys string[]

	--Rock-solid solution for obfuscated TweakDB key overrides.
	local map = {}
	for _, v in pairs(keys) do
		local height = TweakDB:GetFlat(v .. ".height")
		local heightName = height and Game.NameToString(height)
		local distance = heightName and TweakDB:GetFlat(v .. ".distance")
		local distanceName = distance and Game.NameToString(distance)
		if not distanceName then goto continue end

		--Workaround for mislabeled Low/High YAML tweaks.
		local search = ({ Low = "_high", High = "_low" })[heightName]
		if search and contains(v:lower(), search) then
			heightName = heightName == "Low" and "High" or "Low"
			TweakDB:SetFlat(v .. ".height", heightName)
		end

		map[format("%s_%s", heightName, distanceName)] = v

		::continue::
	end

	return isTableValid(map) and setCache(0xca33, map) or nil
end

---Attempts to retrieve the name of the mounted vehicle.
---@return string? # The resolved vehicle name as a string, or nil if it could not be determined.
local function getVehicleName()
	local cache = getCache(0x3ae2)
	if isString(cache) then return cache end

	local veh = getMountedVehicle()
	local tid = veh and veh:GetTDBID()
	if not tid then return nil end

	local str = findVehicleName(tid)
	return str and setCache(0x3ae2, str:gsub("^Vehicle%.", "")) or nil
end

---Attempts to retrieve the appearance name of the mounted vehicle.
---@return string? # The resolved vehicle name as a string, or nil if it could not be determined.
local function getVehicleAppearanceName()
	local veh = getMountedVehicle()
	local cname = veh and veh:GetCurrentAppearanceName()
	return cname and Game.NameToString(cname) or nil
end

---Retrieves the display name of the currently mounted vehicle.
---@return string? # The display name of the mounted vehicle, or nil if no name available.
local function getVehicleDisplayName()
	local cache = getCache(0x05b4)
	if isStringValid(cache) then return cache end

	local veh = getMountedVehicle()
	local name = veh and veh:GetDisplayName()

	--Fixes incorrectly named custom vehicles.
	if name and startsWith(name, "LocKey#") then
		name = Game.GetLocalizedText(name)
	end

	return name and setCache(0x05b4, name:gsub("„", '"'):gsub("“", '"')) or nil
end

--#endregion

--#region 🧬 Tweak Accessors

---Returns a formatted TweakDB record key for accessing vehicle camera data.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera level path (e.g. "High_Close").
---@param skipCustom boolean? # True, skips checking for a custom key; otherwise, custom keys will be evaluated.
---@return string? # The formatted TweakDB record key (may be a custom key).
---@return string? # The original key, only returned if the formatted key is a custom entry.
local function getCameraTweakBaseKey(preset, path, skipCustom)
	if not isTable(preset) then return nil, nil end

	local id = preset.ID
	if not areString(id, path) or get(CameraDataInvalidLevelMap, false, id, path) then
		return nil, nil
	end

	local cache = getCache(0x074e) or {}
	if cache[id] and cache[id][path] then return cache[id][path][1], get(cache, nil, id, path, 2) end

	if not skipCustom and isString(getCustomVehicleCameraID()) then
		local map = getVehicleCameraMap()
		if isTableValid(map) then ---@cast map table
			local base = map[path]
			if isString(base) then
				deep(cache, id, path)[1] = base

				local custom = getCameraTweakBaseKey(preset, path, true)
				if custom then
					deep(cache, id, path)[2] = custom
				end

				setCache(0x074e, cache)

				return base, custom
			end
		end
	end

	local isBasilisk = id == "v_militech_basilisk_CameraPreset"
	if isBasilisk and (startsWith(path, "Low") or contains(path, "DriverCombat")) then
		return nil, nil
	end

	local section = isBasilisk and "Vehicle" or "Camera"
	local base = format("%s.VehicleTPP_%s_%s", section, id, path)
	deep(cache, id, path)[1] = base
	setCache(0x074e, cache)
	return base, nil
end

---Returns a formatted TweakDB record key for a specific vehicle camera variable.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera level path (e.g. "High_Close").
---@param var string # The name of the variable within the record (e.g. "lookAtOffset" or "defaultRotationPitch").
---@param skipCustom boolean? # True to skip checking for a custom key; otherwise, custom keys will be evaluated.
---@return string? # The formatted TweakDB record key for the specified variable (may be a custom key).
---@return string? # The original key, only returned if the formatted key is a custom entry.
local function getCameraTweakKey(preset, path, var, skipCustom)
	if not isTable(preset) or not isString(var) then return nil, nil end
	local base, custom = getCameraTweakBaseKey(preset, path, skipCustom)
	return base and format("%s.%s", base, var) or nil, custom and format("%s.%s", custom, var) or nil
end

---Updates the TweakDB records associated with a specific vehicle camera path.
---@param preset ICameraPreset # The camera preset to update.
---@param path string # The camera level path (e.g. "High_Close").
local function updateCameraTweakBaseKey(preset, path)
	local base, custum = getCameraTweakBaseKey(preset, path)
	if base then TweakDB:Update(base) end
	if custum then TweakDB:Update(custum) end
end

---Updates a single default parameter in the configuration and optionally in the game.
---@param name string # The name of the option to update.
---@param value (boolean|number)? # The new value to assign.
---@param updateConfig boolean? # If true, the related `config.options` entry is updated as well.
---@param ensureSetFov boolean? # If true, the FOV will be set even while it is locked.
local function updateConfigValue(name, value, updateConfig, ensureSetFov)
	local option = name and config.options[name]
	if not option or option.IsUnavailable then return end

	local default = option.Default
	local isRestore = equals(value, default)
	if not isRestore and value ~= nil then
		if default == nil or type(value) ~= type(default) then return end

		local min, max = option.Min, option.Max
		if areNumber(value, min, max) then ---@cast value number
			value = clamp(value, min, max)
		end
	else
		isRestore = true
		value = default
	end

	if updateConfig then
		config.isUnsaved = config.isUnsaved or value ~= option.Value
		option.Value = value
	end

	if name == "closerBikes" then
		if isTableValid(presets.restoreCollection) then
			for key, preset in pairs(presets.restoreCollection) do
				presets.collection[key] = preset
			end
			presets.restoreCollection = nil
		end

		local isAvailable = value > 1

		local shifts = {}
		for _, key in ipairs(PresetInfo.Offsets) do
			local data = get(config.options, nil, name .. key:upper())
			if data ~= nil then
				shifts[key] = data.Value or data.Default or 0
			end
		end

		if isAvailable then
			presets.restoreCollection = {}
			for key, preset in pairs(presets.collection) do
				local isDef = preset.IsDefault
				local id = preset.ID
				if isDef or not equalsAny(id, "2w_Preset", "Brennan_Preset") then goto continue end

				local origin = get(presets.collection, {}, id)
				if not isTableValid(origin) then goto continue end ---@cast origin ICameraPreset

				presets.restoreCollection[key] = clone(preset)

				preset.Far = merge(origin.Medium, preset.Medium)
				preset.Medium = merge(origin.Close, preset.Close)

				preset.Close = merge(origin.Close, preset.Close)
				preset.Close.a = 12
				preset.Close.d = -0.7

				if value == 3 then
					preset.Far.x = -0.5
					preset.Medium.x = -0.4
					preset.Close.x = -0.3
				elseif value == 4 then
					preset.Far.x = 0.5
					preset.Medium.x = 0.4
					preset.Close.x = 0.3
				end

				for _, level in ipairs(PresetInfo.Levels) do
					for offset, shift in pairs(shifts) do
						if not equals(shift, 0) then
							preset[level][offset] = preset[level][offset] + shift
						end
					end
				end

				::continue::
			end
		end
	end

	if option.IsGameOption then
		setGameOption(option.GameOptionPath, option.GameOptionKey, value)
		return
	end

	if not option.IsGameTweak or not isRestore and not isVehicleMounted() then return end

	for _, section in ipairs(DefaultParams.Keys) do
		local key = format("%s.%s", section, name)
		local current = TweakDB:GetFlat(key)
		if current ~= nil and not equals(current, value) then
			TweakDB:SetFlat(key, value)
			logIf(DevLevels.ALERT, LogLevels.INFO, 0xeef2, isRestore and Text.LOG_PARAM_REST or Text.LOG_PARAM_SET, key, value)
		end
	end

	if not state.isCodewareAvailable then return end

	local isFOV = name == "fov"
	local player = (isFOV or name == "zoom") and Game.GetPlayer()
	local component = player and player:FindComponentByType("vehicleTPPCameraComponent")
	if not component then return end

	if isFOV then
		if state.isFovControlAvailable and ensureSetFov then
			component:PendingSetFOV()
		end
		component:SetFOV(value)
	else
		component:SetZoom(value)
	end
end

---Updates or restores all default parameter in the configuration and applies them to the game if necessary.
---@param doRestore boolean? # If true, all values are reset to their default.
local function updateConfigData(doRestore)
	for var, option in pairs(config.options) do
		if doRestore and option.IsGameOption then goto continue end

		if not option.IsUnavailable and option.Value == nil then
			if option.IsGameOption then
				if areString(option.GameOptionPath, option.GameOptionKey) then
					local default = option.Default
					local current = getGameOption(option.GameOptionPath, option.GameOptionKey, type(default))
					option.Value = coalesce(current, default)
				end
			elseif option.IsGameTweak then
				for _, section in ipairs(DefaultParams.Keys) do
					local key = format("%s.%s", section, var)
					local current = TweakDB:GetFlat(key)
					option.Value = coalesce(current, option.Default)
					break
				end
			else
				option.Value = option.Default
			end
		end

		local value
		if doRestore then
			value = option.Default
		else
			value = option.Value
		end

		updateConfigValue(var, value)

		::continue::
	end
end

---Updates a specific advanced default parameter.
---@param sIdx number # Index referencing the section name within `DefaultParams.Keys`.
---@param name string # Name of the variable to update.
---@param value boolean|number # New value to apply.
---@param updateConfig? boolean # If true, updates the related advanced configuration; defaults to false if omitted.
---@param noDbUpdate? boolean # If true, uses `TweakDB:SetFlatNoUpdate()` instead of `TweakDB:SetFlat()`; defaults to false if omitted.
---@return boolean # Returns true if the parameter value changed, false otherwise.
local function updateAdvancedConfigValue(sIdx, name, value, updateConfig, noDbUpdate)
	if not sIdx or not name or value == nil then return false end

	local section = DefaultParams.Keys[sIdx]
	if not section then return false end

	local origin = get(DefaultParams.Vars, nil, name)
	local default = origin ~= nil and pluck(origin.Default, sIdx)
	if default == nil or type(value) ~= type(default) then return false end

	local result = false

	local key = format("%s.%s", section, name)
	local current = TweakDB:GetFlat(key)
	local isRestore = default ~= nil and equals(default, value)
	if not equals(current, value) then
		result = true

		if isNumber(value) and value % 1 ~= 0 then
			value = tonumber(format("%.3f", value)) or value
		end

		if noDbUpdate then
			TweakDB:SetFlatNoUpdate(key, value)
		else
			TweakDB:SetFlat(key, value)
		end

		logIf(DevLevels.ALERT, LogLevels.INFO, 0x2e3b, isRestore and Text.LOG_PARAM_REST or Text.LOG_PARAM_SET, key, value)
	end

	if not updateConfig then return result end

	config.isAdvancedUnsaved = true
	local option = deep(config.advancedOptions, sIdx)
	option[name] = isRestore and nil or value

	return result
end

---Iterates through all advanced configuration parameters and restores or updates their default values.
---If any parameter changes, its section is committed to the TweakDB.
---@param doRestore boolean? # If true, restores all parameters to their default values instead of keeping current ones.
local function updateAdvancedConfigData(doRestore)
	for i, section in ipairs(DefaultParams.Keys) do
		local commit = false
		for var, data in pairs(DefaultParams.Vars) do
			local default = pluck(data.Default, i)
			local value = get(config.advancedOptions, default, i, var)
			if updateAdvancedConfigValue(i, var, doRestore and default or value, false, true) then
				commit = true
			end
		end
		if commit then
			TweakDB:Update(section)
		end
	end
end

---Resets custom camera behavior values for the mounted vehicle to their global defaults.
---Ensures modded vehicles do not override global TweakDB values such as FOV or camera locking.
---This operation can be undone using `restoreAllCustomCameraData`.
---@param key string # The vehicle's preset key. Used for cache.
local function resetCustomDefaultParams(key)
	if not key then return end

	local cache = getCache(0xf5d6, true) or {}
	if cache[key] then return end

	cache[key] = true
	setCache(0xf5d6, cache, true)

	local veh = getMountedVehicle()
	local vtid = veh and veh:GetTDBID()
	local vname = vtid and TDBID.ToStringDEBUG(vtid)
	local cptid = vname and TweakDB:GetFlat(vname .. ".tppCameraParams")
	local section = cptid and TDBID.ToStringDEBUG(cptid)
	if not section then return end

	local sIdx = contains(section, "_2w_") and 2 or 1
	local commit = false
	for var, data in pairs(DefaultParams.Vars) do
		local entry = format("%s.%s", section, var)
		local current = TweakDB:GetFlat(entry)
		if not current then goto continue end

		local default = data.Default
		local option = get(config.options, nil, var)
		local advanced = get(config.advancedOptions, nil, sIdx, var)

		if option then
			default = coalesce(option.Value, option.Default)
		elseif advanced ~= nil then
			default = advanced
		else
			default = pluck(default, sIdx)
		end

		if equals(current, default) then goto continue end

		if not presets.restoreParams[entry] then
			presets.restoreParams[entry] = current
		end

		commit = true
		TweakDB:SetFlatNoUpdate(entry, default)
		logF(DevLevels.BASIC, LogLevels.INFO, 0x460a, Text.LOG_PARAM_MANIP, entry, current, default)

		::continue::
	end

	if commit then
		TweakDB:Update(section)
	end
end

---Resets custom camera behavior values for the mounted vehicle to their defaults.
---This operation can be undone using `restoreAllCustomCameraData`.
---@param key string # The vehicle's preset key. Used for cache.
local function resetCustomCameraVars(key, preset)
	if not key then return end

	local cache = getCache(0x810b, true) or {}
	if cache[key] then return end

	cache[key] = true
	setCache(0x810b, cache, true)

	for _, path in ipairs(CameraData.Levels) do
		local commit = false
		for _, var in ipairs(CameraData.Vars) do
			local ckey, dkey = getCameraTweakKey(preset, path, var)
			if not ckey or not dkey or presets.restoreParams[ckey] then goto continue end

			local def = TweakDB:GetFlat(dkey)
			local val = def and TweakDB:GetFlat(ckey)
			if not val or equals(val, def) then goto continue end

			commit = true
			presets.restoreParams[ckey] = val
			TweakDB:SetFlatNoUpdate(ckey, def)
			logF(DevLevels.BASIC, LogLevels.INFO, 0x810b, Text.LOG_PARAM_MANIP, ckey, val, def, dkey)

			::continue::
		end
		if commit then
			updateCameraTweakBaseKey(preset, path)
		end
	end
end

---Restores all previously overridden custom camera behavior values.
---Only re-applies values if they differ from the current ones in TweakDB.
---Requires `presets.restoreParams` to contain valid entries; otherwise, nothing happens.
local function restoreAllCustomCameraData()
	if not isTableValid(presets.restoreParams) then return end

	for k, v in pairs(presets.restoreParams) do
		local value = TweakDB:GetFlat(k)
		if not equals(value, v) then
			TweakDB:SetFlat(k, v)
			logF(DevLevels.BASIC, LogLevels.INFO, 0x09ea, Text.LOG_PARAM_REST, k, v)
		end
	end

	presets.restoreParams = {}

	setCache(0xf5d6, nil, true) --Clear `resetCustomDefaultParams` cache.
	setCache(0x810b, nil, true) --Clear `resetCustomCameraVars` cache.
end

---Gets the default rotation pitch value for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@return number # The default rotation pitch for the given camera path.
local function getCameraDefaultRotationPitch(preset, path)
	local key = getCameraTweakKey(preset, path, "defaultRotationPitch")

	local isLow = startsWith(path, "Low_")
	local defaults = {
		["4w_aerondight"]                   = { low = 04, high = 12 },
		["4w_Preset"]                       = { low = 04, high = 15 },
		["4w_SubCompact_Preset"]            = { low = 12, high = 12 },
		v_militech_basilisk_CameraPreset    = { low = 05, high = 05 },
		v_utility4_militech_behemoth_Preset = { low = 05, high = 12 },
		default                             = { low = 04, high = 11 }
	}
	local def = defaults[preset.ID] or defaults.default
	local defVal = isLow and def.low or def.high
	if not key then return defVal end

	local value = tonumber(TweakDB:GetFlat(key))
	if isLow and value ~= nil then
		value = clamp(value - 7, -45, 90)
	end
	return value or defVal
end

---Sets the default rotation pitch for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the default rotation pitch.
local function setCameraDefaultRotationPitch(preset, path, value)
	if not isNumber(value) then return end

	local key, isCustom = getCameraTweakKey(preset, path, "defaultRotationPitch")
	if not key then return end

	local fallback = getCameraDefaultRotationPitch(preset, path)
	if not fallback then return end

	--Adjust low camera.
	if startsWith(path, "Low_") then
		value = clamp(value - 7, -45, 90)
		logIf(DevLevels.FULL, LogLevels.INFO, 0x5c19, Text.LOG_PARAM_IS_LOW, key)
	end

	if equals(value, fallback) then return end

	--Backup default value for shutdown.
	if isCustom and not presets.restoreParams[key] then
		presets.restoreParams[key] = fallback
		logIf(DevLevels.ALERT, LogLevels.INFO, 0x5c19, Text.LOG_PARAM_BACKUP, key, fallback)
	end

	--Finally, set the new value.
	TweakDB:SetFlatNoUpdate(key, value)
	logIf(DevLevels.FULL, LogLevels.INFO, 0x5c19, Text.LOG_PARAM_SET, key, value)
end

---Gets the look-at offset value for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path to retrieve the offset for.
---@return Vector3? # The camera offset as a Vector3.
local function getCameraLookAtOffset(preset, path)
	local key = getCameraTweakKey(preset, path, "lookAtOffset")
	return key and TweakDB:GetFlat(key) or nil
end

---Sets the look-at offset for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path to set the offset for.
---@param x number # The X-coordinate of the camera position.
---@param y number # The Y-coordinate of the camera position.
---@param z number # The Z-coordinate of the camera position.
local function setCameraLookAtOffset(preset, path, x, y, z)
	if not areNumber(x, y, z) then return end

	local key, isCustom = getCameraTweakKey(preset, path, "lookAtOffset")
	if not key then return end

	local fallback = getCameraLookAtOffset(preset, path)
	if not fallback then return end

	--Adjust combat camera.
	if contains(path, "DriverCombat") then
		z = z + 0.5
	end

	local value = Vector3.new(x or fallback.x, y or fallback.y, z or fallback.z)
	if equals(value, fallback) then return end

	--Backup default value for shutdown.
	if isCustom and not presets.restoreParams[key] then
		presets.restoreParams[key] = fallback
		logIf(DevLevels.ALERT, LogLevels.INFO, 0xb786, Text.LOG_PARAM_BACKUP, key, fallback)
	end

	--Finally, set the new value.
	TweakDB:SetFlatNoUpdate(key, value)
	logIf(DevLevels.FULL, LogLevels.INFO, 0xb786, Text.LOG_PARAM_SET, key, value)
end

---Gets the boom length offset value for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@return number # The boom length offset for the given camera path.
local function getCameraBoomLengthOffset(preset, path)
	local key = getCameraTweakKey(preset, path, "boomLengthOffset")
	return key and (tonumber(TweakDB:GetFlat(key)) or 0) or 0
end

---Sets the boom length offset for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the boom length offset.
local function setCameraBoomLengthOffset(preset, path, value)
	if not isNumber(value) then return end

	local key, isCustom = getCameraTweakKey(preset, path, "boomLengthOffset")
	if not key then return end

	--Adjust combat camera.
	if contains(path, "DriverCombat") then
		value = value + 0.5
	end

	local fallback = getCameraBoomLengthOffset(preset, path)
	if not fallback or equals(value, fallback) then return end

	--Backup default value for shutdown.
	if isCustom and not presets.restoreParams[key] then
		presets.restoreParams[key] = fallback
		logIf(DevLevels.ALERT, LogLevels.INFO, 0x25a4, Text.LOG_PARAM_BACKUP, key, fallback)
	end

	--Finally, set the new value.
	TweakDB:SetFlatNoUpdate(key, value)
	logIf(DevLevels.FULL, LogLevels.INFO, 0x25a4, Text.LOG_PARAM_SET, key, value)
end

--#endregion

--#region ⚖️ Preset Management

---Checks whether a preset with the given key exists and matches the specified camera ID.
---Returns true only if the preset is present in `presets.collection ` and its `ID` matches `id`.
---@param key string # The key under which the preset is stored in the `presets.collection ` table.
---@param id string # The camera ID of the mounted vehicle.
---@return boolean # True if the preset exists and has a matching ID, false otherwise.
local function presetExists(key, id)
	local preset = get(presets.collection, nil, key)
	return preset and preset.ID == id
end

---Attempts to find the best matching key in the `presets.collection ` table using one or more candidate values.
---It first checks for exact matches, and then for prefix-based partial matches.
---@param ... string # One or more strings to match against known preset keys (e.g., vehicle name, appearance name).
---@return string? # The matching key from `presets.collection `, or nil if no match was found.
local function findPresetKey(...)
	local id = getVehicleCameraID()
	local seen = { {}, {} }
	local size = select("#", ...)
	local length = 0
	local result
	for pass = 1, #seen do
		for i = 1, size do
			local search = select(i, ...)
			if not search or seen[pass][search] then goto continue end

			seen[pass][search] = true
			for key, preset in pairs(presets.collection) do
				if preset.ID ~= id then goto continue end

				if pass == 1 and search == key then
					return key
				elseif pass == 2 and startsWith(search, key) then
					local len = #key
					if len > length then
						length = len
						result = key
					end
				end

				::continue::
			end

			::continue::
		end
	end
	return result
end

---Validates a new preset key based on the given vehicle and appearance names.
---Ensures the key is non-empty, meets the minimum length, and matches expected name prefixes.
---@param vehicleName string # The base vehicle name used for validation.
---@param appearanceName string # The appearance variant of the vehicle. May be the same as `vehicleName`.
---@param currentKey string # The currently active or fallback preset key. Used as return value on failure.
---@param newKey string? # The newly entered preset key that should be validated.
---@return string # Returns the validated preset key (without `.lua` extension), or `currentKey` if validation fails.
local function validatePresetKey(vehicleName, appearanceName, currentKey, newKey)
	if not areString(vehicleName, appearanceName) then return currentKey end
	if not isString(currentKey) then return vehicleName end
	if not isString(newKey) then return currentKey end ---@cast newKey string

	local name = trimLuaExt(newKey)
	if #name < 1 then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x19fd, Text.LOG_PSET_BLANK_NAME)
		return currentKey
	end

	if startsWith(vehicleName, name) or
		startsWith(appearanceName, name) then
		return name
	end

	if vehicleName ~= appearanceName then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x19fd, Text.LOG_PSET_NAMES_MISM, vehicleName, appearanceName)
	else
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x19fd, Text.LOG_PSET_NAME_MISM, vehicleName)
	end

	return currentKey
end

---Retrieves the current camera offset data for the specified camera ID from TweakDB and returns it as a `ICameraPreset` table.
---@param id string # The camera ID to query.
---@return ICameraPreset? # The retrieved camera offset data, or nil if not found.
local function getPreset(id)
	if not id then return nil end

	local preset = { ID = id } ---@cast preset ICameraPreset
	for i, path in ipairs(CameraData.Levels) do
		local vec3 = getCameraLookAtOffset(preset, path)
		if not vec3 or (not vec3.x and not vec3.y and not vec3.z) then goto continue end

		local level = PresetInfo.Levels[(i - 1) % 3 + 1]
		local angle = getCameraDefaultRotationPitch(preset, path)
		local dist = getCameraBoomLengthOffset(preset, path)

		preset[level] = {
			a = tonumber(angle),
			x = tonumber(vec3.x),
			y = tonumber(vec3.y),
			z = tonumber(vec3.z),
			d = tonumber(dist),
		}

		if preset.Far and preset.Medium and preset.Close then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x198c, Text.LOG_CAM_OSET_DONE, id)
			return preset
		end

		::continue::
	end

	log(LogLevels.ERROR, 0x198c, Text.LOG_CAM_OSET_MISS, id)
	return nil
end

---Retrieves the default preset that matches the given preset's camera ID.
---@param preset ICameraPreset # The preset to search for a default version.
---@return ICameraPreset? # Returns the default preset if found, otherwise nil.
local function getDefaultPreset(preset)
	local id = preset and preset.ID
	if not id then return nil end

	for _, item in pairs(presets.collection) do
		if item.IsDefault and item.ID == id then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0xaced, Text.LOG_PSET_DEF_FOUND, id)
			return item
		end
	end

	log(LogLevels.WARN, 0xaced, Text.LOG_PSET_DEF_MISS, id)

	local fallback = getPreset(id)
	if not fallback then return nil end

	--Ensures unique key to prevent conflicts.
	local key = format("%x_%s", checksum(id), id)

	fallback.IsDefault = true
	fallback.IsJoined = true
	presets.collection[key] = fallback

	log(LogLevels.INFO, 0xaced, Text.LOG_PSET_DEF_JOINED, key)

	return fallback
end

---Returns the Y and Z offset values from a preset or its fallback.
---@param preset ICameraPreset? # The main preset table containing `Close`, `Medium`, or `Far` levels.
---@param fallback ICameraPreset? # The fallback preset table used if values are missing in the main preset.
---@param level "Close"|"Medium"|"Far" # The level to fetch ("Close", "Medium", or "Far").
---@return number a # The angle value. Falls back to 11 if not found.
---@return number x # The X offset value. Falls back to 0 if not found.
---@return number y # The Y offset value. Falls back to 0 if not found.
---@return number z # The Z offset value. Falls back to a default per level (Close = 1.115, Medium = 1.65, Far = 2.25).
---@return number d # The distance value. Falls back to a default per level (Close = 0, Medium = 1.5, Far = 4).
local function getOffsetData(preset, fallback, level)
	if not isTable(preset) or not contains(PresetInfo.Levels, level) then
		logF(DevLevels.FULL, LogLevels.ERROR, 0x21d6, Text.LOG_PSET_LVL_MISS, level)
		return 0, 0, 0, 0, 0 --Should never be returned with the current code.
	end ---@cast preset ICameraPreset

	local p = preset[level]
	local f = (fallback and fallback[level]) or {}

	local a = tonumber(p and p.a or f.a) or 11
	local x = tonumber(p and p.x or f.x) or 0
	local y = tonumber(p and p.y or f.y) or 0
	local z = tonumber(p and p.z or f.z) or ({ Close = 1.115, Medium = 1.65, Far = 2.25 })[level]
	local d = tonumber(p and p.d or f.d) or ({ Close = 0, Medium = 1.5, Far = 4 })[level]
	return a, x, y, z, d
end

---Applies a camera offset preset to the vehicle by updating values in TweakDB.
---If no `preset` is provided, the preset is looked up automatically based on the mounted vehicle.
---Missing values in the preset are replaced with fallback values from the default preset, if available.
---Each successfully applied preset ID is recorded in `presets.restoreStack`.
---@param preset ICameraPreset? # The preset to apply. May be nil to auto-resolve via the current vehicle.
---@param id string? # The camera ID of the mounted vehicle.
local function applyPreset(preset, id)
	if not preset then
		local vNam = getVehicleName()
		local aNam = vNam and getVehicleAppearanceName()
		local key = aNam and findPresetKey(vNam, aNam)
		local cid = key and getVehicleCameraID()
		if not (key and cid) then return end

		log(LogLevels.INFO, 0x9583, Text.LOG_CAM_PSET, key)

		local pset = presets.collection[key]
		if not isTableValid(pset) then return end

		if pset.IsVanilla and get(config.options, false, "noVanilla", "Value") then
			return
		end

		resetCustomDefaultParams(key)
		resetCustomCameraVars(key, pset)
		applyPreset(pset, cid)

		--Tracks usage statistics.
		local usage = presets.usage[key] or {}
		usage.Total = (usage.Total or 0) + 1
		usage.Last = os.time()
		usage.First = usage.First or usage.Last
		presets.usage[key] = usage
		presets.isUsageUnsaved = true
		return
	end

	if not isStringValid(preset.ID) then
		logF(DevLevels.BASIC, LogLevels.ERROR, 0x9583, Text.LOG_PSET_APPLY_FAIL)
		return
	end

	if isString(id) and id ~= preset.ID then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x9583, Text.LOG_CAM_ID_MISM, preset.ID, id)
		return
	end

	local isDefault = preset.IsDefault
	local fallback = isDefault and preset or getDefaultPreset(preset) or {}
	for i, path in ipairs(CameraData.Levels) do
		local level = PresetInfo.Levels[(i - 1) % 3 + 1]
		local a, x, y, z, d = getOffsetData(preset, fallback, level)
		setCameraDefaultRotationPitch(preset, path, a)
		setCameraLookAtOffset(preset, path, x, y, z)
		setCameraBoomLengthOffset(preset, path, d)
		updateCameraTweakBaseKey(preset, path)
	end
	if not isDefault then
		presets.isAnyActive = true
	end

	insert(presets.restoreStack, preset.ID)
end

---Restores all camera offset presets to their default values.
local function restoreAllPresets()
	for _, preset in pairs(presets.collection) do
		if preset.IsDefault then
			applyPreset(preset)
		end
	end
	presets.restoreStack = {}

	log(LogLevels.INFO, 0x8438, Text.LOG_PSETS_REST_DEF)
end

---Restores modified camera offset presets to their default values.
local function restoreModifiedPresets()
	local changed = presets.restoreStack
	if not isTableValid(changed) then return end

	local amount = #changed
	local restored = 0
	for _, preset in pairs(presets.collection) do
		if preset.IsDefault and contains(changed, preset.ID) then
			applyPreset(preset)
			restored = restored + 1
			log(LogLevels.INFO, 0xe126, Text.LOG_PSET_REST, preset.ID)
		end
		if restored >= amount then break end
	end
	presets.restoreStack = {}

	log(LogLevels.INFO, 0xe126, Text.LOG_PSETS_REST, restored, amount)
end

---Validates whether the given camera offset preset is structurally valid.
---A preset is valid if it has a string ID and at least one of Close, Medium,
---or Far contains a numeric `y` or `z` value.
---@param preset ICameraPreset # The preset to validate.
---@return boolean # True if the preset is valid, false otherwise.
local function isPresetValid(preset)
	if not isTable(preset) or not isStringValid(preset.ID) then return false end

	for _, e in ipairs(PresetInfo.Levels) do
		local offset = preset[e]
		if not isTable(offset) then
			goto continue
		end
		for _, k in ipairs(PresetInfo.Offsets) do
			if isNumber(offset[k]) then
				return true
			end
		end
		::continue::
	end

	return false
end

---Adds, updates, or removes a preset entry in the `presets.collection ` table.
---@param key string # The key under which the preset is stored (usually the preset name without ".lua").
---@param preset ICameraPreset? # The preset to store. If nil, the existing entry will be removed.
---@return boolean # True if the operation was successful (added, updated or removed), false if the key is invalid or the preset is not valid.
local function setPresetEntry(key, preset)
	if not isString(key) then return false end

	if preset == nil then
		if presets.collection[key] ~= nil then
			presets.isUsageUnsaved = true
			presets.collection[key] = nil
		end
		return true
	end

	if not isPresetValid(preset) then return false end

	presets.collection[key] = preset
	return true
end

--#endregion

--#region 💾 Preset File Control

---Builds the absolute path to a preset file based on its name and vehicle status.
---@param name string # The base name of the preset file (with or without `.lua` extension).
---@param status integer # Vehicle status code. Matches getVehicleStatus(), with one exception:
--- - -1 = defaults (special case, not equal by getVehicleStatus)
--- -  0 = crowd vanilla vehicle
--- -  1 = player vanilla vehicle
--- -  2 = custom/modded vehicle
--- - any other value is treated as custom
---@return string # The full path to the preset file, or an empty string if name is invalid.
local function getPresetFilePath(name, status)
	if not isString(name) then return "" end

	local path
	if status == -1 then
		path = PresetFolders.DEFAULTS
	elseif status == 0 or status == 1 then
		path = PresetFolders.VANILLA
	elseif get(presets.collection, {}, name).IsLegacy then
		path = PresetFolders.CUSTOM_LEGACY
	else
		path = PresetFolders.CUSTOM
	end
	return combine(path, ensureLuaExt(name))
end

---Checks whether a preset file with the given name exists in the appropriate folder.
---Automatically adds the ".lua" extension if missing.
---@param name string # The name of the preset file (with or without ".lua" extension).
---@param isDefault boolean? # If true, checks the "defaults" directory instead of "presets".
---@return boolean # True if the file exists, false otherwise.
local function presetFileExists(name, isDefault)
	if not isStringValid(name) then return false end

	if isDefault then
		local path = getPresetFilePath(name, -1)
		return fileExists(path)
	end

	name = ensureLuaExt(name)
	for key, value in pairs(PresetFolders) do
		if key ~= "DEFAULTS" then
			local path = combine(value, name)
			if fileExists(path) then
				return true
			end
		end
	end

	return false
end

---Saves a camera preset to file, either as a regular preset or as a default.
---It serializes only values that differ from the default (unless saving as default).
---@param name string # The name of the preset file (with or without `.lua` extension).
---@param preset table # The preset data to save (must include an `ID` and valid offset data).
---@param allowOverwrite boolean? # Whether existing files may be overwritten.
---@param forceDefault boolean? # If true, saves the preset to the `defaults` directory instead of `presets`.
---@return boolean # True on success, or false if writing failed or nothing needed to be saved.
local function savePreset(name, preset, allowOverwrite, forceDefault)
	if not isStringValid(name) or not isTableValid(preset) then return false end

	local status = getVehicleStatus()
	local isVanilla = status == 0 or status == 1
	local isLegacy = get(presets.collection, {}, name).IsLegacy
	local path = combine(
		forceDefault and PresetFolders.DEFAULTS or
		isVanilla and PresetFolders.VANILLA or
		isLegacy and PresetFolders.CUSTOM_LEGACY or
		PresetFolders.CUSTOM, ensureLuaExt(name))
	if not isStringValid(path) then return false end

	--To always save all values, as the currently retrieved defaults may change in future.
	local isCustom = preset.ID == getCustomVehicleCameraID()

	if not allowOverwrite and not isCustom then
		local check = io.open(path, "r")
		if check then
			check:close()
			log(LogLevels.WARN, 0x8515, Text.LOG_PSET_FILE_EXIST, path)
			return false
		end
	end

	local default = getDefaultPreset(preset) or {}
	local save = false
	local parts = { "return{" }
	insert(parts, format("ID=%q,", preset.ID))
	for _, mode in ipairs(PresetInfo.Levels) do
		local curLevel = preset[mode]
		local defLevel = default[mode] or {}
		local offsetParts = {}

		if isTableValid(curLevel) then
			for _, offset in ipairs(PresetInfo.Offsets) do
				local curVal = curLevel[offset]
				local defVal = defLevel[offset]
				if isCustom or forceDefault or not equals(curVal, defVal) then
					save = true
					insert(offsetParts, format("%s=%s", offset, serialize(curVal)))
				end
			end
		end

		if isTableValid(offsetParts) then
			insert(parts, format("%s={%s},", mode, concat(offsetParts, ",")))
		end
	end

	if not save then
		log(LogLevels.WARN, 0x8515, Text.LOG_PSET_NOT_CHANGED, path, default.ID)

		if not forceDefault then
			local ok, err = os.remove(path)
			if ok then
				logF(DevLevels.ALERT, LogLevels.WARN, 0x8515, Text.LOG_PSET_DELETED, path)
			else
				logF(DevLevels.FULL, LogLevels.ERROR, 0x8515, Text.LOG_PSET_DEL_FAIL, path, err)
			end
			return ok and setPresetEntry(name)
		end

		return false
	end

	if forceDefault then
		insert(parts, "IsDefault=true")
	elseif isVanilla then
		insert(parts, "IsVanilla=true")
	elseif isLegacy then
		insert(parts, "IsLegacy=true")
	end

	local last = parts[#parts]
	if last and last:sub(-1) == "," then
		parts[#parts] = last:sub(1, -2)
	end

	insert(parts, "}")

	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(concat(parts))
	file:close()

	logF(DevLevels.ALERT, LogLevels.INFO, 0x8515, Text.LOG_PSET_SAVED, path)

	return true
end

---Removes camera presets from the global `presets.collection ` table.
---If no key is provided, clears all presets
---If a key is provided, removes only entries whose keys start with the given prefix.
---@param key string? # Optional key prefix used to filter which presets to remove.
local function purgePresets(key)
	if not isString(key) then
		presets.collection = {}
		log(LogLevels.WARN, 0x176b, Text.LOG_CAMS_ALL_CLEARED)
		return
	end ---@cast key string

	local c = 0
	for k in pairs(presets.collection) do
		if startsWith(k, key) then
			presets.collection[k] = nil
			c = c + 1
		end
	end

	log(LogLevels.WARN, 0x176b, Text.LOG_CAMS_CLEARED, c, key)
end

---Loads a single camera preset file, validates it, and registers it if applicable.
---Checks if the preset is relevant for custom/modded vehicles.
---@param file string # The preset filename (with `.lua` extension).
---@param folder string # Directory where the preset file is located.
---@param count integer # Current number of successfully loaded presets.
---@param vehicleNames table<string, boolean>? # Optional map of vehicle names and their apperance names to validate the preset against.
---@return integer # Updated count of successfully loaded presets.
local function loadPresetFile(file, folder, count, vehicleNames)
	if not state.isModEnabled or not file or not hasLuaExt(file) then return count end

	local key = trimLuaExt(file)
	if presets.collection[key] then
		count = count + 1
		logF(DevLevels.BASIC, LogLevels.WARN, 0x0305, Text.LOG_PSET_SKIPPED, key, folder, file)
		return count
	end

	--Ensures that presets are only loaded for vehicles that are actually installed.
	if vehicleNames then ---@cast vehicleNames table<string, boolean>
		local isValid = vehicleNames[key] ~= nil

		if not isValid then
			for name in pairs(vehicleNames) do
				if startsWith(name, key) then
					isValid = true
					break
				end
				if isValid then break end
			end
		end

		if not isValid then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x0305, Text.LOG_PSET_IGNORED, key, folder, file)
			return count
		end

		--Add support for legacy preset versions.
		--Additional versions may be added in the future.
		if key == "yv_350z" and vehicleNames["yv_350z_black"] then
			local legacyFile = combine("legacy", file)
			if presetFileExists(legacyFile) then
				file = legacyFile
				logF(DevLevels.BASIC, LogLevels.INFO, 0x0305, Text.LOG_PSET_LOAD_VER, key, folder, file)
			end
		end
	end

	local path = combine(folder, file)
	local chunk, err = deserialize(path, true)
	if not chunk then
		logF(DevLevels.BASIC, LogLevels.ERROR, 0x0305, Text.LOG_PSET_LOAD_FAIL, folder, file, err)
		return count
	end

	local ok, result = pcall(chunk)
	if not ok or not result then
		logF(DevLevels.BASIC, LogLevels.WARN, 0x0305, Text.LOG_PSET_EXE_FAIL, folder, file)

		local success, error = pcall(os.remove, path)
		if success then
			logF(DevLevels.BASIC, LogLevels.INFO, 0x0305, Text.LOG_PSET_DELETED, path)
		else
			logF(DevLevels.BASIC, LogLevels.WARN, 0x0305, Text.LOG_PSET_DEL_FAIL, path, error)
		end

		return count
	end

	if not setPresetEntry(key, result) then
		logF(DevLevels.BASIC, LogLevels.ERROR, 0x0305, Text.LOG_PSET_INVALID, folder, file)
		return count
	end

	count = count + 1
	logIf(DevLevels.FULL, LogLevels.INFO, 0x0305, Text.LOG_PSET_LOAD, key, folder, file)
	return count
end

---Loads all valid preset files from the specified folder.
---Automatically handles all different location folders differently.
---For custom folders, files are loaded asynchronously in small batches to avoid blocking,
---due to the verification process that checks if each preset matches an installed vehicle.
---@param path string # One of the paths from `PresetFolders` (DEFAULTS, VANILLA, CUSTOM) indicating which folder to load presets from.
local function loadPresetsFrom(path)
	if not state.isModEnabled then return end

	local isVan = path == PresetFolders.VANILLA
	local noVan = get(config.options, false, "noVanilla", "Value")
	if isVan and noVan then return end

	local isDef = path == PresetFolders.DEFAULTS
	local files = dir(path)
	if files then
		local task = presets.loaderTask
		local count = 0

		if isDef or isVan then
			task.StartTime = os.clock()
			for _, v in ipairs(files) do
				count = loadPresetFile(v.name, path, count)
			end
			task.EndTime = os.clock()

			local duration = task.EndTime - task.StartTime
			task.Duration = (task.Duration or 0) + duration

			if isDef and count < 39 then
				state.isModEnabled = false
				logF(DevLevels.FULL, LogLevels.ERROR, 0x98e0, Text.LOG_PSETS_DEF_BROKEN)
			end

			local text = isDef and Text.LOG_PSETS_LOAD_DEF or Text.LOG_PSETS_LOAD_VAN
			logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, text, count, #files - 1, duration)
			return
		end

		local length = #files - 1
		if length == 0 then
			task.IsActive = false
			logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_CUS, 0, 0, 0)
			logF(DevLevels.ALERT, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_DONE, task.Duration)
			if isFunction(task.Finalizer) then
				task.Finalizer()
			end
			return
		end

		task.StartTime = os.clock()
		task.EndTime = task.StartTime
		task.Duration = task.Duration or 0

		local isBusy = false
		local iterations = ceil(length / 5)
		local index, file, names
		local isMappingSuccess, isMappingDone = false, false

		asyncRepeat(0.1, function(id)
			if isBusy or not isMappingDone then return end
			if not isMappingSuccess then
				asyncStop(id)
				task.IsActive = false
				count = 0
				return
			end
			isBusy = true
			for _ = 1, iterations do
				index, file = next(files, index)
				if not file then
					asyncStop(id)
					task.EndTime = os.clock()
					task.IsActive = false
					return
				end
				count = loadPresetFile(file.name, path, count, names)
			end
			isBusy = false
		end)

		asyncRepeat(1, function(id)
			if task.IsActive then return end
			asyncStop(id)

			local duration = task.EndTime - task.StartTime
			task.Duration = task.Duration + duration

			logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_CUS, count, length, duration)

			local ignored = length - count
			if ignored > 0 then
				logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_IGNO, ignored)
			end

			logF(DevLevels.ALERT, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_DONE, task.Duration)

			task.Duration = 0

			if isFunction(task.Finalizer) then
				task.Finalizer()
			end
		end)

		--Workaround to query all custom vehicle appearances. I'm not sure
		--if this is a CET bug or intended behavior, but it doesn't seem to
		--matter when I call it. On the very first time, only about half of
		--the appearances that should be available are returned. The query
		--must be forced at least one frame before the actual action. The
		--result is discarded, only to ensure that the next queries returns
		--all appearances.
		local interval, amount = 0, 0
		asyncRepeatBurst(interval, function(id)
			local map, quantity = getAllUniqueVehicleIdentifiers(true)
			log(LogLevels.INFO, 0x98e0, Text.LOG_VEH_UIDS, quantity)
			if quantity == amount or interval >= 1 then
				asyncStop(id)
				names = map
				isMappingSuccess = quantity > 0
				isMappingDone = true
				return
			end
			amount = quantity
			interval = interval + .1
		end)

		return
	end

	state.isModEnabled = false
	logF(DevLevels.FULL, LogLevels.ERROR, 0x98e0, Text.LOG_PSETS_DIR_MISS, path)
end

---Loads all camera presets from the defaults, vanilla, and custom folders.
---@param refresh boolean? # Whether to clear existing presets before loading.
---@param delay number? # Optional delay before execution.
local function loadPresets(refresh, delay)
	if refresh then purgePresets() end

	presets.loaderTask.IsActive = true
	delay = abs(isNumber(delay) and delay or 0)
	asyncOnce(delay, function()
		loadPresetsFrom(PresetFolders.DEFAULTS)
		loadPresetsFrom(PresetFolders.VANILLA)
		loadPresetsFrom(PresetFolders.CUSTOM)
	end)
end

---Saves the `presets.usage` table to `db.sqlite3` on disk.
local function savePresetUsage()
	if not presets.isUsageUnsaved then return end
	presets.isUsageUnsaved = false

	if not isTableValid(presets.usage) then return end

	sqliteInit(
		"PresetUsage",
		"Name TEXT PRIMARY KEY",
		"First INTEGER",
		"Last INTEGER",
		"Total INTEGER"
	)

	--Load current DB values.
	local database = {}
	for row in sqliteRows("PresetUsage", "Name, First, Last, Total") do
		local key, first, last, total = unpack(row)
		database[key] = {
			First = first,
			Last = last,
			Total = total
		}
	end

	sqliteBegin()

	--Bulk delete outdated entries.
	local doVacuum = false
	for name in pairs(database) do
		if not presets.collection[name] then
			doVacuum = true
			presets.usage[name] = nil
			sqliteDelete("PresetUsage", "Name", name)
		end
	end

	--Update only changed entries.
	for name, current in pairs(presets.usage) do
		local previous = database[name]
		if not equals(current, previous) then
			sqliteUpsert("PresetUsage", "Name", {
				Name = name,
				First = current.First,
				Last = current.Last,
				Total = current.Total
			})
		end
	end

	sqliteCommit()

	if doVacuum then
		sqliteVacuum()
	end
end

---Loads `presets.usage` table from `db.sqlite3`.
local function loadPresetUsage()
	sqliteInit(
		"PresetUsage",
		"Name TEXT PRIMARY KEY",
		"First INTEGER",
		"Last INTEGER",
		"Total INTEGER"
	)

	--Load DB values.
	presets.usage = {}
	for row in sqliteRows("PresetUsage", "Name, First, Last, Total") do
		local key, first, last, total = unpack(row)
		presets.usage[key] = {
			First = first,
			Last = last,
			Total = total
		}
	end
end

---Saves the `config.options` values to `db.sqlite3` on disk.
local function saveGlobalOptions()
	if not config.isUnsaved then return end
	config.isUnsaved = false

	if not isTable(config.options) then return end

	restoreAllCustomCameraData()

	sqliteInit(
		"GlobalOptions",
		"Name TEXT PRIMARY KEY",
		"Value TEXT"
	)

	--Load current DB values.
	local database = {}
	for row in sqliteRows("GlobalOptions", "Name, Value") do
		local key, rawVal = unpack(row)
		database[key] = rawVal
	end

	sqliteBegin()

	local doVacuum = false

	--Update only changed entries.
	for name, option in pairs(config.options) do
		local default = serialize(option.Default)
		local current = serialize(coalesce(option.Value, option.Default))
		local previous = database[name]
		if not equals(current, previous) then
			if equals(current, default) then
				doVacuum = true
				sqliteDelete("GlobalOptions", "Name", name)
			else
				sqliteUpsert("GlobalOptions", "Name", {
					Name = name,
					Value = current
				})
			end
		end
	end

	sqliteCommit()

	if doVacuum then
		sqliteVacuum()
	end
end

---Loads `config.options` values from `db.sqlite3`.
local function loadGlobalOptions()
	sqliteInit(
		"GlobalOptions",
		"Name TEXT PRIMARY KEY",
		"Value TEXT"
	)

	--Load DB values.
	local options = config.options
	for row in sqliteRows("GlobalOptions", "Name, Value") do
		local key, raw = unpack(row)
		local chunk = deserialize(raw)
		if not chunk then goto continue end

		local ok, result = pcall(chunk)
		if not ok then goto continue end

		local option = options[key]
		if type(result) == type(option.Default) then
			option.Value = result
		end

		::continue::
	end
end

---Saves the `config.advancedOptions` values to `db.sqlite3` on disk.
local function saveAdvancedOptions()
	if not config.isAdvancedUnsaved then return end
	config.isAdvancedUnsaved = false

	if not isTable(config.advancedOptions) then return end

	restoreAllCustomCameraData()

	sqliteBegin()

	local doVacuum = false

	for i, options in pairs(config.advancedOptions) do
		local tableName = "AdvancedOptions" .. i

		sqliteInit(
			tableName,
			"Name TEXT PRIMARY KEY",
			"Value TEXT"
		)

		local database = {}
		for row in sqliteRows(tableName, "Name, Value") do
			local key, rawVal = unpack(row)
			database[key] = rawVal
		end

		for name, value in pairs(options) do
			local current = serialize(value)

			local default = DefaultParams.Vars[name].Default
			default = serialize(pluck(default, i))
			if equals(current, default) then
				doVacuum = true
				sqliteDelete(tableName, "Name", name)
				goto continue
			end

			local previous = database[name]
			if not equals(current, previous) then
				sqliteUpsert(tableName, "Name", {
					Name = name,
					Value = current
				})
			end

			::continue::
		end
	end

	sqliteCommit()

	if doVacuum then
		sqliteVacuum()
	end
end

---Loads `config.advancedOptions` values from `db.sqlite3`.
local function loadAdvancedOptions()
	for i, _ in ipairs(DefaultParams.Keys) do
		local tableName = "AdvancedOptions" .. i

		sqliteInit(
			tableName,
			"Name TEXT PRIMARY KEY",
			"Value TEXT"
		)

		for row in sqliteRows(tableName, "Name, Value") do
			local key, raw = unpack(row)
			local chunk = deserialize(raw)
			if not chunk then goto continue end

			local ok, result = pcall(chunk)
			if ok and isBoolean(result) or isNumber(result) then
				deep(config.advancedOptions, i)[key] = result
			end

			::continue::
		end
	end
end

--#endregion

--#region 🧪 Preset Editor

---Generates a checksum token for a camera preset by combining its ID and offset tables.
---@param preset ICameraPreset # The camera preset containing fields `ID`, `Close`, `Medium`, and `Far`.
---@return integer # Adler-53 checksum of `preset.ID`, `preset.Close`, `preset.Medium`, `preset.Far`, or -1 if invalid.
local function getEditorPresetToken(preset)
	if not isTable(preset) then return -1 end
	return checksum(preset.ID, preset.Close, preset.Medium, preset.Far)
end

---Creates a new editor preset entry from a camera preset.
---@param preset ICameraPreset # The source camera preset.
---@param key string # Identifier/name for this preset entry.
---@param snapshot boolean? # If true, deep-copies `preset` and clears its `IsDefault` flag.
---@param verify boolean? # If true, sets `IsPresent` by checking the file system.
---@return IEditorPreset # A table with fields: Preset, Key, Name, Token, IsPresent.
local function getEditorPreset(preset, key, snapshot, verify)
	local object = preset
	if snapshot then
		object = clone(object)
	end
	return {
		Preset = object,
		Key = key,
		Name = key,
		Token = getEditorPresetToken(object),
		IsPresent = verify and presetFileExists(key) or false
	}
end

---Retrieves (and if necessary initializes) the four editor‐preset entries for a given arguments.
---If the entries already exist in `editor.bundles`, it simply returns them.
---@param name string # Vehicle name (e.g. "v_sport2_porsche_911turbo_player").
---@param appName string # Appearance name (e.g. "porsche_911turbo__basic_johnny").
---@param id string # Camera-preset ID for TweakDB lookup.
---@param key string # Preset key/alias used for storage and display.
---@return IEditorBundle? # Returns the editor bundle containing Flux, Pivot, Finale, Nexus, and Tasks entries, or nil if initialization failed.
local function getEditorBundle(name, appName, id, key)
	local bundle = deep(editor.bundles, format("%s*%s", name, appName)) ---@cast bundle IEditorBundle

	if not areTable(bundle.Flux, bundle.Pivot, bundle.Finale, bundle.Nexus, bundle.Tasks) then
		local flux = getPreset(id)
		if not flux then
			log(LogLevels.WARN, 0xf0b7, Text.LOG_PSET_NOT_FOUND, id)
			return
		end

		bundle.Flux = getEditorPreset(flux, key, true)
		bundle.Pivot = getEditorPreset(flux, key, true)
		bundle.Finale = getEditorPreset(flux, key, true, true)

		local nexus = getDefaultPreset(flux) ---@cast nexus ICameraPreset
		bundle.Nexus = getEditorPreset(nexus, key, true, true)

		bundle.Tasks = {
			Rename = false,
			Validate = false,
			Apply = false,
			Save = false,
			Restore = false
		}
	end

	return bundle
end

---Clears the last editor bundle if no pending tasks are active.
local function clearLastEditorBundle()
	local bundle = editor.lastBundle
	if not isTable(bundle) then return end

	if bundle.Tasks.Apply or
		bundle.Tasks.Save or
		bundle.Tasks.Restore then
		return
	end

	local flux = get(bundle, {}, "Flux")
	local key = flux.Key
	local hash = flux.Token
	if key and hash and not presetFileExists(key) and hash == get(bundle, {}, "Nexus").Token then
		presets.collection[key] = nil

		log(LogLevels.INFO, 0xbc48, Text.LOG_PSET_DELETED, key)
	end

	bundle.Flux = nil
	bundle.Pivot = nil
	bundle.Finale = nil
	bundle.Nexus = nil

	editor.lastBundle = nil

	log(LogLevels.INFO, 0xbc48, Text.LOG_PSET_EDIT_DELETED)
end

---Replaces an existing editor preset entry with values from another and updating its checksum.
---@param src IEditorPreset # The source preset entry whose data will be copied.
---@param dest IEditorPreset # The preset entry to overwrite (modified in place).
---@param verify boolean? # If true, recomputes `IsPresent` by checking the file system for `src.Key`.
local function replaceEditorPreset(src, dest, verify)
	if not areTable(src, dest) then return end

	local preset = clone(src.Preset)
	dest.Preset = preset
	dest.Key = src.Key
	dest.Name = src.Name
	dest.Token = getEditorPresetToken(preset)
	dest.IsPresent = verify and presetFileExists(src.Key) or false

	local cache = getCache(0xcb3d) --Get `onDraw` cache.
	if cache then
		cache.key = nil
	end
end

---Applies the current UI-edited camera preset to the internal preset registry.
---Updates the pivot state, clears the old entry, and assigns any preserved overrides.
---@param key string # The key under which the current preset will be stored.
---@param flux IEditorPreset # The edited preset containing user modifications.
---@param pivot IEditorPreset # The previously applied preset; will be overwritten with `flux`.
---@param tasks IEditorTasks # Tracks pending editor actions; `Apply` will be cleared here.
local function applyEditorPreset(key, flux, pivot, tasks)
	if not isString(key) or not areTable(flux, pivot, tasks) then return end

	tasks.Apply = false

	local isVanilla = false
	local isLegacy = false
	if presets.collection[pivot.Key] then
		isVanilla = presets.collection[pivot.Key].IsVanilla
		isLegacy = presets.collection[pivot.Key].IsLegacy
	end

	presets.collection[pivot.Key] = nil
	if not tasks.Restore then
		if isVanilla then
			flux.Preset.IsVanilla = true
		end
		if isLegacy then
			flux.Preset.IsLegacy = true
		end
		presets.collection[key] = flux.Preset
	end

	replaceEditorPreset(flux, pivot)

	logF(DevLevels.ALERT, LogLevels.INFO, 0x1e64, Text.LOG_PSET_UPDATED, key)
end

---Saves the current camera preset to disk and updates the saved (finale) state.
---Performs overwrite, cleanup of old files on rename, and syncs the checksum.
---@param key string # The key used as filename for saving the preset (without `.lua` extension).
---@param flux IEditorPreset # The currently edited preset with unsaved modifications.
---@param finale IEditorPreset # The last saved version of the preset; will be updated to match `flux`.
---@param tasks IEditorTasks # Tracks pending editor actions; will reset `Save`, `Restore`, and optionally `Rename`.
---@param status integer # Vehicle status used to determine the folder path:
--- - 0 = crowd vanilla vehicle
--- - 1 = player vanilla vehicle
--- - 2 = custom/modded vehicle
local function saveEditorPreset(key, flux, finale, tasks, status)
	if not isString(key) or not areTable(flux, finale, tasks) or not isNumber(status) or status == -1 then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0xebb8, Text.LOG_ARG_INVALID)
		return
	end

	if not savePreset(key, flux.Preset, true) then
		logF(DevLevels.ALERT, LogLevels.WARN, 0xebb8, Text.LOG_PSET_NOT_SAVED, key)
		return
	end

	tasks.Restore = false
	tasks.Save = false

	if tasks.Rename then
		tasks.Rename = false
		local path = getPresetFilePath(finale.Name, status)
		if fileExists(path) then
			local ok, err = isStringValid(path) and os.remove(path) or false, nil
			if not ok then
				logF(DevLevels.FULL, LogLevels.ERROR, 0xebb8, Text.LOG_PSET_DEL_FAIL, finale.Name, flux.Name, err)
			end
		end

		presets.collection[finale.Key] = nil
	end

	replaceEditorPreset(flux, finale, true)
end

--#endregion

--#region 🎨 UI Layout Helpers

---Ensures an ImGui window stays fully within the screen boundaries and optionally repositions it.
---If any of the `x`, `y`, `width`, `height`, `maxWidth`, or `maxHeight` parameters are not provided,
---the function automatically queries the current window position/size and display resolution.
---@param x number? # Optional X position of the window.
---@param y number? # Optional Y position of the window.
---@param width number? # Optional width of the window.
---@param height number? # Optional height of the window.
---@param maxWidth number? # Optional maximum screen width; defaults to display width.
---@param maxHeight number? # Optional maximum screen height; defaults to display height.
---@return boolean isValidated # True if the window position was adjusted to fit within bounds.
---@return number newX # The validated X position.
---@return number newY # The validated Y position.
---@return number width # The width of the window.
---@return number height # The height of the window.
---@return number maxWidth # The maximum screen width.
---@return number maxHeight # The maximum screen height.
local function validateWindowBounds(x, y, width, height, maxWidth, maxHeight)
	if not areNumber(x, y) then
		x, y = ImGui.GetWindowPos()
		---@cast x number
		---@cast y number
	end
	if not areNumber(width, height) then
		width, height = ImGui.GetWindowSize()
		---@cast width number
		---@cast height number
	end
	if not areNumber(maxWidth, maxHeight) then
		maxWidth, maxHeight = GetDisplayResolution()
		---@cast maxWidth number
		---@cast maxHeight number
	end
	local newX = clamp(x, 0, maxWidth - width)
	local newY = clamp(y, 0, maxHeight - height)
	local isValidated = false
	if newX ~= x or newY ~= y then
		isValidated = true
		ImGui.SetWindowPos(newX, newY)
	end
	return isValidated, newX, newY, width, height, maxWidth, maxHeight
end

---Aligns the next ImGui item horizontally, vertically, or both.
---If `x` is a number, only vertical alignment is applied using it as cell height.
---If `x` is a string, both horizontal (right-aligned) and vertical centering are enabled by default.
---@param x string|number # Text to align (string) or cell height to vertically center (number).
---@param hAlign boolean? # If true, right-aligns the next item. Defaults to true if `x` is a string.
---@param vAlign boolean? # If true, vertically centers the next item. Defaults to true.
---@param cellHeight number? # Optional height of the cell for vertical centering. Ignored if `x` is a number.
local function alignNext(x, hAlign, vAlign, cellHeight)
	if isNumber(x) then ---@cast x number
		hAlign = false
		cellHeight = x
	elseif isString(x) then
		hAlign = hAlign == nil and true or hAlign
	else
		return
	end

	vAlign = vAlign == nil and true or vAlign
	local style = ImGui.GetStyle()
	local fh = ImGui.GetFontSize()

	if hAlign then ---@cast x string
		local cw = ImGui.GetColumnWidth()
		local tw = ImGui.CalcTextSize(x)
		local cx = ImGui.GetCursorPosX()
		ImGui.SetCursorPosX(cx + cw - tw)
	end

	if vAlign then
		local cy = ImGui.GetCursorPosY()
		local oy = cellHeight or (fh + style.FramePadding.y * 2)
		ImGui.SetCursorPosY(cy + (oy - fh) * 0.5)
	end
end

---Sets the alpha channel of a given ABGR color without modifying the RGB components.
---@param c integer # The original color in 0xAABBGGRR format.
---@param alpha integer # The new alpha value (0-255) to apply.
---@return integer # The resulting color with the updated alpha in 0xAABBGGRR format.
local function setAlpha(c, alpha)
	if not areNumber(c, alpha) then return 0 end
	return bor(lshift(band(alpha, 0xff), 24), band(c, 0x00ffffff))
end

---Adjusts an ABGR color by modifying its alpha, blue, green, and red (weird order in LUA) components.
---@param c integer # The input color in 0xAARRGGBB format.
---@param aa integer? # Amount to add to the alpha channel.
---@param bb integer? # Amount to add to the blue channel.
---@param gg integer? # Amount to add to the green channel.
---@param rr integer? # Amount to add to the red channel.
---@return integer # The resulting adjusted color in 0xAARRGGBB format.
local function adjustColor(c, aa, bb, gg, rr)
	if not isNumber(c) then return 0 end

	local a = band(rshift(c, 24), 0xff)
	local b = band(rshift(c, 16), 0xff)
	local g = band(rshift(c, 8), 0xff)
	local r = band(c, 0xff)
	a = isNumber(aa) and math.min(0xff, a + aa) or a
	b = isNumber(bb) and math.min(0xff, b + bb) or b
	g = isNumber(gg) and math.min(0xff, g + gg) or g
	r = isNumber(rr) and math.min(0xff, r + rr) or r
	return bor(lshift(a, 24), lshift(b, 16), lshift(g, 8), r)
end

---Converts an ImGui style color from a Vec4 (floating point RGBA) to a 32-bit ABGR integer.
---@param col integer # The `ImGuiCol` enum value representing the style color (e.g., ImGuiCol.FrameBg, ImGuiCol.Text).
---@param alpha? integer # Optional override for the alpha component (0–255). If omitted, the value from the ImGui style color is used.
---@return integer # Returns the color as a 32-bit integer in the format 0xAABBGGRR. Returns 0 if the input values are invalid.
local function getStyleColor(col, alpha)
	local x, y, z, w = ImGui.GetStyleColorVec4(col)
	if not areNumber(x, y, z, w) then return 0 end

	local a = math.min(0xff, isNumber(alpha) and alpha or floor(w * 0xff))
	local b = math.min(0xff, floor(z * 0xff))
	local g = math.min(0xff, floor(y * 0xff))
	local r = math.min(0xff, floor(x * 0xff))
	return bor(lshift(a, 24), lshift(b, 16), lshift(g, 8), r)
end

---Generates three color variants from a base color for use in UI styling (e.g., normal, hovered, active).
---Each subsequent variant increases brightness slightly on BGR channels.
---@param base integer # The base color in 0xAAGGBBRR format.
---@return integer, integer, integer # Returns three color variants: base, hover, and active.
local function getThreeColorsFrom(idx, base)
	if not isNumber(base) then return 0, 0, 0 end

	local alpha = idx == ImGuiCol.Button and 0xff or 0
	local hover = adjustColor(base, alpha, 32, 32, 32)
	local active = adjustColor(base, alpha, 64, 64, 64)
	return base, hover, active
end

---Pushes a set of up to three related style colors to ImGui's style stack: base, hovered, and active.
---Calculated automatically from a single base color by brightening B, G, and R (weird order in LUA) channels.
---Returns the number of pushed styles so they can be popped accordingly.
---@param idx integer # The ImGuiCol index for the base color (e.g. ImGuiCol.FrameBg or ImGuiCol.Button).
---@param color integer # The base color in 0xAAGGBBRR format.
---@return integer # The number of style colors pushed. Returns 0 if arguments are invalid.
local function pushColors(idx, color)
	if not areNumber(idx, color) then return 0 end

	if idx == ImGuiCol.Button or idx == ImGuiCol.FrameBg then
		local hoveredIdx, activeIdx = idx + 1, idx + 2
		local base, hover, active = getThreeColorsFrom(idx, color)
		ImGui.PushStyleColor(idx, base)
		ImGui.PushStyleColor(hoveredIdx, hover)
		ImGui.PushStyleColor(activeIdx, active)
		return 3
	end

	if idx == ImGuiCol.Text then
		color = setAlpha(color, 0xff)
	end
	ImGui.PushStyleColor(idx, color)
	return 1
end

---Safely pops a number of ImGui style colors from the stack.
---Calls `ImGui.PopStyleColor(num)` only if `num` is a positive integer.
---@param num integer # The number of style colors to pop from the ImGui stack.
local function popColors(num)
	if not isNumber(num) or num <= 0 then return end
	ImGui.PopStyleColor(num)
end

---Displays a single line of text with optional horizontal centering, vertical spacing, and custom color.
---@param text string # The text to display.
---@param color? number # Optional 32-bit ABGR color (e.g. 0xffc0c0c0). If provided, temporarily overrides the current text color.
---@param heightPadding? number # Optional vertical space (in pixels) added below the text. Defaults to 0 if omitted.
---@param contentWidth? number # Optional content width, used to center the text horizontally.
---@param itemSpacing? number # Optional horizontal spacing between UI elements. Used for centering logic.
local function addText(text, color, heightPadding, contentWidth, itemSpacing)
	if not isStringValid(text) then return end

	if areNumber(contentWidth, itemSpacing) then
		local halfSize = ImGui.CalcTextSize(text) * 0.5
		local padding = math.max(0, (contentWidth - ImGui.GetScrollMaxY() - itemSpacing * 3) * 0.5 - halfSize)
		if padding > 0 then
			ImGui.Dummy(padding, 0)
			ImGui.SameLine()
		end
	end

	local isColor = isNumber(color)
	if isColor then ---@cast color number
		ImGui.PushStyleColor(ImGuiCol.Text, setAlpha(color, 0xff))
	end

	ImGui.Text(text)

	if isColor then
		ImGui.PopStyleColor()
	end

	if not isNumber(heightPadding) then return end ---@cast heightPadding number
	ImGui.Dummy(0, heightPadding)
end

---Adds centered text with custom word wrapping.
---@param text string # The text to display.
---@param wrap number # The maximum width before wrapping.
local function addTextCenterWrap(text, wrap)
	if not isStringValid(text) or not isNumber(wrap) or wrap < 10 then return end

	local ln, w = "", ImGui.GetWindowSize()
	for s in text:gmatch("%S+") do
		local t = (nilOrEmpty(ln)) and s or (ln .. " " .. s)
		if ImGui.CalcTextSize(t) > wrap and ln ~= "" then
			ImGui.SetCursorPosX((w - ImGui.CalcTextSize(ln)) * 0.5)
			ImGui.Text(ln)
			ln = s
		else
			ln = t
		end
	end
	if isStringValid(ln) then
		ImGui.SetCursorPosX((w - ImGui.CalcTextSize(ln)) * 0.5)
		ImGui.Text(ln)
	end
end

---Displays a tooltip when the current UI item is hovered.
---If a single string is passed, displays it as wrapped text.
---If multiple arguments are passed, they are interpreted as alternating key-value pairs for a tooltip table.
---If a table is passed, it will be unpacked as key-value pairs.
---@param scale number? # The resolution scale for wrapping text.
---@param ... string|table # Either a single string, a table of pairs, or a sequence of key-value pairs.
local function addTooltip(scale, ...)
	if not ImGui.IsItemHovered() then return end

	local count = select("#", ...)
	if count >= 2 then
		ImGui.BeginTooltip()
		if not ImGui.BeginTable("TooltipTable", 2) then return end
		for i = 1, count, 2 do
			local key = tostring(select(i, ...))
			local val = tostring(select(i + 1, ...) or "")
			ImGui.TableNextRow()
			ImGui.TableNextColumn()
			ImGui.Text(key)
			ImGui.TableNextColumn()
			ImGui.Text(val)
		end
		ImGui.EndTable()
		ImGui.EndTooltip()
		return
	end

	local item = select(1, ...)
	if item == nil then return end

	if isString(item) then
		ImGui.BeginTooltip()

		local wrap = scale and ceil(420 * scale) or nil
		if wrap then
			ImGui.PushTextWrapPos(wrap)
		end

		ImGui.Text(item)

		if wrap then
			ImGui.PopTextWrapPos()
		end

		ImGui.EndTooltip()
	elseif isTable(item) then
		addTooltip(nil, unpack(item))
	end
end

---Displays a modal popup with a text prompt and a dynamic list of buttons.
---
---Defaults to two buttons (Yes / No). Extra arguments are passed through `...` and are
---position-indexed by type — strings first (labels), then numbers (colors):
--- * Strings override / append labels (index 1 = Yes, 2 = No, 3+ = additional buttons).
---   An empty string `""` skips that label position (keeps the default).
--- * Numbers override colors at the matching button position.
---   A negative number skips that color position.
---
---Examples:
--- * `addPopupWithButtons(id, text, scale)` → Yes / No.
--- * `addPopupWithButtons(id, text, scale, Colors.GARNET)` → Yes (red) / No.
--- * `addPopupWithButtons(id, text, scale, "", "", -1, Colors.RED)` → Yes / No (red).
--- * `addPopupWithButtons(id, text, scale, "", "Cancel")` → Yes / Cancel.
--- * `addPopupWithButtons(id, text, scale, "", Text.GUI_NO_P, Text.GUI_Cancel, Colors.CARAMEL)`
---   → Yes (caramel) / No / Cancel.
---@param id string # The unique popup ID.
---@param text string # The message to display in the popup.
---@param scale number # UI scale factor based on current DPI and font size.
---@param ... string|number # Interleaved label overrides (strings) and color overrides (numbers).
---@return integer? # 1-based index of the pressed button, or nil if popup not active / no button pressed.
local function addPopupWithButtons(id, text, scale, ...)
	if not areStringValid(id, text) or not isNumber(scale) or not ImGui.BeginPopup(id) then return nil end

	local labels = { Text.GUI_YES, Text.GUI_NO }
	local colors = {}

	local labelIdx, colorIdx = 0, 0
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "string" then
			labelIdx = labelIdx + 1
			if v ~= "" then labels[labelIdx] = v end
		elseif type(v) == "number" then
			colorIdx = colorIdx + 1
			if v >= 0 then colors[colorIdx] = v end
		end
	end

	local result = nil

	ImGui.Text(text)
	ImGui.Dummy(0, 2)
	ImGui.Separator()
	ImGui.Dummy(0, 2)

	local width, height = ceil(80 * scale), floor(30 * scale)

	for i, label in ipairs(labels) do
		if i > 1 then ImGui.SameLine() end

		local color = colors[i]
		local pushed = 0
		if color then
			pushed = pushColors(ImGuiCol.Button, color) + pushColors(ImGuiCol.Text, Colors.WHITE)
		end

		if ImGui.Button(label, width, height) then
			result = i
			ImGui.CloseCurrentPopup()
		end

		if pushed > 0 then popColors(pushed) end
	end

	ImGui.EndPopup()

	return result
end

---Draws a vertical on-screen ruler at the bottom center of the screen.
---@param scale number # UI scale factor based on current DPI and font size.
---@param maxWidth number # Screen width for window positioning.
---@param maxHeight number # Screen height for window positioning.
local function drawRuler(scale, maxWidth, maxHeight)
	if not areNumber(scale, maxWidth, maxHeight) then return end

	ImGui.PushStyleColor(ImGuiCol.WindowBg, 0x00000000)
	ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)

	local flags = bor(
		ImGuiWindowFlags.NoTitleBar,
		ImGuiWindowFlags.NoMove,
		ImGuiWindowFlags.NoCollapse,
		ImGuiWindowFlags.AlwaysAutoResize,
		ImGuiWindowFlags.NoSavedSettings,
		ImGuiWindowFlags.NoFocusOnAppearing,
		ImGuiWindowFlags.NoBringToFrontOnFocus
	)
	if not ImGui.Begin("VerticalScreenRuler", true, flags) then return end

	local cache = getCache(0xd6ae, true) or {}
	cache.isHigh = cache.isHigh ~= nil and cache.isHigh or equals(getUserSettingsCameraHeight(), "High")

	local lineH = ImGui.GetTextLineHeight() * 0.2
	local posX, posY = ImGui.GetCursorPos()
	local fov = get(config.options, 69, "fov", "Value")
	local zoom = get(config.options, 1.00, "zoom", "Value")
	local ticks = fov > 69 and fov or 62

	local indices = (function()
		if not cache.isHigh or not equals(zoom, 1.00) then return end

		--Known positions.
		local map = cache.markPosMap or {
			[69]  = { -1, 10, 60, 61, 62 },
			[75]  = { -1, 25, 69, 70, 71 },
			[80]  = { -1, 35, 76, 77, 78 },
			[85]  = { 12, 45, 82, 83, 84 },
			[90]  = { 24, 54, 87, 88, 89 },
			[95]  = { 34, 62, 92, 93, 94 },
			[100] = { 44, 69, 98, 99, 100 },
			[105] = { 53, 76, 101, 102, 103 },
			[110] = { 61, 82, 105, 106, 107 }
		}
		cache.markPosMap = map

		if map[fov] then return map[fov] end

		--Using a proportional formula between FOV and known positions to calculate unknown ones.
		local keys = {}
		for k in pairs(map) do insert(keys, k) end
		sort(keys, function(a, b) return a < b end)

		local p, n
		for i = 1, #keys do
			if keys[i] <= fov then p = keys[i] end
			if keys[i] >= fov and not n then n = keys[i] end
		end
		p = p or n
		n = n or p

		local t = (fov - p) / (n - p)
		local r = {}
		for i = 1, 5 do
			r[i] = (map[p][i] == -1 or map[n][i] == -1) and -1 or floor(map[p][i] + (map[n][i] - map[p][i]) * t + 0.5)
		end

		cache.markPosMap[fov] = r
		return r
	end)()

	local colors = {}
	if isTableValid(indices) then ---@cast indices table
		cache.colors = cache.colors or {
			Colors.GREEN,
			Colors.CYAN,
			Colors.YELLOW,
			Colors.ORANGE,
			Colors.RED
		}
		for i, idx in ipairs(indices) do
			if idx > 0 then
				colors[idx] = cache.colors[i]
			end
		end
	end

	cache.reps = cache.reps or {}
	cache.nums = cache.nums or {}
	for i = 0, ticks do
		local isMajor = i % 10 == 0

		local tick = cache.reps[i] or rep("_", isMajor and 5 or i % 5 == 0 and 4 or 3)
		cache.reps[i] = tick

		local num = cache.nums[i] and cache.nums[i] or (isMajor and format(" %3d", i) or "")
		cache.nums[i] = num

		local px, py = posX, posY + (ticks - i) * lineH
		local color = colors[i]

		ImGui.SetCursorPos(px, py)

		ImGui.PushStyleColor(ImGuiCol.Text, color or Colors.WHITE)

		ImGui.Text(tick .. num)

		if color then
			ImGui.SetCursorPos(px, py - 1)
			ImGui.Text(tick)
		end

		ImGui.PopStyleColor()
	end

	local width, height = ImGui.GetWindowSize()
	local x, y = (maxWidth - width) * 0.5 + gui.rulerOffset * scale, (maxHeight - height) + 9 * scale
	ImGui.SetWindowPos(x, y)

	ImGui.PopStyleColor()
	ImGui.End()

	setCache(0xd6ae, cache, true)
end

---Draws and manages the Global Settings window.
---@param scale number # UI scale factor based on current DPI and font size.
---@param x number # X-coordinate of the window's top-left corner.
---@param y number # Y-coordinate of the window's top-left corner.
---@param width number # Width of the window in pixels.
---@param height number # Height of the window in pixels. Minimum height enforced internally.
---@param halfContentWidth number # Half of the usable content width, used for calculating button widths.
---@param heightPadding number # Vertical spacing below the table, in pixels.
---@param buttonHeight number # Height of buttons in pixels.
---@param sbarWidth number # Width of the vertical scrollbar, used for button layout adjustments.
---@return boolean # Returns true if the Advanced Settings section was just opened by the user; false otherwise.
local function openGlobalOptionsWindow(scale, x, y, width, height, halfContentWidth, heightPadding, buttonHeight, sbarWidth)
	if not config.isOpen or not areNumber(scale, x, y, width, height, halfContentWidth, heightPadding, buttonHeight, sbarWidth) then
		return false
	end

	ImGui.SetNextWindowPos(x, y)

	local cache = getCache(0x958a, true) or 270

	height = math.max(height, cache * scale)
	ImGui.SetNextWindowSize(width, height)

	ImGui.PushStyleColor(ImGuiCol.WindowBg, getStyleColor(ImGuiCol.WindowBg, 0xff))
	local flags = bor(
		ImGuiWindowFlags.NoResize,
		ImGuiWindowFlags.NoMove,
		ImGuiWindowFlags.NoCollapse,
		ImGuiWindowFlags.NoSavedSettings
	)
	config.isOpen = ImGui.Begin(Text.GUI_SETTINGS, config.isOpen, flags)
	if not config.isOpen then return false end
	ImGui.PopStyleColor()

	if not gui.hasInitialized[Text.GUI_SETTINGS] then
		gui.hasInitialized[Text.GUI_SETTINGS] = true
		ImGui.SetKeyboardFocusHere(-1)
	end

	if not isTableValid(config.options) or not ImGui.BeginTable("GlobalOptions", 2, ImGuiTableFlags.Borders) then
		ImGui.End()
		return false
	end

	ImGui.TableSetupColumn(" \u{f0572}", ImGuiTableColumnFlags.WidthStretch)
	ImGui.TableSetupColumn(" \u{f189a}", ImGuiTableColumnFlags.WidthFixed)
	ImGui.TableHeadersRow()

	for key, option in opairs(config.options, "DisplayName") do
		---@cast option IOptionData
		if option.IsUnavailable then goto continue end

		local depKey = option.Dependency
		if isStringValid(depKey) then
			local depDef = get(config.options, nil, depKey, "Default")
			if depDef ~= nil then
				local depVal = get(config.options, nil, depKey, "Value")
				if depVal ~= nil and depVal == depDef then
					cache = 270
					goto continue
				end
				cache = 380
			end
		end

		ImGui.TableNextRow()

		ImGui.TableNextColumn()
		---@cast key string
		ImGui.Text(tostring(option.DisplayName or key))

		ImGui.TableNextColumn()
		local isFov = key == "fov"
		local current = option.Value
		local items = option.Values
		local label = "##" .. key
		local changed, recent = false, nil
		if isTableValid(items) then ---@cast items string[]
			ImGui.SetNextItemWidth(floor(60 * scale))
			if ImGui.BeginCombo(label, items[current]) then
				for i, item in ipairs(items) do
					local isSelected = current == i
					if ImGui.Selectable(item, isSelected) and current ~= i then
						recent = i
						changed = true
					end
					if isSelected then
						ImGui.SetItemDefaultFocus()
					end
				end
				ImGui.EndCombo()
			end
		elseif isBoolean(current) then ---@cast current boolean
			recent = ImGui.Checkbox(label, current)
			if recent ~= current then
				changed = true
			end
			addTooltip(scale, option.Tooltip)
		elseif isNumber(current) then ---@cast current number
			local default = option.Default ---@cast default number
			local min = option.Min ---@cast min number
			local max = option.Max ---@cast max number
			if not areNumber(min, max) then
				min = -math.huge
				max = math.huge
			end

			local rawDefault, rawCurrent, rawMin, rawMax
			if isFov and state.isFovControlAvailable then
				rawDefault = default
				default = changeFovFormat(default)

				rawCurrent = current
				current = changeFovFormat(current)

				min = changeFovFormat(min)
				rawMin = min

				max = changeFovFormat(max)
				rawMax = max
			end

			local speed = option.Speed or 0.01
			local precision = getPrecision(speed)

			ImGui.SetNextItemWidth(floor(24 * scale * #format("%3s", max) * 0.5))
			recent = ImGui.DragFloat(label, current, speed, min, max, precision)
			if recent ~= current and inRange(recent, min, max) then
				changed = true
			end

			if isFov and state.isFovControlAvailable then
				local valueLabel = Text.GUI_GSET_FOV_TIP_VAL
				addTooltip(nil, split(format(option.Tooltip,
					format(valueLabel, default, rawDefault),
					format(valueLabel, min, rawMin),
					format(valueLabel, max, rawMax),
					format(valueLabel, current, rawCurrent)), "|"))
			else
				addTooltip(nil, split(format(option.Tooltip, roundF(default), roundF(min), roundF(max), roundF(current)), "|"))
			end
		else
			ImGui.Text(Text.GUI_UNKNOWN)
		end

		if changed then
			if config.nativeInstance and config.nativeOptions[key] then
				config.nativeInstance.setOption(config.nativeOptions[key], recent)
			else
				if isFov then ---@cast recent number
					recent = changeFovFormat(recent, true)
				end
				updateConfigValue(key, recent, true, isFov)
			end
		end

		::continue::
	end

	ImGui.EndTable()
	ImGui.Dummy(0, heightPadding)

	local isAdvancedOpening = false

	local buttonWidth = halfContentWidth - (ImGui.GetScrollMaxY() > 0 and sbarWidth / 2 or 0)
	if ImGui.Button(Text.GUI_GSET_ADVANCED, buttonWidth, buttonHeight) then
		config.isAdvancedOpen = not config.isAdvancedOpen
		isAdvancedOpening = config.isAdvancedOpen
	end
	addTooltip(scale, Text.GUI_GSET_ADVANCED_TIP)
	ImGui.SameLine()

	if ImGui.Button(Text.GUI_GSET_RESET, buttonWidth, buttonHeight) then
		for key, option in pairs(config.options) do
			local default = option.Default
			local isFov = key == "fov"
			if config.nativeInstance and config.nativeOptions[key] then
				if isFov then ---@cast default number
					default = changeFovFormat(default)
				end
				config.nativeInstance.setOption(config.nativeOptions[key], default)
			else
				updateConfigValue(key, default, true, isFov)
			end
		end
	end
	addTooltip(scale, Text.GUI_GSET_RESET_TIP)

	ImGui.End()

	setCache(0x958a, cache)

	return isAdvancedOpening
end

---Draws and manages the Advanced Settings window.
---@param scale number # UI scale factor based on current DPI and font size.
---@param isOpening boolean # True if the window is being opened; positions and sizes are reset accordingly.
---@param maxWidth number # Screen width for window positioning and constraints.
---@param maxHeight number # Screen height for window positioning and constraints.
local function openAdvancedOptionsWindow(scale, isOpening, maxWidth, maxHeight)
	if not config.isAdvancedOpen or not areNumber(scale) then return end

	ImGui.SetNextWindowSizeConstraints(440 * scale, 200 * scale, 600 * scale, maxHeight or math.huge)

	local x, y, width, height
	if isOpening and areNumber(maxWidth, maxHeight) then
		width, height = 460 * scale, maxHeight * 0.85
		x, y = (maxWidth - width) * 0.5, (maxHeight - height) * 0.25
		ImGui.SetNextWindowPos(x, y)
		ImGui.SetNextWindowSize(width, height)
	end

	local flags = bor(
		ImGuiWindowFlags.NoCollapse,
		ImGuiWindowFlags.NoSavedSettings
	)
	config.isAdvancedOpen = ImGui.Begin(Text.GUI_ASET_TITLE, config.isAdvancedOpen, flags)
	if not config.isAdvancedOpen then return end

	if validateWindowBounds(x, y, width, height, maxWidth, maxHeight) then
		ImGui.End()
		return
	end

	if not gui.hasInitialized[Text.GUI_ASET_TITLE] then
		gui.hasInitialized[Text.GUI_ASET_TITLE] = true
		ImGui.SetKeyboardFocusHere(-1)
	end

	local cache = getCache(0x2e7c) or {}
	local header = {
		Text.GUI_ASET_HEAD1,
		Text.GUI_ASET_HEAD2
	}
	local _, regionHeight, frameHeight = ImGui.GetContentRegionAvail()
	for i, section in ipairs(DefaultParams.Keys) do
		cache[i] = ImGui.CollapsingHeader(header[i], bor(ImGuiTreeNodeFlags.DefaultOpen))
		if not cache[i] then goto continue end

		frameHeight = frameHeight or ImGui.GetFrameHeight()
		local childHeight = (cache[1] and cache[2] and regionHeight / 2 - frameHeight * 1.5 or regionHeight - frameHeight * 3)
		if ImGui.BeginChild("TableChild_" .. section .. i, 0, childHeight, false) then
			if ImGui.BeginTable("DataTable_" .. section .. i, 3, bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg)) then
				ImGui.TableSetupColumn("##" .. 0, ImGuiTableColumnFlags.WidthFixed, -1)
				ImGui.TableSetupColumn("##" .. 1, ImGuiTableColumnFlags.WidthStretch)
				ImGui.TableSetupColumn("##" .. 2, ImGuiTableColumnFlags.WidthFixed, -1)

				for var, data in opairs(DefaultParams.Vars) do
					if config.options[var] then goto continue end

					ImGui.TableNextColumn()
					local text = camelToHuman(var)
					ImGui.Text(text)
					addTooltip(scale, data.Tip)

					ImGui.TableNextColumn()
					local default = pluck(data.Default, i)
					local current = get(config.advancedOptions, default, i, var)
					local changed, recent = false, nil
					ImGui.SetNextItemWidth(-1)
					if isBoolean(current) then
						recent = ImGui.Checkbox("##" .. var .. i, current)
					elseif isNumber(current) then
						local min = data.Min or -math.huge
						local max = data.Max or math.huge
						local step = data.Step or getStep(current)
						local precision = getPrecision(step)
						recent = ImGui.DragFloat("##" .. var .. i, current, step, min, max, precision)
						addTooltip(nil, split(format(Text.GUI_ASET_VAL_TIP, default, min, max), "|"))
					else
						ImGui.Text("\u{f01f7}")
					end
					if not equals(recent, current) then
						changed = true
					end

					ImGui.TableNextColumn()
					local isUndoOff = equals(current, default)
					if isUndoOff then
						ImGui.BeginDisabled(true)
						ImGui.PushStyleColor(ImGuiCol.Button, Colors.DARKGRAY)
					end
					ImGui.SetNextItemWidth(-1)
					if ImGui.Button("\u{f054d}##" .. var .. i) then
						changed = true
						recent = default
					end
					if isUndoOff then
						ImGui.PopStyleColor()
						ImGui.EndDisabled()
					end

					if changed then
						updateAdvancedConfigValue(i, var, default, true)
						if config.nativeInstance and config.nativeOptions[i .. var] then
							config.nativeInstance.setOption(config.nativeOptions[i .. var], recent)
						end
					end

					::continue::
				end

				ImGui.EndTable()
			end

			ImGui.EndChild()
		end

		::continue::
	end

	setCache(0x2e7c, cache)
	ImGui.End()
end

---Draws and manages the Preset Explorer window.
---@param scale number # UI scale factor based on current DPI and font size.
---@param isOpening boolean # Whether the window is being opened (to set initial position and size).
---@param x number # The initial X position of the window, used only on first opening.
---@param y number # The initial Y position of the window, used only on first opening.
---@param width number # The initial width of the window.
---@param height number # The initial height of the window.
---@param maxHeight number # The maximum height allowed for the window.
---@param halfHeightPadding number # Half of the vertical padding value, used for layout spacing.
---@param buttonHeight number # The height for button controls in the file table.
---@param itemSpacing number # Horizontal spacing between UI elements, used for centering logic.
local function openFileExplorerWindow(scale, isOpening, x, y, width, height, maxHeight, halfHeightPadding, buttonHeight, itemSpacing)
	if not explorer.isOpen or not areNumber(scale, width, height, maxHeight, halfHeightPadding, buttonHeight) then
		return
	end

	local cache = getCache(0x970b, true) or {}
	local dirs = cache.dirs or {
		PresetFolders.VANILLA,
		PresetFolders.CUSTOM
	}
	local files = cache.files
	local isScanning = false
	if not isTableValid(files) then
		isScanning = true
		local scan = explorer.scan
		if not scan then
			scan = { files = {}, dirIdx = 1, entryIdx = 1, entries = nil }
			explorer.scan = scan
		end
		local budget = 40
		while budget > 0 and scan.dirIdx <= #dirs do
			if not scan.entries then
				scan.entries = dir(dirs[scan.dirIdx]) or {}
				scan.entryIdx = 1
				break
			end
			while budget > 0 and scan.entryIdx <= #scan.entries do
				local entry = scan.entries[scan.entryIdx]
				scan.entryIdx = scan.entryIdx + 1
				budget = budget - 1
				local name = entry and entry.name
				if name and hasLuaExt(name) then
					scan.files[name] = scan.dirIdx
				end
			end
			if scan.entryIdx > #scan.entries then
				scan.dirIdx = scan.dirIdx + 1
				scan.entries = nil
			end
		end
		if scan.dirIdx > #dirs then
			cache.dirs = dirs
			cache.files = scan.files
			setCache(0x970b, cache, true)
			files = scan.files
			explorer.scan = nil
			isScanning = false
		else
			files = {}
		end
	end

	height = math.max(height, 400 * scale)
	if isOpening and areNumber(x, y) then
		ImGui.SetNextWindowPos(x, y)
		ImGui.SetNextWindowSize(width, height)
	end
	ImGui.SetNextWindowSizeConstraints(width, height, math.max(width, 400 * scale), maxHeight)

	ImGui.PushStyleColor(ImGuiCol.WindowBg, getStyleColor(ImGuiCol.WindowBg, 0xff))
	local flags = bor(
		ImGuiWindowFlags.NoCollapse,
		ImGuiWindowFlags.NoSavedSettings
	)
	explorer.isOpen = ImGui.Begin(Text.GUI_PSET_EXPL, explorer.isOpen, flags)
	if not explorer.isOpen then return end
	ImGui.PopStyleColor()

	local isValidated, _, _, _, winHeight = validateWindowBounds()
	if isValidated then
		ImGui.End()
		return
	end

	if not gui.hasInitialized[Text.GUI_PSET_EXPL] then
		gui.hasInitialized[Text.GUI_PSET_EXPL] = true
		ImGui.SetKeyboardFocusHere(-1)
	end

	local barFlags = bor(ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.SizingFixedFit)
	local barHeight = floor(32 * scale)
	if ImGui.BeginTable("SearchBar", 3, barFlags) then
		ImGui.TableSetupColumn("##Label", ImGuiTableColumnFlags.WidthFixed, barHeight)
		ImGui.TableSetupColumn("##Input", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn("##PadRight", ImGuiTableColumnFlags.WidthFixed, barHeight)

		ImGui.TableNextRow()

		ImGui.TableNextColumn()
		local label = "\u{f1a7e}"
		alignNext(label)
		ImGui.Text(label)

		ImGui.TableNextColumn()
		ImGui.SetNextItemWidth(-1)
		local recent, changed = ImGui.InputText("##Search", explorer.searchText or "", 96)
		if changed and recent then
			explorer.searchText = recent
		end

		local cmds = cache.commands
		if not cmds then
			cmds = split(format(Text.GUI_PSET_EXPL_SEARCH_TIP,
				ExplorerCommands.INSTALLED,
				ExplorerCommands.MODDED,
				ExplorerCommands.UNAVAILABLE,
				ExplorerCommands.ACTIVE,
				ExplorerCommands.INACTIVE,
				ExplorerCommands.VANILLA), "|")
			cache.commands = cmds
			setCache(0x970b, cache, true)
		end
		addTooltip(nil, cmds)

		ImGui.EndTable()
	end
	ImGui.Dummy(0, halfHeightPadding)

	local command = nil
	local search = (explorer.searchText or ""):lower()
	for _, value in pairs(ExplorerCommands) do
		if search == value then
			command = value
			search = ""
			break
		end
	end

	local visible = {}
	for fileName, dirNum in opairs(files) do
		if #search > 0 and not fileName:lower():find(search, 1, true) then
			goto continue
		end

		local key = trimLuaExt(fileName)
		local pset = presets.collection[key]
		if (pset and command == ExplorerCommands.MODDED and pset.IsVanilla) or
			(command == ExplorerCommands.VANILLA and dirNum > 1) then
			goto continue
		end

		local color
		if not pset then
			if isStringValid(command) and command ~= ExplorerCommands.UNAVAILABLE and command ~= ExplorerCommands.VANILLA then
				goto continue
			end
			color = Colors.GARNET
		end
		if command == ExplorerCommands.UNAVAILABLE and not color then
			goto continue
		end

		local usage = presets.usage[key]
		if isTableValid(usage) then
			if command == ExplorerCommands.INACTIVE then goto continue end
			color = Colors.FIR
		end
		if command == ExplorerCommands.ACTIVE and color ~= Colors.FIR then goto continue end

		visible[#visible + 1] = { fileName = fileName, dirNum = dirNum, key = key, usage = usage, color = color }
		::continue::
	end
	explorer.totalVisible = #visible

	local columnWidth
	if ImGui.BeginTable("PresetFiles", 2, bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg)) then
		ImGui.TableSetupColumn(" \u{f09a8}" .. explorer.totalVisible, ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn(" \u{f05e9}", ImGuiTableColumnFlags.WidthFixed)
		ImGui.TableHeadersRow()

		local drawRow = function(item)
			local fileName, dirNum, key, usage, color = item.fileName, item.dirNum, item.key, item.usage, item.color

			ImGui.TableNextRow()
			ImGui.TableNextColumn()

			alignNext(buttonHeight)
			color = color and pushColors(ImGuiCol.Text, color) or 0
			columnWidth = columnWidth or ((ImGui.GetColumnWidth(0) - 4) * scale)

			local short = item.short
			if short == nil or item.shortWidth ~= columnWidth then
				local textWidth = ImGui.CalcTextSize(key) * scale
				if columnWidth < textWidth then
					local dots = "..."
					local cutoff = columnWidth - ImGui.CalcTextSize(dots) * scale
					short = key
					while #short > 0 and ImGui.CalcTextSize(short) * scale > cutoff do
						short = short:sub(1, -2)
					end
					short = short .. dots
				else
					short = false
				end
				item.short = short
				item.shortWidth = columnWidth
			end

			if short then
				ImGui.Text(short)
				addTooltip(scale, format(Text.GUI_PSET_EXPL_NAME_TIP, key))
			else
				ImGui.Text(key)
			end
			popColors(color)

			if usage then
				if short then
					addTooltip(scale, "\n")
				end
				local fmt = "%Y-%m-%d %H:%M:%S %p"
				addTooltip(nil,
					split(format(Text.GUI_PSET_EXPL_USAGE_TIP,
						os.date(fmt, usage.First),
						os.date(fmt, usage.Last),
						usage.Total), "|"))
			end

			ImGui.TableNextColumn()
			local pushd = pushColors(ImGuiCol.Button, Colors.GARNET) + pushColors(ImGuiCol.Text, Colors.WHITE)
			if ImGui.Button("\u{f0a7a}##" .. fileName, 0, buttonHeight) then
				ImGui.OpenPopup(fileName)
			end
			popColors(pushd)
			addTooltip(scale, Text.GUI_PSET_EXPL_DEL_TIP)

			local folder = dirs[dirNum]
			local path = combine(folder, fileName)
			if addPopupWithButtons(fileName, format(Text.GUI_PSET_EXPL_DEL_POP, path), scale, Colors.GARNET) == 1 then
				if not folder then return end

				local ok, err = os.remove(path)
				if ok then
					for n in pairs(editor.bundles) do
						local parts = split(n, "*")
						if #parts >= 2 then
							local vName, aName = parts[1], parts[2]
							if startsWith(vName, key) or startsWith(aName, key) then
								editor.bundles[n] = nil
							end
						end
					end

					setPresetEntry(key)

					if get(editor.lastBundle, {}, "Flux").Key == key then
						restoreModifiedPresets()
						clearLastEditorBundle()
					end

					logF(DevLevels.ALERT, LogLevels.INFO, 0x970b, Text.LOG_PSET_DELETED, fileName)

					setCache(0x970b, nil, true)
				else
					logF(DevLevels.FULL, LogLevels.WARN, 0x970b, Text.LOG_PSET_DEL_FAIL, fileName, err)
				end
			end
		end

		local clipper = ImGuiListClipper.new()
		clipper:Begin(#visible)
		while clipper:Step() do
			for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
				drawRow(visible[i])
			end
		end

		ImGui.EndTable()
	end

	if not isNumber(itemSpacing) then
		ImGui.End()
		return
	end

	local isEmpty = nilOrEmpty(files)
	if isScanning or isEmpty or explorer.totalVisible < 1 then
		local text, color
		if isScanning then
			text, color = Text.GUI_PSET_EXPL_LOADING, Colors.CARAMEL
		elseif isEmpty then
			text, color = Text.GUI_PSET_EXPL_EMPTY, Colors.GARNET
		else
			text, color = Text.GUI_PSET_EXPL_UNMATCH, Colors.MULBERRY
		end

		local textSize = ImGui.CalcTextSize(text) * scale
		local conWidth = ImGui.GetContentRegionAvail()
		local heightPad = math.floor(winHeight * 0.15)
		local widthPad = math.max((conWidth - textSize) * 0.5 - itemSpacing * 0.5, 8 * scale)

		ImGui.Dummy(0, heightPad)
		ImGui.Dummy(widthPad, 0)
		ImGui.SameLine()

		ImGui.PushStyleColor(ImGuiCol.Text, setAlpha(color, 0xff))
		ImGui.Text(text)
		ImGui.PopStyleColor()
	end

	ImGui.End()
end

--#endregion

--#region 🎬 Runtime Behavior

---Initializes the mod when CET is loaded.
---This function is triggered once at the beginning of a session.
---It loads all preset files, usage data, and applies the current camera preset.
local function onInit()
	loadGlobalOptions()
	loadAdvancedOptions()
	updateAdvancedConfigData()
	updateConfigData()
	loadPresetUsage()

	local task = presets.loaderTask
	if not isFunction(task.Finalizer) then
		task.Finalizer = function()
			resetCache(true)
			clearLastEditorBundle()
			resetCache()
			applyPreset()

			local available = false
			for _, preset in pairs(presets.collection) do
				if not preset.IsDefault and equalsAny(preset.ID, "2w_Preset", "Brennan_Preset") then
					available = true
					break
				end
			end
			if not available then
				local option = deep(config.options, "closerBikes")
				option.Value = option.Default
				option.IsUnavailable = true
			end
		end
	end

	loadPresets(true, 5)
end

---Handles logic when a vehicle is unmounted.
---If forced or the mod is enabled, resets padding and cache, restores default presets,
---and clears the last active editor session state.
---@param force boolean? # If true, unmount logic will execute even if the mod is disabled.
local function onUnmount(force)
	if not force and not state.isModEnabled then return end

	if not force and state.devMode >= DevLevels.ALERT then
		log(LogLevels.INFO, 0x9dee, Text.LOG_EVNT_UMNT)
	end

	gui.forceMetricsReset = true
	savePresetUsage()

	restoreModifiedPresets()
	updateConfigData(true)
	updateAdvancedConfigData(true)

	clearLastEditorBundle()

	resetCache()
	presets.isAnyActive = false
end

---Handles logic when the game or CET shuts down.
---Restores all camera presets and parameters to default and saves usage stats.
local function onShutdown()
	restoreAllPresets()
	restoreAllCustomCameraData()
	updateConfigData(true)
	updateAdvancedConfigData(true)
end

---Initializes or refreshes all settings in the Native Settings UI.
local function setupNativeSettings()
	local native = GetMod("nativeSettings")
	if not native then return end
	config.nativeInstance = native

	local tab = "/" .. Text.GUI_NAME
	local isNew = false
	if not native.pathExists(tab) then
		native.addTab(tab, Text.GUI_TITLE)
		isNew = true
	else
		for _, option in pairs(config.nativeOptions) do
			native.removeOption(option)
		end
		config.nativeOptions = {}
	end

	--Ensures that multiple save queues aren't started simultaneously.
	local pendingSaves = {}

	---Asynchronous queue that delays saving until the settings tab is closed.
	---@param advanced boolean? # If true, Advanced Options are saved; otherwise, Global Settings are saved.
	local function saveToFile(advanced)
		advanced = advanced == true
		if pendingSaves[advanced] then return end

		pendingSaves[advanced] = true
		asyncRepeat(1, function(id)
			if gui.isOverlayOpen or not nilOrEmpty(native.currentTab) then return end
			asyncStop(id)
			pendingSaves[advanced] = false
			if advanced then
				config.isAdvancedUnsaved = true
				saveAdvancedOptions()
			else
				saveGlobalOptions()
			end
		end)
	end

	---Adds a settings option dynamically based on its type (list, boolean, or numeric).
	---Used internally to register configuration entries with the native settings system.
	---@param key string # Unique option identifier.
	---@param section string # The subcategory where the option appears in the Settings UI.
	---@param label string # Display name shown in the settings UI.
	---@param desc string # Description text.
	---@param default number|boolean # Default value for the option.
	---@param value number|boolean # Current value of the option.
	---@param min number? # Minimum numeric value (for sliders).
	---@param max number? # Maximum numeric value (for sliders).
	---@param speed number? # Step size for numeric options; fractional speeds imply float sliders.
	---@param list string[]? # Optional list of selectable string values.
	---@param setValue fun(value: any) # Callback used when the value changes.
	local function addOption(key, section, label, desc, default, value, min, max, speed, list, setValue)
		local added
		if isTableValid(list) then
			added = native.addSelectorString(section, label, desc, list, value, default, setValue)
		elseif isBoolean(default) then
			added = native.addSwitch(section, label, desc, value, default, setValue)
		elseif isNumber(default) then
			speed = speed or 1

			local isFloat = speed % 1 ~= 0
			added = (isFloat and native.addRangeFloat or native.addRangeInt)(
				section,
				label,
				desc,
				min,
				max,
				speed,
				isFloat and getPrecision(speed) or value,
				isFloat and value or default,
				isFloat and default or setValue,
				isFloat and setValue or nil
			)
		end
		if added then
			while config.nativeOptions[key] ~= nil do
				logF(DevLevels.FULL, LogLevels.ERROR, 0xc024, Text.LOG_KEY_DUPLICATE, key)
				key = format("%s-%s", key, checksum(key))
			end
			config.nativeOptions[key] = added
		end
	end

	---Core Settings
	local cat = combine(tab, "CoreSettings")
	if native.pathExists(cat) then
		native.removeSubcategory(cat)
	end
	native.addSubcategory(cat, Text.NUI_CAT_CSET)

	addOption("Mod", cat, Text.NUI_CSET_MOD, Text.NUI_CSET_MOD_TIP, true, state.isModEnabled, nil, nil, nil, nil,
		function(value)
			state.isModEnabled = value
			if value then
				onInit()
				logF(DevLevels.ALERT, LogLevels.INFO, 0xcb3d, Text.LOG_MOD_ON)
			else
				asyncStop(true)

				onUnmount(true)
				onShutdown()
				purgePresets()

				editor.bundles = {}
				presets.usage = {}
				state.devMode = DevLevels.DISABLED

				logF(DevLevels.ALERT, LogLevels.INFO, 0xcb3d, Text.LOG_MOD_OFF)

				resetCache(false)
				resetCache(true)
			end
			setupNativeSettings()
		end
	)

	--Global Settings
	cat = combine(tab, "GlobalSettings")
	if native.pathExists(cat) then
		native.removeSubcategory(cat)
	end
	if state.isModEnabled then
		native.addSubcategory(cat, Text.NUI_CAT_GSET)

		for key, option in opairs(config.options, "DisplayName") do
			if not option.IsUnavailable then
				local def = option.Default
				local cur = option.Value
				local min = option.Min
				local max = option.Max

				local isFov = key == "fov"
				if isFov and areNumber(def, cur, min, max) then
					def = changeFovFormat(def)
					cur = changeFovFormat(cur)
					min = changeFovFormat(min)
					max = changeFovFormat(max)
				end
				addOption(
					key,
					cat,
					option.DisplayName,
					option.Description or option.Tooltip,
					def,
					cur,
					min,
					max,
					option.Speed,
					option.Values,
					function(value)
						if isFov and state.isFovControlAvailable and isNumber(value) then
							value = changeFovFormat(value, true)
						end
						updateConfigValue(key, value, true, isFov)
						saveToFile()
					end
				)
			end
		end
	end

	--Advanced Settings
	local cats = {
		Text.NUI_CAT_ASET1,
		Text.NUI_CAT_ASET2,
	}
	for i in ipairs(DefaultParams.Keys) do
		cat = combine(tab, "AdvancedSettings" .. i)
		if native.pathExists(cat) then
			native.removeSubcategory(cat)
		end
		if not state.isModEnabled then goto continue end

		native.addSubcategory(cat, cats[i])

		for var, origin in opairs(DefaultParams.Vars) do
			if config.options[var] then goto continue end

			local label = truncateMiddle(camelToHuman(var), 48)
			local default = pluck(origin.Default, i)
			local current = get(config.advancedOptions, default, i, var)
			local defText
			if isBoolean(default) then
				defText = default and Text.GUI_ON or Text.GUI_OFF
			else
				defText = tostring(default)
			end
			local desc = format(Text.NUI_VAL_NOTE, origin.Tip or Text.GUI_GSET_ADVANCED_TIP, defText)

			addOption(
				i .. var,
				cat,
				label,
				desc,
				default,
				current,
				origin.Min,
				origin.Max,
				origin.Step or 1,
				nil,
				function(value)
					updateAdvancedConfigValue(i, var, value, true)
					saveToFile(true)
				end
			)

			::continue::
		end

		::continue::
	end

	logF(DevLevels.BASIC, LogLevels.INFO, 0x60b9, isNew and Text.LOG_NUI_INIT or Text.LOG_NUI_UPD)
end

--[[
---This event gets triggered even before `onInit`.
registerForEvent("onTweak", function()
	--Save default presets.
	local defaults = {
		"2w_Preset",
		"4w_911",
		"4w_aerondight",
		"4w_Alvarado_Preset",
		"4w_Archer_Hella",
		"4w_Archer_Quarz",
		"4w_BMF",
		"4w_caliburn",
		"4w_Columbus",
		"4w_Cortes_Preset",
		"4w_Galena",
		"4w_Galena_Nomad",
		"4w_herrera_outlaw",
		"4w_herrera_riptide",
		"4w_Hozuki",
		"4w_Limo_Thrax",
		"4w_Mahir_Supron_Kurtz",
		"4w_Makigai",
		"4w_Medium_Preset",
		"4w_Preset",
		"4w_Quadra",
		"4w_Quadra66",
		"4w_Quadra66_Nomad",
		"4w_Shion",
		"4w_Shion_Nomad",
		"4w_SubCompact_Preset",
		"4w_Tanishi",
		"4w_Thorton_Colby",
		"4w_Thorton_Colby_Pickup",
		"4w_Thorton_Colby_Pickup_Kurtz",
		"4w_Truck_Preset",
		"Brennan_Preset",
		"Default_Preset",
		"v_militech_basilisk_CameraPreset",
		"v_standard25_mahir_supron_CameraPreset",
		"v_utility4_centurion",
		"v_utility4_kaukaz_bratsk_Preset",
		"v_utility4_kaukaz_zeya_Preset",
		"v_utility4_militech_behemoth_Preset"
	}
	for _, value in ipairs(defaults) do
		local preset = getPreset(value)
		if preset then
			savePreset(preset.ID, preset, true, true)
		end
	end
end)
--]]

--This event is triggered when the CET initializes this mod.
registerForEvent("onInit", function()
	local backupDevMode

	--Game version check.
	state.gameVersion = getGameVersion()
	state.isGameCompatible = isVersionAtLeast(state.gameVersion, "2.21")

	--CET version check.
	state.cetVersion = getRuntimeVersion()
	state.isCetCompatible = isVersionAtLeast(state.cetVersion, "1.35")
	state.isCetTopical = isVersionAtLeast(state.cetVersion, "1.35.1")

	--Codeware dependence.
	---@diagnostic disable-next-line: undefined-global
	state.isCodewareAvailable = type(Codeware) == "userdata"

	---Determines whether `FovControl` is installed.
	if not state.isCodewareAvailable then
		deep(config.options, "zoom").IsUnavailable = false
	end

	--FovControl dependence.
	---@diagnostic disable-next-line: undefined-global, undefined-field
	state.isFovControlAvailable = type(FovControl) == "userdata" and type(FovControl.Version) == "function"

	--Ensures the log file is fresh when the mod initializes.
	pcall(function()
		local name = "ThirdPersonVehicleCameraTool"
		for i = 1, 9 do
			local path = format("%s.%d.log", name, i)
			if not fileExists(path) then
				break
			end
			pcall(os.remove, path)
		end
		local file = io.open(format("%s.log", name), "w")
		if file then file:close() end
	end)

	--Fetch preset files from the upstream repo; download any that are missing locally or whose size differs.
	asyncDownloadFile(
		"https://api.github.com/repos/koryboc/CP2077-TPPCamToolkit/contents/ThirdPersonVehicleCameraTool/presets",
		"update.json",
		"application/json; charset=utf-8",
		function(e)
			local files = json.decode(e)
			for _, entry in ipairs(files) do
				local type = entry.type
				if not type and type ~= "file" then goto continue end

				local file = entry.name
				if not file or not hasLuaExt(file) then goto continue end

				local path = getPresetFilePath(file, 2)
				if fileExists(path) then
					local size = entry.size
					if not size then goto continue end

					local mismatch = false
					local handle = io.open(path, "rb")
					if handle then
						local length = handle:seek("end")
						handle:close()
						mismatch = size ~= length
					end

					if not mismatch then goto continue end
				end

				local url = entry.download_url
				if not url then goto continue end
				asyncDownloadFile(url, path, "text/plain; charset=utf-8", function(_)
					logF(DevLevels.ALERT, LogLevels.INFO, 0, format("UPDATED: %s", path))
				end)

				::continue::
			end
		end)

	--Load all saved data from disk; apply preset only if the player is in a vehicle.
	onInit()

	--Set FOV limits from user settings.
	local settings = getUserSettingsOption("/graphics/basic", "FieldOfView")
	if isTableValid(settings) then
		local fov = deep(config.options, "fov")
		local min = settings.MinValue ---@cast min number
		local max = settings.MaxValue ---@cast max number
		if state.isFovControlAvailable then
			fov.Min = changeFovFormat(min, true)
			fov.Max = changeFovFormat(max, true)
		else
			fov.Min = math.min(30, math.max(fov.Min, min / 3.5))
			fov.Max = math.max(120, math.min(fov.Max, max + 10))
		end
	end

	--When the player enters a vehicle. This event also fires
	--every few seconds for no apparent reason, so it's essential
	--to ensure the code runs only once when entering a vehicle.
	Observe("VehicleComponent", "OnMountingEvent", function()
		if not state.isModEnabled or not isVehicleMounted() or isCachePopulated() then
			return
		end
		logIf(DevLevels.ALERT, LogLevels.INFO, 0x0f9b, Text.LOG_EVNT_MNT)
		updateAdvancedConfigData()
		updateConfigData()
		applyPreset()
	end)

	--When the player unmounts from a vehicle, reset to default camera offsets.
	Observe("VehicleComponent", "OnUnmountingEvent", function()
		if isVehicleMounted() then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x0f9b, Text.LOG_EVNT_UMNT_FAIL)
			return
		end
		onUnmount()
	end)

	--When the game returns to the main menu, ensure any active vehicle camera presets are reset.
	Observe("QuestTrackerGameController", "OnUninitialize", function() onUnmount() end)

	--While the loading screen is active, but also triggers
	--once when the user confirms it at the end with a key press.
	Observe("LoadingScreenProgressBarController", "SetProgress", function(_, progress)
		gui.isOverlayLocked = progress < 1.0 --1.0 only on keyboard-confirmation.
		if not state.isModEnabled then return end
		if gui.isOverlayLocked then
			backupDevMode = backupDevMode or state.devMode
			state.devMode = DevLevels.DISABLED
			config.isOpen = false
			config.isAdvancedOpen = false
			explorer.isOpen = false
			return
		end
		gui.isOverlaySuppressed = false
		if backupDevMode ~= nil then
			state.devMode = backupDevMode
			backupDevMode = nil
		end
	end)

	--When a non-keyboard-confirmed loading screen finishes.
	Observe("FastTravelSystem", "OnLoadingScreenFinished", function(_, finished)
		if not finished then return end
		gui.isOverlayLocked = false
		if backupDevMode ~= nil then
			state.devMode = backupDevMode
			backupDevMode = nil
		end
	end)

	--When control over the player character is gained (e.g. after loading a save).
	Observe("PlayerPuppet", "OnTakeControl", function(self)
		if not state.isModEnabled or gui.isOverlayLocked then return end

		local hash = tonumber(self:GetEntityID().hash)
		if hash ~= 1 then return end

		onUnmount(true)

		local deadline = 18 --Prevents an infinite loop, even though it's very unlikely.
		asyncRepeat(0.3, function(id)
			if not state.isModEnabled then
				asyncStop(id)
				return
			end

			if not Game.GetPlayer() then return end --Outdated CET.

			if deadline > 0 and not isVehicleMounted() then
				deadline = deadline - 1
				return
			end

			asyncStop(id)
			applyPreset()
		end)
	end)

	--Registers menu event observers and maps them to GUI state updates.
	local function suppressOverlay()
		gui.isOverlaySuppressed = true
		logIf(DevLevels.FULL, LogLevels.INFO, 0x60b9, Text.LOG_MENU_SUPPRESS)
	end

	local function releaseOverlay()
		gui.isOverlaySuppressed = false
		logIf(DevLevels.FULL, LogLevels.INFO, 0x60b9, Text.LOG_MENU_RELEASE)
	end

	local function autoToggleOverlay(a, b)
		gui.isOverlaySuppressed = not isBoolean(b) and a or b
		logIf(DevLevels.FULL, LogLevels.INFO, 0x60b9, Text.LOG_MENU_TOGGLE)
	end

	local function resetMetrics()
		gui.forceMetricsReset = true
		config.isOpen = false
		setCache(0xcb3d, nil) --Clear `onDraw` cache.
		logIf(DevLevels.FULL, LogLevels.INFO, 0x60b9, Text.LOG_MENU_RESET)
	end

	local menuObservers = {
		[suppressOverlay] = {
			OnEnterScenario  = {
				"MenuScenario_ArcadeMinigame",
				"MenuScenario_BenchmarkResults",
				"MenuScenario_CharacterCustomization",
				"MenuScenario_CharacterCustomizationMirror",
				"MenuScenario_NetworkBreach",
				"MenuScenario_PreGameSubMenu"
			},
			OnLeaveScenario  = "MenuScenario_Idle",
			OnSelectMenuItem = "MenuScenario_HubMenu",
			OnLoadGame       = "MenuScenario_SingleplayerMenu",
			OnShow           = "gameuiPhotoModeMenuController"
		},
		[releaseOverlay] = {
			OnLeaveScenario = "MenuScenario_BaseMenu",
			OnCloseHubMenu  = "MenuScenario_HubMenu",
			OnHide          = "gameuiPhotoModeMenuController"
		},
		[autoToggleOverlay] = {
			OnIsActiveUpdated           = "BraindanceGameController",
			OnQuickHackUIVisibleChanged = "HUDManager"
		},
		[resetMetrics] = {
			GoBack = {
				"MenuScenario_PauseMenu",
				"MenuScenario_DeathMenu"
			},
			OnSettingsBack = "MenuScenario_Settings"
		}
	}
	for handler, events in pairs(menuObservers) do
		for event, scenarios in pairs(events) do
			scenarios = isTable(scenarios) and scenarios or { scenarios } ---@cast scenarios table
			for _, scenario in ipairs(scenarios) do
				Observe(scenario, event, handler)
			end
		end
	end

	--Initializes the Native Settings UI addon.
	local threshold = 0
	asyncRepeat(0.3, function(id)
		threshold = presets.loaderTask.IsActive and 0 or threshold + 1
		if threshold > 5 then
			asyncStop(id)
			setupNativeSettings()
		end
	end)
end)

--Detects when the CET overlay is opened.
registerForEvent("onOverlayOpen", function()
	gui.isOverlayOpen = true
	gui.hasInitialized = {}
end)

--Detects when the CET overlay is closed.
registerForEvent("onOverlayClose", function()
	gui.isOverlayOpen = false
	setCache(0x970b, nil, true) --Clear `openFileExplorerWindow` cache.
	saveGlobalOptions()
	saveAdvancedOptions()
end)

--Display a simple GUI with some options.
registerForEvent("onDraw", function()
	--Notification system (requires at least CET 'v1.35.1').
	if state.isCetTopical and gui.areToastsPending then
		gui.areToastsPending = false
		if isTableValid(gui.toasterBumps) then
			for k, v in pairs(gui.toasterBumps) do
				local toast = ImGui.Toast.new(k, v)
				ImGui.ShowToast(toast)
			end
		end
		gui.toasterBumps = {}
	end

	--Stop when CET overlay is hidden.
	if not gui.isOverlayOpen and state.devMode < DevLevels.OVERLAY then return end

	local isStillVisible = not gui.isOverlayOpen and state.devMode >= DevLevels.OVERLAY

	--Stop if the window should remain visible but the GUI is suppressed.
	if gui.isOverlaySuppressed and isStillVisible then return end

	--If CET is closed but the window should stay visible, apply transparent styling.
	local pushedColors = 0
	if isStillVisible then
		local bl20 = setAlpha(Colors.BLACK, 0x20)
		local bl40 = setAlpha(Colors.BLACK, 0x40)
		local bl60 = setAlpha(Colors.BLACK, 0x60)
		local wh30 = setAlpha(Colors.WHITE, 0x30)
		local wh40 = setAlpha(Colors.WHITE, 0x40)
		pushedColors =
			pushColors(ImGuiCol.Text, Colors.WHITE) +
			pushColors(ImGuiCol.WindowBg, bl60) +
			pushColors(ImGuiCol.FrameBg, bl20) +
			pushColors(ImGuiCol.TitleBg, bl60) +
			pushColors(ImGuiCol.TitleBgActive, bl60) +
			pushColors(ImGuiCol.TableHeaderBg, bl40) +
			pushColors(ImGuiCol.TableBorderStrong, wh40) +
			pushColors(ImGuiCol.TableBorderLight, wh30)
	end

	--Main window begins.
	local flags = gui.isValidating and ImGuiWindowFlags.None or ImGuiWindowFlags.AlwaysAutoResize
	if not gui.isOverlayOpen then
		flags = bor(flags, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoInputs)
	end
	if not ImGui.Begin(Text.GUI_TITLE, flags) then
		popColors(pushedColors)
		return
	end

	--Forces ImGui to rebuild the window on the next frame with fresh metrics.
	if gui.forceMetricsReset then
		gui.forceMetricsReset = false
		popColors(pushedColors)
		ImGui.End()
		return
	end

	--Ensure the window stays fully within the screen boundaries.
	local isValidated, winX, winY, winWidth, winHeight, maxWidth, maxHeight = validateWindowBounds()
	gui.isValidating = isValidated
	if isValidated then
		popColors(pushedColors)
		ImGui.End()
		return
	end

	local isLocked = gui.isOverlayLocked
	if isLocked or presets.loaderTask.IsActive then
		ImGui.BeginDisabled(true)
	else
		--Preventing automatic item selection.
		if not gui.hasInitialized[Text.GUI_TITLE] then
			gui.hasInitialized[Text.GUI_TITLE] = true
			ImGui.SetKeyboardFocusHere(-1)
		end
	end

	--Computes scaled layout values.
	local scale = ImGui.GetFontSize() / 18
	local contentMinWidth = floor(240 * scale)
	local buttonWidth = floor(192 * scale)
	local buttonHeight = floor(24 * scale)
	local rowHeight = floor(28 * scale)
	local heightPadding = floor(4 * scale)
	local halfHeightPadding = floor(2 * scale)
	local doubleHeightPadding = floor(8 * scale)

	local style = ImGui.GetStyle()
	local itemSpacing = style.ItemSpacing.x
	local sbarWidth = style.ScrollbarSize

	local contentWidth = ImGui.GetContentRegionAvail()
	local halfContentWidth = floor(contentWidth * 0.5)
	halfContentWidth = math.min(halfContentWidth, ceil(abs(halfContentWidth - (itemSpacing * 0.5))))

	if not gui.isPaddingLocked then
		local relativePadding = (contentWidth - contentMinWidth) * 0.5 + (22 * scale) - itemSpacing
		gui.paddingWidth = floor(math.max(16 * scale, relativePadding))
	end
	local controlPadding = gui.paddingWidth

	--Set Minimum window width.
	ImGui.Dummy(contentMinWidth, heightPadding)

	--Create top controls only if CET is open.
	if not isStillVisible then
		--Warning for outdated game or runtime.
		if state.devMode <= DevLevels.DISABLED and (not state.isGameCompatible or not state.isCetCompatible) then
			local gameVer, cetVer = serialize(state.gameVersion), serialize(state.cetVersion)
			ImGui.Dummy(0, 0)
			ImGui.SameLine()
			ImGui.PushStyleColor(ImGuiCol.Text, setAlpha(Colors.GARNET, 0xff))
			addTextCenterWrap(format(Text.GUI_COMP_WARN, gameVer, cetVer), contentWidth)
			ImGui.PopStyleColor()
			ImGui.Dummy(0, doubleHeightPadding)
		end

		--Checkbox to toggle mod functionality and handle enable/disable logic.
		ImGui.Dummy(controlPadding, 0)
		ImGui.SameLine()
		local isEnabled = ImGui.Checkbox(Text.GUI_MOD_TOGGLE, state.isModEnabled)
		addTooltip(scale, Text.GUI_MOD_TOGGLE_TIP)
		if isEnabled ~= state.isModEnabled then
			state.isModEnabled = isEnabled
			if isEnabled then
				onInit()
				logF(DevLevels.ALERT, LogLevels.INFO, 0xcb3d, Text.LOG_MOD_ON)
			else
				asyncStop(true)

				onUnmount(true)
				onShutdown()
				purgePresets()

				editor.bundles = {}
				presets.usage = {}
				state.devMode = DevLevels.DISABLED

				logF(DevLevels.ALERT, LogLevels.INFO, 0xcb3d, Text.LOG_MOD_OFF)

				resetCache(false)
				resetCache(true)
			end
			setupNativeSettings()
		end
		ImGui.Dummy(0, halfHeightPadding)
		if not state.isModEnabled then
			--Mod is disabled — nothing left to add.
			popColors(pushedColors)
			ImGui.End()
			return
		end

		--Button to open the Global Settings window.
		ImGui.Dummy(controlPadding, 0)
		ImGui.SameLine()
		if ImGui.Button(Text.GUI_SETTINGS, buttonWidth, buttonHeight) then
			config.isOpen = true
		end
		addTooltip(scale, Text.GUI_SETTINGS_TIP)
		ImGui.Dummy(0, halfHeightPadding)
		local isAdvancedOpening =
			openGlobalOptionsWindow(
				scale,
				winX,
				winY,
				winWidth,
				winHeight,
				halfContentWidth,
				heightPadding,
				buttonHeight,
				sbarWidth
			)
		openAdvancedOptionsWindow(scale, isAdvancedOpening, maxWidth, maxHeight)

		--Slider to set the developer mode level.
		local sliderWidth = floor(90 * scale)
		ImGui.Dummy(controlPadding, 0)
		ImGui.SameLine()
		ImGui.SetNextItemWidth(sliderWidth)
		local devMode = ImGui.SliderInt(Text.GUI_CREAT_MODE, state.devMode, DevLevels.DISABLED, DevLevels.FULL)
		if ImGui.IsItemHovered() and ImGui.IsMouseClicked(1) then
			devMode = DevLevels.DISABLED
		end
		if devMode ~= state.devMode then
			state.devMode = clamp(devMode, DevLevels.DISABLED, DevLevels.FULL)
			if state.devMode == DevLevels.DISABLED then
				gui.forceMetricsReset = true
				resetCache(true)
			end
		end
		gui.isPaddingLocked = ImGui.IsItemActive()
		addTooltip(scale, Text.GUI_CREAT_MODE_TIP)

		if state.devMode >= DevLevels.RULER then
			ImGui.Dummy(0, halfHeightPadding)
			ImGui.Dummy(controlPadding, 0)
			ImGui.SameLine()
			ImGui.SetNextItemWidth(sliderWidth)
			local rulerOffset = ImGui.SliderInt(Text.GUI_RULER_OFFSET, gui.rulerOffset, -500, 500)
			if ImGui.IsItemHovered() and ImGui.IsMouseClicked(1) then
				rulerOffset = 0
			end
			if not equals(rulerOffset, gui.rulerOffset) then
				gui.rulerOffset = clamp(rulerOffset, -500, 500)
			end
			addTooltip(scale, Text.GUI_RULER_OFFSET_TIP)
		end

		--The button that reloads all presets.
		if state.devMode > DevLevels.DISABLED then
			ImGui.Dummy(0, halfHeightPadding)
			ImGui.Dummy(controlPadding, 0)
			ImGui.SameLine()
			if ImGui.Button(Text.GUI_PSETS_RLD, buttonWidth, buttonHeight) then
				editor.bundles = {}
				resetCache()
				restoreAllPresets()
				loadPresets(true)
				applyPreset()
			end
			addTooltip(scale, Text.GUI_PSETS_RLD_TIP)
		end

		ImGui.Dummy(0, doubleHeightPadding)
	end

	--Draw ruler if enabled.
	if state.devMode >= DevLevels.RULER then
		drawRuler(scale, maxWidth, maxHeight)
	end

	--Table showing vehicle name, camera ID and more — if certain conditions are met.
	local cache = getCache(0xcb3d) or {}
	local vehicle, name, appName, id, key, displayName, status, statusText, camHeight, activeCam, activeCamText, isCloserBikes
	local steps = {
		function()
			return not isLocked and state.devMode > DevLevels.DISABLED
		end,
		function()
			vehicle = getMountedVehicle()
			return vehicle ~= nil
		end,
		function()
			name = getVehicleName()
			if name ~= nil then return true end

			log(LogLevels.ERROR, 0xcb3d, Text.LOG_VEH_NAME_MISS)
			return false
		end,
		function()
			appName = getVehicleAppearanceName()
			if appName ~= nil then return true end

			log(LogLevels.ERROR, 0xcb3d, Text.LOG_APP_NOT_FOUND)
			return false
		end,
		function()
			id = getVehicleCameraID()
			if id ~= nil then return true end

			log(LogLevels.ERROR, 0xcb3d, Text.LOG_CAM_ID_MISS)
			addText(Text.LOG_CAM_ID_MISS, Colors.GARNET, halfHeightPadding, contentWidth, itemSpacing)
			return false
		end,
		function()
			key = cache.key
			if key ~= nil then return true end

			key = name ~= appName and findPresetKey(name, appName) or findPresetKey(name) or name
			cache.key = key
			setCache(0xcb3d, cache)
			return key ~= nil
		end,
		function()
			displayName = cache.displayName
			if displayName ~= nil then return true end

			displayName = getVehicleDisplayName() or Text.GUI_UNKNOWN
			cache.displayName = displayName
			setCache(0xcb3d, cache)
			return true
		end,
		function()
			status = cache.status
			if status ~= nil then return true end

			status = getVehicleStatus()
			cache.status = status
			setCache(0xcb3d, cache)
			return true
		end,
		function()
			statusText = cache.statusText
			if statusText ~= nil then return true end

			statusText = ({
				[0] = Text.GUI_EDIT_VAL_STATE_0,
				[1] = Text.GUI_EDIT_VAL_STATE_1,
				[2] = Text.GUI_EDIT_VAL_STATE_2
			})[status] or Text.GUI_UNKNOWN
			cache.statusText = statusText
			setCache(0xcb3d, cache)
			return true
		end,
		function()
			camHeight = cache.camHeight
			if camHeight ~= nil then return true end

			local height = getUserSettingsCameraHeight()
			camHeight = equals(height, "Low") and Text.GUI_EDIT_VAL_CAMH_0 or Text.GUI_EDIT_VAL_CAMH_1
			cache.camHeight = camHeight
			setCache(0xcb3d, cache)
			return true
		end,
		function()
			local player = Game.GetPlayer()
			local manager = player and player:FindVehicleCameraManager()
			local active = manager and manager:GetActivePerspective()
			activeCam = active and tonumber(Game.EnumValueFromString("vehicleCameraPerspective", active.value)) or -1
			return true
		end,
		function()
			local text = ({
				[0] = Text.GUI_EDIT_VAL_CAMA_0,
				[1] = Text.GUI_EDIT_VAL_CAMA_1,
				[2] = Text.GUI_EDIT_VAL_CAMA_2,
				[3] = Text.GUI_EDIT_VAL_CAMA_3,
				[4] = Text.GUI_EDIT_VAL_CAMA_4,
				[5] = Text.GUI_EDIT_VAL_CAMA_5,
				[6] = Text.GUI_EDIT_VAL_CAMA_6,
			})[activeCam] or Text.GUI_UNKNOWN
			activeCamText = activeCam == 0 and text or format(text, camHeight)
			return true
		end,
		function()
			isCloserBikes = cache.isCloserBikes
			if isCloserBikes ~= nil then return true end

			cache.isCloserBikes = get(config.options, 1, "closerBikes", "Value") > 1
			isCloserBikes = cache.isCloserBikes
			setCache(0xcb3d, cache)
			return true
		end
	}

	local failed = false
	for _, step in ipairs(steps) do
		if not step() then
			failed = true
			break
		end
	end

	if failed then
		if state.devMode > DevLevels.DISABLED then
			if not isLocked and not vehicle then
				addText(Text.GUI_STATE_NO_VEH, Colors.CARAMEL, halfHeightPadding, contentWidth, itemSpacing)
			end
		elseif not isLocked and isVehicleMounted() then
			local text, color
			if presets.isAnyActive then
				text = Text.GUI_STATE_PSET_ON
				color = Colors.FIR
			else
				text = Text.GUI_STATE_PSET_OFF
				color = Colors.CARAMEL
			end
			addText(text, color, halfHeightPadding, contentWidth, itemSpacing)
		end

		--Don't create a Preset Explorer button if CET isn't open.
		if isStillVisible then
			popColors(pushedColors)
			ImGui.End()
			return
		end

		--Button to open the Preset Explorer.
		ImGui.Separator()
		ImGui.Dummy(0, heightPadding)
		ImGui.Dummy(controlPadding, 0)
		ImGui.SameLine()
		local isExplorerOpening = false
		if ImGui.Button(Text.GUI_PSET_EXPL, buttonWidth, buttonHeight) then
			explorer.isOpen = not explorer.isOpen
			isExplorerOpening = explorer.isOpen
		end
		addTooltip(scale, Text.GUI_PSET_EXPL_TIP)
		ImGui.Dummy(0, halfHeightPadding)

		if isLocked then
			ImGui.EndDisabled()
		end

		--Main window is done.
		popColors(pushedColors)
		ImGui.End()

		--Opens the Preset Explorer window when button triggered.
		openFileExplorerWindow(
			scale,
			isExplorerOpening,
			winX,
			winY,
			winWidth,
			winHeight,
			maxHeight,
			halfHeightPadding,
			buttonHeight,
			itemSpacing)
		return
	end

	local bundle = getEditorBundle(name, appName, id, key) ---@cast bundle IEditorBundle
	if not isTableValid(bundle) then
		--Nothing else to display.
		popColors(pushedColors)
		ImGui.End()
	end
	editor.lastBundle = bundle

	local flux = bundle.Flux ---@cast flux IEditorPreset
	local pivot = bundle.Pivot ---@cast pivot IEditorPreset
	local finale = bundle.Finale ---@cast finale IEditorPreset
	local nexus = bundle.Nexus ---@cast nexus IEditorPreset
	local tasks = bundle.Tasks ---@cast tasks IEditorTasks
	if not areTableValid(flux, pivot, finale, nexus, tasks) then
		--No further controls required.
		popColors(pushedColors)
		ImGui.End()
	end

	--Show a warning if a bike preset cannot be edited.
	if not isStillVisible and isCloserBikes and equalsAny(id, "2w_Preset", "Brennan_Preset") then
		ImGui.PushStyleColor(ImGuiCol.Text, setAlpha(Colors.GARNET, 0xff))
		addTextCenterWrap(Text.GUI_EDIT_CB_WARN, contentWidth)
		ImGui.PopStyleColor()
		ImGui.Dummy(0, doubleHeightPadding)

		isLocked = true
		ImGui.BeginDisabled(true)
	end

	--Display some vehicle information.
	local presetName = (flux.Name ~= key or presetExists(key, id)) and flux.Name or id
	if ImGui.BeginTable("PresetInfo", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("\u{f11be}", ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn("\u{f09a8}", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		local equNames = name == appName
		local customID = getCustomVehicleCameraID()
		local customIdText = isStringValid(customID) and format("%s : %s", customID, activeCamText) or nil
		local baseIdText = customIdText ~= nil and id or format("%s : %s", id, activeCamText)
		local rows = {
			{ label = "\u{f0208}", tip = Text.GUI_EDIT_LABL_DNAME_TIP,  value = displayName },
			{ label = "\u{f1975}", tip = Text.GUI_EDIT_LABL_STATUS_TIP, value = statusText },
			{ label = "\u{f1b8d}", tip = Text.GUI_EDIT_LABL_VEH_TIP,    value = name },
			{ label = "\u{f0301}", tip = Text.GUI_EDIT_LABL_APP_TIP,    value = appName,    isDisabled = equNames },
			{ label = "\u{f0567}", tip = Text.GUI_EDIT_LABL_CAMID_TIP,  value = baseIdText, isDisabled = id == customID },
			{
				label      = "\u{f0569}",
				tip        = Text.GUI_EDIT_LABL_CCAMID_TIP,
				value      = customIdText,
				valTip     = Text.GUI_EDIT_VAL_CCID_TIP,
				isCustomID = customIdText ~= nil
			},
			{
				label      = "\u{f1668}",
				tip        = Text.GUI_EDIT_LABL_PSET_TIP,
				value      = presetName,
				valTip     = equNames and Text.GUI_EDIT_VAL_PSET_TIP2 or Text.GUI_EDIT_VAL_PSET_TIP1,
				isDisabled = isStillVisible and presetName == id,
				isEditable = true
			}
		}

		local maxInputWidth = floor(math.max(16, (contentWidth - 38)) * scale)
		for _, row in ipairs(rows) do
			if row.isDisabled or not areString(row.label, row.value) then goto continue end

			ImGui.TableNextRow(0, rowHeight)
			ImGui.TableNextColumn()

			alignNext(rowHeight)
			ImGui.Text(row.label)
			addTooltip(scale, row.tip)

			ImGui.TableNextColumn()

			if row.isCustomID then
				alignNext(rowHeight)
				ImGui.Text(row.value)

				local tip = cache.customIDTip
				if not tip then
					local camMap = getVehicleCameraMap()
					if isTableValid(camMap) then ---@cast camMap table<string, string>
						tip = split(row.valTip, "|") or {}
						for _, v in ipairs(CameraData.Levels) do
							local cam = camMap[v]
							insert(tip, v .. ":")
							insert(tip, cam and cam or "\u{f0026} " .. Text.GUI_NONE)
						end
						cache.customIDTip = tip
						setCache(0xcb3d, cache)
					end
				end
				if isTableValid(tip) then
					addTooltip(nil, tip)
				end
			elseif row.isEditable then
				local color
				if flux.Name ~= flux.Key then
					color = Colors.GARNET
				elseif isStillVisible and tasks.Restore then
					color = Colors.OLIVE
				elseif isStillVisible and tasks.Save then
					color = Colors.CARAMEL
				else
					color = Colors.FIR
				end
				color = row.value ~= id and pushColors(ImGuiCol.FrameBg, color) or 0

				local namWidth = math.min(ImGui.CalcTextSize(name), 302)
				local appWidth = math.min(ImGui.CalcTextSize(appName), 302)
				local width = clamp(appWidth, namWidth, maxInputWidth) + doubleHeightPadding
				local maxLen = math.max(#name, #appName) + 1

				ImGui.SetNextItemWidth(width)
				local recent, changed = ImGui.InputText("##FileName", row.value, maxLen)
				if ImGui.IsItemHovered() and ImGui.IsMouseClicked(1) then
					recent = finale.Name
					changed = true
				end
				if changed and recent then
					local trimVal = trimLuaExt(recent)
					if trimVal == id then
						trimVal = ""
					end
					if flux.Name ~= trimVal then
						if #trimVal > 0 then
							flux.Name = trimVal
							tasks.Rename = true
						else
							flux.Key = key
							flux.Name = key
						end
					end
				end

				popColors(color)

				cache.renameTip = cache.renameTip or {}
				local tipKey = equNames and name or appName
				local tip = cache.renameTip[tipKey]
				if not tip then
					if equNames then
						tip = format(
							row.valTip,
							color == Colors.CARAMEL and flux.Name or key,
							name,
							chopUnderscoreParts(name)
						)
					else
						tip = format(
							row.valTip,
							color == Colors.CARAMEL and flux.Name or key,
							name,
							appName,
							chopUnderscoreParts(name),
							chopUnderscoreParts(appName)
						)
					end
					cache.renameTip[tipKey] = tip
					setCache(0xcb3d, cache)
				end
				addTooltip(scale, tip)
			else
				alignNext(rowHeight)

				local rawValue = tostring(row.value or Text.GUI_UNKNOWN)
				local value = rawValue
				local maxSize = floor(290 * scale)

				if ImGui.CalcTextSize(value) > maxSize then
					repeat
						value = value:sub(1, -2)
					until ImGui.CalcTextSize(value) <= maxSize
					value = value .. "..."
				end

				ImGui.Text(value)
				if rawValue ~= value then
					local newTip = format("%s\n%s", capitalizeWords(row.tip), rawValue)
					addTooltip(scale, newTip)
				else
					addTooltip(scale, row.valTip or row.tip)
				end
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if tasks.Rename then
		tasks.Rename = finale.IsPresent and flux.Name ~= finale.Name
		flux.Key = flux.Name
	end

	--Camera preset editor allowing adjustments to Angle, X, Y, Z
	--coordinates, and Distance — if certain conditions are met.
	if ImGui.BeginTable("PresetEditor", 6, ImGuiTableFlags.Borders) then
		local headers = {
			"\u{f066a}", --Levels
			"\u{f10f3}\u{f0aee}", --Angles
			"\u{f0d4c}\u{f0b05}", --X-axis
			"\u{f0d51}\u{f0b06}", --Y-axis
			"\u{f0d55}\u{f0b07}", --Z-axis
			"\u{f054e}\u{f0af1}" --Distance
		}

		for i, header in ipairs(headers) do
			local flag = i < 3 and ImGuiTableColumnFlags.WidthFixed or ImGuiTableColumnFlags.WidthStretch
			local head = header
			if i > 2 and #head < 12 then
				local pad = 12 - #head
				local left = floor(pad / 2)
				local right = pad - left
				head = rep(" ", left) .. head .. rep(" ", right)
			end
			ImGui.TableSetupColumn(head, flag, -1)
		end

		ImGui.TableHeadersRow()

		local rows = {
			{ label = "\u{f0623}", tip = Text.GUI_EDIT_LABL_CAM_1_TIP, isActive = equalsAny(activeCam, 1, 4), isCombat = activeCam == 4 },
			{ label = "\u{f0622}", tip = Text.GUI_EDIT_LABL_CAM_2_TIP, isActive = equalsAny(activeCam, 2, 5), isCombat = activeCam == 5 },
			{ label = "\u{f0621}", tip = Text.GUI_EDIT_LABL_CAM_3_TIP, isActive = equalsAny(activeCam, 3, 6), isCombat = activeCam == 6 }
		}

		local tips = {
			Text.GUI_EDIT_VAL_A_TIP,
			Text.GUI_EDIT_VAL_X_TIP,
			Text.GUI_EDIT_VAL_Y_TIP,
			Text.GUI_EDIT_VAL_Z_TIP,
			Text.GUI_EDIT_VAL_D_TIP
		}

		for i, row in ipairs(rows) do
			local isGameDefault = id == presetName
			local level = PresetInfo.Levels[i]
			local color

			ImGui.TableNextRow(0, rowHeight)
			ImGui.TableNextColumn()

			alignNext(rowHeight)

			if isGameDefault then
				color = not isStillVisible and getStyleColor(ImGuiCol.TabActive)
			elseif isStillVisible and tasks.Save then
				color = tasks.Restore and Colors.OLIVE or Colors.CARAMEL
			else
				color = Colors.FIR
			end
			color = row.isActive and color and pushColors(ImGuiCol.Text, color) or 0

			ImGui.Text(row.isActive and (row.isCombat and "\u{f0703}" or "\u{f1879}") or row.label)
			popColors(color)
			addTooltip(scale, row.tip)

			for j, field in ipairs(PresetInfo.Offsets) do
				local defVal = get(nexus.Preset, 0, level, field)
				local curVal = get(flux.Preset, defVal, level, field)
				local speed = pick(j, 1, 1e-2)
				local minVal = pick(j, -45, -5, -10, 0, -3.8)
				local maxVal = pick(j, 90, 5, 10, 32, 24)
				local precision = pick(j, "%.0f", "%.2f")
				local origVal
				color = nil

				ImGui.TableNextColumn()

				if not equals(curVal, defVal) then
					if isGameDefault then
						color = Colors.GARNET
					elseif isStillVisible and tasks.Save then
						color = Colors.CARAMEL
					else
						color = Colors.FIR
					end
				end
				color = color and pushColors(ImGuiCol.FrameBg, color) or 0

				ImGui.SetNextItemWidth(-1)
				local recent = ImGui.DragFloat(format("##%s_%s", level, field), curVal, speed, minVal, maxVal, precision)
				if ImGui.IsItemHovered() and ImGui.IsMouseClicked(1) then
					origVal = get(pivot.Preset, defVal, level, field)
					recent = origVal
				end
				if not equals(recent, curVal) then
					recent = clamp(recent, minVal, maxVal)
					deep(flux.Preset, level)[field] = recent
					tasks.Validate = true
				end

				popColors(color)

				local tip = tips[j]
				if tip then
					origVal = origVal or get(pivot.Preset, defVal, level, field)
					addTooltip(nil, split(format(tip, defVal, minVal, maxVal, origVal), "|"))
				end
			end
		end

		ImGui.EndTable()
		ImGui.Dummy(0, halfHeightPadding)
	end

	--Create bottom controls only if CET is open.
	if isStillVisible then
		popColors(pushedColors)
		ImGui.End()
		return
	end

	if tasks.Validate then
		tasks.Validate = false
		flux.Token = getEditorPresetToken(flux.Preset)
		tasks.Apply = flux.Token ~= pivot.Token
		tasks.Save = flux.Token ~= finale.Token
		tasks.Restore = tasks.Save and flux.Token == nexus.Token
	end

	key = validatePresetKey(name, appName, key or name, flux.Name)
	if key ~= flux.Name then
		--No longer identical to `flux.Key`; triggers red highlight in UI.
		flux.Name = key
	end

	--Button to apply previously configured values in-game.
	local color = tasks.Restore and Colors.OLIVE or Colors.CARAMEL
	local pushed = tasks.Apply and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_EDIT_APPLY, halfContentWidth, buttonHeight) then
		--Always applies on user action — even if unnecessary.
		applyEditorPreset(key, flux, pivot, tasks)
	end
	popColors(pushed)
	addTooltip(scale, Text.GUI_EDIT_APPLY_TIP)
	ImGui.SameLine()

	--Button in same line to save configured values to a file for future automatic use.
	local saveConfirmed = false
	pushed = (tasks.Save or tasks.Rename) and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_EDIT_SAVE, halfContentWidth, buttonHeight) then
		if presetFileExists(finale.Name) then
			editor.isOverwriteConfirmed = true
			ImGui.OpenPopup(key)
		else
			saveConfirmed = true
		end
	end
	popColors(pushed)
	addTooltip(scale, format(tasks.Restore and Text.GUI_EDIT_REST_TIP or Text.GUI_EDIT_SAVE_TIP, key))

	if editor.isOverwriteConfirmed then
		local curPath = getPresetFilePath(finale.Key, status)
		local newPath = getPresetFilePath(key, status)
		local newExists = fileExists(newPath)
		local isRename = tasks.Rename and fileExists(curPath)
		local message
		if isRename then
			message = format(newExists and Text.GUI_EDIT_MVO_POP or Text.GUI_EDIT_MV_POP, curPath, newPath)
		else
			message = format(newExists and Text.GUI_EDIT_OWR_POP or Text.GUI_EDIT_CPY_POP, newPath)
		end
		local pressed
		if isRename then
			pressed = addPopupWithButtons(key, message, scale, Text.GUI_MOVE, Text.GUI_COPY, Text.GUI_Cancel, Colors.CARAMEL, Colors.OLIVE)
		else
			pressed = addPopupWithButtons(key, message, scale, Colors.CARAMEL)
		end
		if pressed ~= nil then
			editor.isOverwriteConfirmed = false
			if pressed == 1 then
				saveConfirmed = true
			elseif pressed == 2 and isRename then
				tasks.Rename = false
				saveConfirmed = true
			else
				saveConfirmed = false
			end
		end
	end
	if saveConfirmed then
		saveConfirmed = false

		--Apply is always performed on user request, even if redundant.
		applyEditorPreset(key, flux, pivot, tasks)

		--Saving is always performed, even if no changes were made in the editor. The
		--user could theoretically change preset files manually outside the game, and
		--the mod wouldn't detect that at runtime. It would be problematic if saving
		--were blocked just because the mod assumes there are no changes.
		saveEditorPreset(key, flux, finale, tasks, status)
	end
	ImGui.Dummy(0, heightPadding)

	if isLocked then
		ImGui.EndDisabled()
	end

	--Button to open the Preset Explorer.
	ImGui.Separator()
	ImGui.Dummy(0, halfHeightPadding)
	local isExplorerOpening = false
	if ImGui.Button(Text.GUI_PSET_EXPL, contentWidth, buttonHeight) then
		explorer.isOpen = not explorer.isOpen
		isExplorerOpening = explorer.isOpen
	end
	addTooltip(scale, Text.GUI_PSET_EXPL_TIP)
	ImGui.Dummy(0, halfHeightPadding)

	--Well done.
	popColors(pushedColors)
	ImGui.End()

	--Opens the Preset Explorer window when toggled.
	openFileExplorerWindow(
		scale,
		isExplorerOpening,
		winX,
		winY,
		winWidth,
		winHeight,
		maxHeight,
		halfHeightPadding,
		buttonHeight,
		itemSpacing
	)
end)

--Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", onShutdown)

---Called every frame to update active timers.
---Processes all running async timers and executes their callbacks when their interval elapses.
registerForEvent("onUpdate", function(deltaTime)
	if not async.isActive then return end

	for id, timer in pairs(async.timers) do
		if not timer.IsActive then goto continue end

		timer.Time = timer.Time - deltaTime
		if timer.Time > 0 then goto continue end

		timer.Callback(id)
		timer.Time = timer.Interval

		::continue::
	end
end)

--#endregion
