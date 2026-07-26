--[[
==============================================
This file is distributed under the MIT License
==============================================

Standard API Definitions for IntelliSense

All definitions included here are used in the
main code.

These definitions have no functionality. They
are already provided by Lua or CET and exist
only for documentation and coding convenience.

Filename: api.lua
Version: 2026-07-26, 16:04 UTC+01:00 (MEZ)

Copyright (c) 2026, Roy Bock aka koryboc
All rights reserved.
______________________________________________
--]]


---Provides functions to create graphical user interface elements within the Cyber Engine Tweaks overlay.
---@class ImGui
---@field Begin fun(title: string, flags?: integer): boolean # Begins a new ImGui window with optional flags. Must be closed with `ImGui.End()`. Returns true if the window is open and should be rendered.
---@field Begin fun(title: string, open: boolean, flags?: integer): boolean # Begins a new ImGui window. Returns true if the window is open and should be rendered. If `open` is false, the window is not shown.
---@field End fun() # Ends the creation of the current ImGui window. Must always be called after `ImGui.Begin()`.
---@field CollapsingHeader fun(label: string, flags?: integer): boolean # Creates a collapsible header that can be opened or closed. Returns true if the header is open.
---@field BeginChild fun(id: string, width?: number, height?: number, border?: boolean): boolean # Begins a child window or region inside the current window. Must be closed with `ImGui.EndChild()`. Returns true if the child window is visible and should be rendered.
---@field EndChild fun() # Ends the creation of a child window started with `ImGui.BeginChild()`.
---@field Separator fun() # Draws a horizontal line to visually separate UI sections.
---@field Dummy fun(width: number, height: number) # Creates an invisible element of specified width and height, useful for spacing.
---@field SameLine fun(offsetX?: number, spacing?: number) # Places the next UI element on the same line. Optionally adds horizontal offset and spacing.
---@field Text fun(text: string) # Displays text within the current window or tooltip.
---@field GetTextLineHeight fun(): number # Returns the height in pixels of a single line of text in the current font.
---@field PushTextWrapPos fun(wrapLocalPosX?: number) # Sets a maximum width (in pixels) for wrapping text. Applies to subsequent Text elements until `PopTextWrapPos()` is called. If no value is provided, wraps at the edge of the window.
---@field PopTextWrapPos fun() # Restores the previous text wrapping position. Should be called after `PushTextWrapPos()` to reset wrapping behavior.
---@field Button fun(label: string, width?: number, height?: number): boolean # Creates a clickable button with optional width and height. Returns true if the button was clicked.
---@field Checkbox fun(label: string, value: boolean): (boolean, boolean) # Creates a toggleable checkbox. Returns `changed` (true if state has changed) and `value` (the new state).
---@field InputText fun(label: string, value: string, maxLength?: integer): (string, boolean) # Creates a single-line text input field. Returns a tuple: the `new value` and `changed` (true if the text was edited).
---@field SliderInt fun(label: string, value: integer, min: integer, max: integer): integer # Creates an integer slider. Returns the new `value`.
---@field DragFloat fun(label: string, value: number, speed?: number, min?: number, max?: number, format?: string): number # Creates a draggable float input widget. Allows the user to adjust the value by dragging or with arrow keys. Optional speed, min/max limits, and format string. Returns the updated float value.
---@field BeginCombo fun(label: string, previewValue: string, flags?: integer): boolean # Begins a combo box (drop-down list) with a preview value. Returns true if the combo is open and items should be drawn.
---@field Selectable fun(label: string, selected?: boolean, flags?: integer, sizeX?: number, sizeY?: number): boolean # Creates a selectable item inside a combo or list. Returns true if the item was clicked.
---@field SetItemDefaultFocus fun() # Sets keyboard focus to the most recently added item if no other item is active. Commonly used inside combos or lists.
---@field EndCombo fun() # Ends the current combo box started with `ImGui.BeginCombo()`.
---@field IsItemHovered fun(): boolean # Returns true if the last item is hovered by the mouse cursor.
---@field IsItemActive fun(): boolean # Returns true while the last item is being actively used (e.g., held with mouse or keyboard input).
---@field IsMouseClicked fun(button: integer): boolean # Returns true on the frame when the specified mouse button is pressed. Button indices: 0 = left, 1 = right, 2 = middle.
---@field SetKeyboardFocusHere fun(offset?: integer) # Sets the keyboard focus to the next widget (or `offset` widgets ahead) in the window. Useful to programmatically focus text inputs or other interactive items.
---@field SetNextItemWidth fun(width: number) # Sets a fixed width for the next item (e.g., combo box, slider, or text input). Affects layout and alignment.
---@field BeginTooltip fun() # Begins creating a tooltip. Must be paired with `ImGui.EndTooltip()`.
---@field EndTooltip fun() # Ends the creation of a tooltip. Must be called after `ImGui.BeginTooltip()`.
---@field BeginTable fun(id: string, columns: integer, flags?: integer): boolean # Begins a table with the specified number of columns. Returns true if the table is created successfully and should be rendered.
---@field TableSetupColumn fun(label: string, flags?: integer, init_width_or_weight?: number) # Defines a column in the current table with optional flags and initial width or weight.
---@field TableHeadersRow fun() # Automatically creates a header row using column labels defined by `TableSetupColumn()`. Must be called right after defining the columns.
---@field TableNextRow fun(row_flags?: integer, min_row_height?: number) # Advances to the next row. Optional: row flags and minimum height in pixels.
---@field TableNextColumn fun() # Advances to the next column in the current table row. Resets to column 0 after the last column.
---@field EndTable fun() # Ends the creation of the current table. Must always be called after `ImGui.BeginTable()`.
---@field GetColumnWidth fun(columnIndex?: integer): number # Returns the current width in pixels of the specified column index (default: 0). Only valid when called within an active table.
---@field GetFrameHeight fun(): number # Returns the height of a standard frame (e.g., button, input box) in pixels.
---@field GetContentRegionAvail fun(): number, number # Returns the size of the remaining content region inside the current window, excluding padding. Useful for calculating dynamic layouts or centering elements.
---@field GetScrollMaxY fun(): number # Returns the maximum vertical scroll offset of the current window. If greater than 0, a vertical scrollbar is visible. Useful to determine scroll range and scrollbar visibility.
---@field CalcTextSize fun(text: string): number # Calculates the width of a given text string as it would be displayed using the current font. Returns the width in pixels as a floating-point number.
---@field GetStyle fun(): ImGuiStyle # Returns the current ImGui style object, which contains values for UI layout, spacing, padding, rounding, and more.
---@field GetWindowPos fun(): number, number # Returns the X and Y position of the current window, relative to the screen.
---@field GetWindowSize fun(): number, number # Returns the width and height of the current window in pixels.
---@field SetNextWindowPos fun(x: number, y: number) # Sets the position for the next window before calling `ImGui.Begin()`.
---@field SetNextWindowSize fun(width: number, height: number) # Sets the size for the next window before calling `ImGui.Begin()`.
---@field SetNextWindowSizeConstraints fun(minWidth: number, minHeight: number, maxWidth?: number, maxHeight?: number) # Sets minimum and optional maximum size constraints for the next window. Must be called before `ImGui.Begin()`.
---@field GetCursorPos fun(): number, number # Returns the current cursor position (X, Y) within the window. Can be used to manually position elements.
---@field SetWindowPos fun(x: number, y: number) # Sets the position for the current window.
---@field GetFontSize fun(): number # Returns the height in pixels of the currently used font. Useful for vertical alignment calculations.
---@field GetCursorPosX fun(): number # Returns the current X-position of the cursor within the window. Can be used to place elements precisely.
---@field GetCursorPosY fun(): number # Returns the current Y-position of the cursor within the window. Can be used to place elements precisely.
---@field SetCursorPos fun(x: number, y: number) # Sets the cursor position within the window. Useful for precise manual placement of elements.
---@field SetCursorPosX fun(x: number) # Sets the X-position of the cursor within the window. Useful for manual horizontal positioning of UI elements.
---@field SetCursorPosY fun(y: number) # Sets the Y-position of the cursor within the window. Use to manually position elements vertically.
---@field OpenPopup fun(id: string) # Opens a popup by identifier. Should be followed by `ImGui.BeginPopup()`.
---@field BeginPopup fun(id: string): boolean # Starts a popup window with the given ID. Returns true if it should be drawn.
---@field CloseCurrentPopup fun() # Closes the currently open popup window. Should be called inside the popup itself.
---@field EndPopup fun() # Ends the current popup window. Always call after `BeginPopup()`.
---@field GetStyleColorVec4 fun(idx: integer): number, number, number, number # Retrieves the RGBA components (x=R, y=G, z=B, w=A) of a given style color as floats [0-1].
---@field PushStyleColor fun(idx: integer, color: integer) # Pushes a new color style override for the current ImGui context.
---@field PushStyleVar fun(idx: integer, value: number) # Pushes a single style variable override for the current ImGui context. `idx` is the ImGuiStyleVar enum value (e.g., WindowBorderSize, WindowPadding, ItemSpacing), and `value` is the number to set. Must be paired with `PopStyleVar()` to restore the previous style.
---@field PopStyleColor fun(count?: integer) # Removes one or more pushed style colors from the stack. Default count is 1.
---@field BeginDisabled fun(disabled: boolean) # Begins a block in which all contained UI elements are disabled (grayed out and unclickable) if `disabled` is true. Must be closed with `ImGui.EndDisabled()`.
---@field EndDisabled fun() # Ends a disabled UI block started by `ImGui.BeginDisabled()`. Re-enables UI interaction.
---@field ShowToast fun(toast: ImGui.Toast) # Displays a Toast notification instance immediately.
ImGui = ImGui

