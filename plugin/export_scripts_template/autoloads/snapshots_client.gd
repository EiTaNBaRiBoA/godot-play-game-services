extends Node
## Client with save and load games functionality.
##
## This autoload exposes methods and signals to save and load games in the Google cloud of the player.

## Signal emitted after calling the [method save_game] method.[br]
## [br]
## [param is_saved]: Wheter if the game was saved or not.[br]
## [param save_data_name]: The save file name.[br]
## [param save_data_description]: The save file description.
signal game_saved(is_saved: bool, save_data_name: String, save_data_description: String)

## Signal emitted after calling the [method load_game] method or after selecting
## a saved game in the window presented after calling the [method show_saved_games]
## method.[br]
## [br]
## [param saved_data]: The contents of the saved data.[br]
## [param metadata]: The metadata of the loaded snapshot.
signal game_loaded(saved_data: String, metadata: SnapshotMetadata)

## Constant passed to the [method show_saved_games] method to not limit the number of displayed saved files.  
const DISPLAY_LIMIT_NONE := -1

func _ready() -> void:
	if GodotPlayGameServices.android_plugin:
		GodotPlayGameServices.android_plugin.gameSaved.connect(
			func(is_saved: bool, save_data_name: String, save_data_description: String):
				game_saved.emit(is_saved, save_data_name, save_data_description)
		)
		GodotPlayGameServices.android_plugin.gameLoaded.connect(func(saved_data: String, dictionary: Dictionary):
			game_loaded.emit(saved_data, SnapshotMetadata.new(dictionary))
		)

## Opens a new window to display the saved games for the current player. If you select
## a saved game, the [signal game_loaded] signal will be emitted.[br]
## [br]
## [param title]: The title to display in the action bar of the returned Activity.[br]
## [param allow_add_button]: Whether or not to display a "create new snapshot" option in the selection UI.[br]
## [param allow_delete]: Whether or not to provide a delete overflow menu option for each snapshot in the selection UI.[br]
## [param max_snapshots]: The maximum number of snapshots to display in the UI. Use [constant DISPLAY_LIMIT_NONE] to display all snapshots.
func show_saved_games(
	title: String, 
	allow_add_button: bool, 
	allow_delete: bool, 
	max_snapshots: int
) -> void:
	if GodotPlayGameServices.android_plugin:
		GodotPlayGameServices.android_plugin.showSavedGames(title, allow_add_button, allow_delete, max_snapshots)

## Saves game data to the Google Cloud.[br]
## [br]
## This method emits the [signal game_saved] signal.[br]
## [br]
## [param fileName]: The name of the save file. Must be between 1 and 100 non-URL-reserved characters (a-z, A-Z, 0-9, or the symbols "-", ".", "_", or "~").[br]
## [param saveData]: A String with the saved data of the game.[br]
## [param description]: The description of the save file.
func save_game(file_name: String, save_data: String, description: String) -> void:
	if GodotPlayGameServices.android_plugin:
		GodotPlayGameServices.android_plugin.saveGame(file_name, save_data, description)

## Loads game data from the Google Cloud.[br]
## [br]
## This method emits the [signal game_loaded] signal.[br]
## [br]
## [param fileName]: The name of the save file. Must be between 1 and 100 non-URL-reserved charactes (a-z, A-Z, 0-9, or the symbols "-", ".", "_", or "~").
func load_game(file_name: String):
	if GodotPlayGameServices.android_plugin:
		GodotPlayGameServices.android_plugin.loadGame(file_name)