---Flags used to configure ImGui window behavior and appearance.
---@class ImGuiWindowFlags
---@field None integer # Default flag value representing no special behavior. The window uses standard behavior with title bar, resizing, moving, and input enabled.
---@field NoTitleBar integer # Disables the window title bar.
---@field NoResize integer # Disables window resizing.
---@field NoMove integer # Disables window moving.
---@field NoCollapse integer # Disables the ability to collapse the window.
---@field AlwaysAutoResize integer # Automatically resizes the window to fit its content each frame.
---@field NoSavedSettings integer # Prevents the window from saving its settings to the .ini file.
---@field NoFocusOnAppearing integer # Prevents the window from taking focus when it appears.
---@field NoBringToFrontOnFocus integer # Prevents the window from being brought to the front when focused.
---@field NoInputs integer # Disables all inputs (mouse, keyboard, etc.) for the window.
ImGuiWindowFlags = ImGuiWindowFlags

---Style variables used to override ImGui layout and appearance settings temporarily.
---@class ImGuiStyleVar
---@field WindowBorderSize integer # Sets the thickness of a window's border in pixels. Can be pushed with `ImGui.PushStyleVar` to override the default border size. Set to 0 to remove the window border.
ImGuiStyleVar = ImGuiStyleVar

---Flags for customizing tree node and collapsing header behavior in ImGui.
---@class ImGuiTreeNodeFlags
---@field DefaultOpen integer # Node is open by default.
ImGuiTreeNodeFlags = ImGuiTreeNodeFlags

---Flags to customize table behavior and appearance.
---@class ImGuiTableFlags
---@field Borders integer # Draws borders between cells.
---@field NoBordersInBody integer # Removes all inner borders between rows and columns in the body of the table (excluding headers). Improves visual minimalism.
---@field SizingFixedFit integer # Columns use fixed width and will not stretch. Useful when exact sizes are required (e.g., for alignment or layout consistency).
---@field RowBg integer # Draw alternating row background colors for easier readability.
ImGuiTableFlags = ImGuiTableFlags

---Flags to customize individual columns within a table.
---@class ImGuiTableColumnFlags
---@field WidthStretch integer # Makes the column stretch to fill available space.
---@field WidthFixed integer # Makes the column have a fixed width.
ImGuiTableColumnFlags = ImGuiTableColumnFlags

---UI color indices used for styling via `ImGui.PushStyleColor()`.
---Each index refers to a specific UI element's color.
---@class ImGuiCol
---@field Text integer # The color of text.
---@field WindowBg integer # The background color of a window. Default is an opaque dark background.
---@field FrameBg integer # Background color of widgets with a frame (e.g., InputText, DragFloat, etc.) when idle.
---@field TitleBg integer # The background color of a window's title bar when inactive (not focused).
---@field TitleBgActive integer # The background color of a window's title bar when active (focused).
---@field Button integer # The color of button.
---@field TabActive integer # The color used for an active tab in a tab bar. Indicates which tab is currently selected.
---@field TableHeaderBg integer # The background color of a table's header row.
---@field TableBorderStrong integer # Color for strong borders in tables. Typically used for outer or major dividing lines.
---@field TableBorderLight integer # Color for light borders in tables. Typically used for inner or minor dividing lines.
ImGuiCol = ImGuiCol