## The metadata of a Snapshot.
class SnapshotMetadata:
	var snapshot_id: String ## The ID of the snapshot.
	var unique_name: String ## The unique identifier of this snapshot. This is the file_name parameter passed to the save_game method.
	var description: String ## The description of the snapshot. This is the description parameter passed to the save_game method.
	var cover_image_aspect_ratio: int ## The aspect ratio of the cover image for this snapshot.
	var progress_value: int  ## The progress value for this snapshot.
	var last_modified_timestamp: int ## The last time this snapshot was modified, in millis since epoch.
	var played_time: int ## The played time of this snapshot in milliseconds.
	var has_change_pending: bool ## Indicates whether or not this snapshot has any changes pending that have not been uploaded to the server.
	var owner: PlayersClient.Player ## The player that owns this snapshot.
	var game: Game ## The game associated with this snapshot.
	var device_name: String ## The name of the device that wrote this snapshot, if known.
	var cover_image_uri: String ## The snapshot cover image.
	
	func _init(dictionary: Dictionary) -> void:
		if dictionary.has("snapshotId"): snapshot_id = dictionary.snapshotId
		if dictionary.has("uniqueName"): unique_name = dictionary.uniqueName
		if dictionary.has("description"): description = dictionary.description
		if dictionary.has("coverImageAspectRatio"): cover_image_aspect_ratio = dictionary.coverImageAspectRatio
		if dictionary.has("progressValue"): progress_value = dictionary.progressValue
		if dictionary.has("lastModifiedTimestamp"): last_modified_timestamp = dictionary.lastModifiedTimestamp
		if dictionary.has("playedTime"): played_time = dictionary.playedTime
		if dictionary.has("hasChangePending"): has_change_pending = dictionary.hasChangePending
		if dictionary.has("owner"): owner = PlayersClient.Player.new(dictionary.owner)
		if dictionary.has("game"): game = Game.new(dictionary.game)
		if dictionary.has("deviceName"): device_name = dictionary.deviceName
		if dictionary.has("coverImageUri"): cover_image_uri = dictionary.coverImageUri
	
	func _to_string() -> String:
		var result := PackedStringArray()
		
		result.append("snapshot_id: %s" % snapshot_id)
		result.append("unique_name: %s" % unique_name)
		result.append("description: %s" % description)
		result.append("cover_image_aspect_ratio: %s" % cover_image_aspect_ratio)
		result.append("progress_value: %s" % progress_value)
		result.append("last_modified_timestamp: %s" % last_modified_timestamp)
		result.append("played_time: %s" % played_time)
		result.append("has_change_pending: %s" % has_change_pending)
		result.append("owner: {%s}" % str(owner))
		result.append("game: {%s}" % str(game))
		result.append("device_name: %s" % device_name)
		result.append("cover_image_uri: %s" % cover_image_uri)
		
		return ", ".join(result)

## Alass with information about a game.
class Game:
	var are_snapshots_enabled: bool ## Indicates whether or not this game supports snapshots.
	var achievement_total_count: int ## The number of achievements registered for this game.
	var application_id: String ## The application ID for this game.
	var description: String ## The description of this game.
	var developer_name: String ## The name of the developer of this game.
	var display_name: String ## The display name for this game.
	var leaderboard_count: int ## The number of leaderboards registered for this game.
	var primary_category: String ## The primary category of the game.
	var secondary_category: String ## The secondary category of the game.
	var theme_color: String ## The theme color for this game.
	var has_gamepad_support: bool ## Indicates whether or not this game is marked as supporting gamepads.
	var hi_res_image_uri: String ## The game's hi-res image.
	var icon_image_uri: String ## The game's icon.
	var featured_image_uri: String ## The game's featured (banner) image from Google Play.
	
	func _init(dictionary: Dictionary) -> void:
		if dictionary.has("areSnapshotsEnabled"): are_snapshots_enabled = dictionary.areSnapshotsEnabled
		if dictionary.has("achievementTotalCount"): achievement_total_count = dictionary.achievementTotalCount
		if dictionary.has("applicationId"): application_id = dictionary.applicationId
		if dictionary.has("description"): description = dictionary.description
		if dictionary.has("developerName"): developer_name = dictionary.developerName
		if dictionary.has("displayName"): display_name = dictionary.displayName
		if dictionary.has("leaderboardCount"): leaderboard_count = dictionary.leaderboardCount
		if dictionary.has("primaryCategory"): primary_category = dictionary.primaryCategory
		if dictionary.has("secondaryCategory"): secondary_category = dictionary.secondaryCategory
		if dictionary.has("themeColor"): theme_color = dictionary.themeColor
		if dictionary.has("hasGamepadSupport"): has_gamepad_support = dictionary.hasGamepadSupport
		if dictionary.has("hiResImageUri"): hi_res_image_uri = dictionary.hiResImageUri
		if dictionary.has("iconImageUri"): icon_image_uri = dictionary.iconImageUri
		if dictionary.has("featuredImageUri"): featured_image_uri = dictionary.featuredImageUri
	
	func _to_string() -> String:
		var result := PackedStringArray()
		
		result.append("are_snapshots_enabled: %s" % are_snapshots_enabled)
		result.append("achievement_total_count: %s" % achievement_total_count)
		result.append("application_id: %s" % application_id)
		result.append("description: %s" % description)
		result.append("developer_name: %s" % developer_name)
		result.append("display_name: %s" % display_name)
		result.append("leaderboard_count: %s" % leaderboard_count)
		result.append("primary_category: %s" % primary_category)
		result.append("secondary_category: %s" % secondary_category)
		result.append("theme_color: %s" % theme_color)
		result.append("has_gamepad_support: %s" % has_gamepad_support)
		result.append("hi_res_image_uri: %s" % hi_res_image_uri)
		result.append("icon_image_uri: %s" % icon_image_uri)
		result.append("featured_image_uri: %s" % featured_image_uri)
		
		return ", ".join(result)