---Represents the current ImGui style configuration, controlling layout, spacing, padding, rounding, and more.
---@class ImGuiStyle
---@field ItemSpacing { x: number, y: number } # Horizontal and vertical spacing between widgets.
---@field FramePadding { x: number, y: number } # Padding within a framed widget like a button or input box. Affects internal spacing horizontally (x) and vertically (y).
---@field ScrollbarSize number # Horizontal scrollbar width.
ImGuiStyle = ImGuiStyle

---Enumerates the available types of Toast notifications for ImGui popups.
---@class ImGui.ToastType
---@field Success integer # A success notification, typically displayed in green.
---@field Warning integer # A warning notification, typically displayed in yellow or orange.
---@field Error integer # An error notification, typically displayed in red.
---@field Info integer # An informational notification, typically displayed in blue.
ImGui.ToastType = ImGui.ToastType

---Creates a Toast notification instance.
---@class ImGui.Toast
---@field type integer # The Toast type, typically a value from `ImGui.ToastType`.
---@field message string # The main text content of the Toast.
---@field new fun(type: ImGui.ToastType, message: string): ImGui.Toast # Creates a new Toast with the specified type and message.
ImGui.Toast = ImGui.Toast

---Helper for efficiently rendering large lists by skipping items outside the visible scroll area.
---Only the rows within `DisplayStart` and `DisplayEnd` are rendered per step, dramatically reducing per-frame cost for long lists.
---@class ImGuiListClipper
---@field DisplayStart integer # First visible item index for the current step (0-based, inclusive).
---@field DisplayEnd integer # One past the last visible item index for the current step (0-based, exclusive).
---@field new fun(): ImGuiListClipper # Creates a new list clipper instance.
---@field Begin fun(self: ImGuiListClipper, itemCount: integer, itemHeight?: number) # Starts clipping for a list of `itemCount` items. `itemHeight` is measured from the first visible row when omitted.
---@field Step fun(self: ImGuiListClipper): boolean # Advances to the next range of visible items. Returns true while there are items left to render.
ImGuiListClipper = ImGuiListClipper

---Bitwise operations (Lua 5.1 compatibility).
---@class bit32
---@field bor fun(...: integer): integer # Bitwise OR of all given integer values.
---@field band fun(x: integer, y: integer): integer # Returns the bitwise AND of two integers.
---@field rshift fun(x: integer, disp: integer): integer # Shifts `x` right by `disp` bits, filling in with zeros from the left.
---@field lshift fun(x: integer, disp: integer): integer # Shifts `x` left by `disp` bits, discarding bits shifted out on the left.
bit32 = bit32

---Provides access to game data stored in the database, including camera offsets and various other game settings.
---@class TweakDB
---@field GetFlat fun(self: TweakDB, key: string): any? # Retrieves a value from the database based on the provided key.
---@field SetFlat fun(self: TweakDB, key: string, value: any) # Sets or modifies a value in the database for the specified key.
---@field SetFlatNoUpdate fun(self: TweakDB, key: string, value: any) # Sets or modifies a value in the database without applying it immediately. Useful when updating multiple values at once.
---@field Update fun(self: TweakDB, key: string) # Applies the pending change for the specified key that was set with `SetFlatNoUpdate`.
TweakDB = TweakDB

---Represents a TweakDB ID used to reference records in the game database.
---@class TDBID
---@field hash integer # The hash number.
---@field ToStringDEBUG fun(id: TDBID): string? # Converts a TDBID to a readable string, typically starting with a namespace like "Vehicle.".
TDBID = TDBID

---Provides access to system-level requests and information.
---@class SystemRequestsHandler
---@field GetGameVersion fun(): string # Returns the current game version string.

---Represents an internal game name type. Can be converted to a readable string using `Game.NameToString(name)`.
---@class CName

---Represents a single vehicle appearance entry.
---@class VehicleAppearance
---@field name CName # The internal name/ID of the appearance. Use `Game.NameToString(name)` to get a readable string.

---Represents a loaded game resource, including its appearances.
---@class GameResource
---@field appearances VehicleAppearance[] # The appearances data of the resource.

---Provides methods to access a loaded resource and retrieve its data.
---@class ResourceLoader
---@field GetResource fun(self: ResourceLoader): GameResource? # Returns the loaded resource object, or nil if loading failed.

---Provides access to the game's resource depot, which manages various game resources.
---@class ResourceDepot
---@field LoadResource fun(self: ResourceDepot, name: string): ResourceLoader? # Loads the resource with the specified name, or nil if not found.

---Provides control and query access to the vehicle camera system.
---@class VehicleCameraManager
---@field GetActivePerspective fun(self: VehicleCameraManager): table # Returns the currently active vehicle camera perspective as an enum value.

---Represents the player character in the game, providing functions to interact with the player instance.
---@class Player
---@field FindComponentByType fun(self: Player, typeName: string): table # Finds and returns a component of the specified type attached to the player, or nil if not found.
---@field FindVehicleCameraManager fun(self: Player): VehicleCameraManager? # Returns the VehicleCameraManager instance associated with the player, or nil if not available.
---@field SetWarningMessage fun(self: Player, message: string, duration: number) # Displays a warning message on the player's screen for a specified duration.

---Represents a vehicle entity within the game, providing functions to interact with it, such as getting the appearance name.
---@class Vehicle
---@field GetRecordID fun(self: Vehicle): table # Returns the unique TweakDBID associated with the vehicle.
---@field GetTDBID fun(self: Vehicle): TDBID? # Retrieves the internal TweakDB identifier used to reference this vehicle in the game database. Returns nil if unavailable.
---@field GetCurrentAppearanceName fun(self: Vehicle): CName? # Retrieves the current appearance name of the vehicle.
---@field GetDisplayName fun(self: Vehicle): string? # Retrieves the human-readable display name of the vehicle.

---Represents a single settings variable within the game's SettingsSystem.
---@class ConfigVar
---@field GetType fun(self: ConfigVar): { value: string } # Returns the data type of the variable (e.g., "Bool", "Int", "Float", etc.).
---@field GetValue fun(self: ConfigVar): any # Returns the current value of the variable.
---@field GetDefaultValue fun(self: ConfigVar): any # Returns the default value of the variable.
---@field GetMinValue fun(self: ConfigVar): number? # Returns the minimum allowed value for numeric variables.
---@field GetMaxValue fun(self: ConfigVar): number? # Returns the maximum allowed value for numeric variables.
---@field GetStepValue fun(self: ConfigVar): number? # Returns the step size for numeric variables.
---@field GetValues fun(self: ConfigVar): any[]? # Returns all possible values for list-type variables.
---@field GetIndex fun(self: ConfigVar): integer? # Returns the current index for list-type variables.
---@field GetDefaultIndex fun(self: ConfigVar): integer? # Returns the default index for list-type variables.

---Provides access to game settings and configuration variables.
---@class SettingsSystem
---@field HasVar fun(self: SettingsSystem, group: string, option: string): boolean # Checks if a variable exists in the given group.
---@field GetVar fun(self: SettingsSystem, group: string, option: string): ConfigVar # Retrieves a variable object if it exists.

---Provides various global game functions, such as getting the player, mounted vehicles, and converting names to strings.
---@class Game
---@field NameToString fun(value: CName): string # Converts a game name object to a readable string.
---@field EnumValueFromString fun(enumName: string, valueName: string): any # Converts an enum name and value string into its corresponding cdata enum value.
---@field GetLocalizedText fun(key: string): string # Returns the localized text for the specified localization key, e.g., "LocKey#1234".
---@field GetSystemRequestsHandler fun(): SystemRequestsHandler # Provides access to system requests, e.g., game version.
---@field GetResourceDepot fun(): ResourceDepot? # Returns the resource depot object, or nil if not available.
---@field GetPlayer fun(): Player? # Retrieves the current player instance if available.
---@field GetMountedVehicle fun(player: Player): Vehicle? # Returns the vehicle the player is currently mounted in, if any.
---@field GetSettingsSystem fun(): SettingsSystem # Provides access to the global settings system used to query and modify game options.
Game = Game

---Provides access to the game's configuration and runtime options.
---Used to read and modify internal settings such as graphics, streaming, or camera behavior.
---@class GameOptions
---@field GetBool fun(path: string, key: string): boolean # Retrieves a boolean option.
---@field GetInt fun(path: string, key: string): integer # Retrieves an integer option.
---@field GetFloat fun(path: string, key: string): number # Retrieves a floating-point option.
---@field Get fun(path: string, key: string): any # Retrieves an option of any type as string.
---@field SetBool fun(path: string, key: string, value: boolean) # Sets a boolean option (true/false) in the specified category.
---@field SetInt fun(path: string, key: string, value: integer) # Sets an integer option value.
---@field SetFloat fun(path: string, key: string, value: number) # Sets a floating-point option value.
---@field Set fun(path: string, key: string, value: any) # Sets a string option value.
GameOptions = GameOptions

---Represents a three-dimensional vector, commonly used for positions or directions in the game.
---@class Vector3
---@field x number # The X-coordinate.
---@field y number # The Y-coordinate.
---@field z number # The Z-coordinate.
---@field new fun(x: number, y: number, z: number): Vector3 # Creates a new Vector3 instance with specified x, y, and z coordinates.
Vector3 = Vector3

---Retrieves a reference to a loaded CET mod by name.
---@class GetMod # Not a class — provided by CET.
---@field GetMod fun(name: string): table? # Returns the mod object if found, or `nil` if the mod is not loaded.
GetMod = GetMod

---Provides version information about the currently running CET environment.
---@class GetVersion # Not a class — provided by CET.
---@field GetVersion fun(): string # Returns the runtime version as a string, typically formatted like "v1.2.3.4".
GetVersion = GetVersion

---Returns the current screen resolution as width and height in pixels.
---@class GetDisplayResolution # Not a class — provided by CET.
---@field GetDisplayResolution fun(): integer, integer # Returns width and height of the active display in pixels.
GetDisplayResolution = GetDisplayResolution

---Provides functionality to observe game events, allowing custom functions to be executed when certain events occur.
---@class Observe # Not a class — provided by CET.
---@field Observe fun(className: string, functionName: string, callback: fun(...)) # Sets up an observer for a specified function within the game.
Observe = Observe

---Allows the registration of functions to be executed when certain game events occur, such as initialization or shutdown.
---@class registerForEvent # Not a class — provided by CET.
---@field registerForEvent fun(eventName: string, callback: fun(...)) # Registers a callback function for a specified event (e.g., `onInit`, `onIsDefault`).
registerForEvent = registerForEvent

---Provides logging functionality, allowing messages to be printed to the console or log files for debugging purposes.
---@class spdlog # Not a class — provided by CET.
---@field info fun(message: string) # Logs an informational message, typically used for general debug output.
---@field error fun(message: string) # Logs an error message, usually when something goes wrong.
spdlog = spdlog

---SQLite database handle.
---@class db # Not a class — provided by CET.
---@field exec fun(self: db, sql: string): boolean?, string? # Executes a SQL statement. Returns true on success, or nil and an error message.
---@field rows fun(self: db, sql: string): fun(): table # Executes a SELECT statement and returns an iterator. Each yielded row is an array (table) of column values.
db = db

---Scans a directory and returns its contents.
---@class dir # Not a class — provided by CET.
---@field dir fun(path: string): table # Returns a list of file/folder entries in the specified directory. Each entry is a table with at least a `name` field.
dir = dir
