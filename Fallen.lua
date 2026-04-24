
--[[
Fallen - Distance Alert Addon
Monitors distance to a specific player and plays a sound alert when threshold is exceeded.
]]--

addon.name      = 'Fallen'
addon.author    = 'Seekey'
addon.version   = '1.0'
addon.desc      = 'Let me know when my alt is stuck'
addon.link      = 'https://github.com/seekey13/Fallen'

require('common')
local chat = require('chat')
local imgui = require('imgui')
local settings = require('settings')

--[[
    Constants
]]--

local MAX_ENTITY_INDEX = 2302
local MIN_ALERT_DISTANCE = 5
local MAX_ALERT_DISTANCE = 30
local DISTANCE_CHECK_INTERVAL = 10  -- Check distance every N frames (~6 times per second at 60 FPS)
local ENTITY_SCAN_INTERVAL = 30     -- Full entity scan every N frames when cache misses

--[[
    Settings & Configuration
]]--

-- Default settings
local default_settings = T{
    target_name = '';
    alert_distance = 15;
    show_gui = false;
}

-- Load settings
local config_data = settings.load(default_settings)

-- Settings callback for character switches
settings.register('settings', 'settings_update', function(s)
    if s ~= nil then
        config_data = s
    end
end)

-- Config helper functions
local config = {}

function config.get(key)
    return config_data[key]
end

function config.set(key, value)
    config_data[key] = value
    settings.save()
end

function config.toggle(key)
    if type(config_data[key]) == 'boolean' then
        config_data[key] = not config_data[key]
        settings.save()
        return config_data[key]
    end
    return nil
end

-- Alert tracking
local alert_triggered = false

-- Entity caching for performance
local cached_entity_index = nil
local cached_entity_name = ''

-- Frame throttling counters
local distance_check_frame_counter = 0
local entity_scan_frame_counter = 0

--[[
    Sound Functions
]]--

-- Play the Fallen.wav sound alert
local function play_alert_sound()
    local sound_path = string.format('%s\\Fallen.wav', addon.path)
    ashita.misc.play_sound(sound_path)
end

--[[
    Core Functions
]]--

-- Get entity by name with caching and throttled scanning for performance
-- Args: name (string) - Character name to search for
-- Returns: entity or nil
local function get_entity_by_name(name)
    if not name or name == '' then
        cached_entity_index = nil
        cached_entity_name = ''
        return nil
    end
    
    -- If name changed, invalidate cache and reset scan counter
    if name ~= cached_entity_name then
        cached_entity_index = nil
        cached_entity_name = name
        entity_scan_frame_counter = 0
    end
    
    -- Try to use cached entity index first
    if cached_entity_index then
        local entity = GetEntity(cached_entity_index)
        -- Verify entity still exists and name matches
        if entity and entity.Name == name then
            return entity
        else
            -- Cache invalid, clear it
            cached_entity_index = nil
        end
    end
    
    -- Throttle full entity scans to avoid performance spikes
    entity_scan_frame_counter = entity_scan_frame_counter + 1
    if entity_scan_frame_counter < ENTITY_SCAN_INTERVAL then
        return nil  -- Skip this frame, try again later
    end
    entity_scan_frame_counter = 0
    
    -- Do full search if cache was invalid or not set
    -- Note: Entity indices 0-2302 represent all possible entities in FFXI
    for i = 0, MAX_ENTITY_INDEX do
        local entity = GetEntity(i)
        if entity and entity.Name == name then
            -- Cache the index for future lookups
            cached_entity_index = i
            return entity
        end
    end
    
    -- Entity not found, clear cache
    cached_entity_index = nil
    return nil
end

-- Calculate distance between two entities using 3D Euclidean formula
-- Uses LocalPosition coordinates (FFXI world units, ~1 unit = 1 yalm)
-- Args: entity1, entity2 - Entity objects with Movement.LocalPosition
-- Returns: number (distance) or nil on error
local function calculate_distance(entity1, entity2)
    -- Explicit nil checks for safer property access
    if not entity1 or not entity1.Movement or not entity1.Movement.LocalPosition then
        return nil
    end
    if not entity2 or not entity2.Movement or not entity2.Movement.LocalPosition then
        return nil
    end
    
    local ok, distance = pcall(function()
        local dx = entity1.Movement.LocalPosition.X - entity2.Movement.LocalPosition.X
        local dy = entity1.Movement.LocalPosition.Y - entity2.Movement.LocalPosition.Y
        local dz = entity1.Movement.LocalPosition.Z - entity2.Movement.LocalPosition.Z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end)
    
    if not ok or not distance then
        return nil
    end
    
    return distance
end

-- Get distance from player to named entity
-- Args: name (string) - Character name to check distance to
-- Returns: number (distance) or nil on error
local function get_distance_to_entity(name)
    -- Get player entity
    local player = GetPlayerEntity()
    if not player then
        return nil, "Unable to get player entity"
    end
    
    -- Find target entity by name
    local target = get_entity_by_name(name)
    if not target then
        return nil, string.format("%s not found", name)
    end
    
    -- Calculate distance
    local distance = calculate_distance(player, target)
    if not distance then
        return nil, "Unable to calculate distance"
    end
    
    return distance, nil
end

--[[
    ImGui Functions
]]--

-- Render the configuration GUI
local function render_gui()
    if not config.get('show_gui') then
        return
    end
    
    local is_open = {true}
    if imgui.Begin('Fallen', is_open, ImGuiWindowFlags_AlwaysAutoResize) then
        -- Player name input
        imgui.Text('Player Name:')
        local name_buffer = {config.get('target_name')}
        imgui.PushItemWidth(200)
        if imgui.InputText('##targetname', name_buffer, 32) then
            config.set('target_name', name_buffer[1])
            alert_triggered = false  -- Reset alert when name changes
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Distance slider
        imgui.Text('Alert Distance:')
        local distance_buffer = {config.get('alert_distance')}
        imgui.PushItemWidth(200)
        if imgui.SliderInt('##alertdistance', distance_buffer, MIN_ALERT_DISTANCE, MAX_ALERT_DISTANCE) then
            config.set('alert_distance', distance_buffer[1])
            alert_triggered = false  -- Reset alert when distance changes
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Status display
        local target_name = config.get('target_name')
        if target_name ~= '' then
            local distance, error_msg = get_distance_to_entity(target_name)
            if error_msg then
                imgui.TextColored({1.0, 0.4, 0.4, 1.0}, error_msg)
            else
                local threshold = config.get('alert_distance')
                if distance > threshold then
                    imgui.TextColored({1.0, 0.4, 0.4, 1.0}, string.format('Distance: %.1f yalms', distance))
                else
                    imgui.TextColored({0.4, 1.0, 0.4, 1.0}, string.format('Distance: %.1f yalms', distance))
                end
            end
        else
            imgui.Text('Enter a player name to monitor')
        end
        
        imgui.End()
    end
    
    -- Handle window close
    if not is_open[1] then
        config.set('show_gui', false)
    end
end

--[[
    Distance Monitoring
]]--

-- Monitor distance and trigger alerts with frame throttling for efficiency
-- Called every frame but only processes every DISTANCE_CHECK_INTERVAL frames
local function monitor_distance()
    -- Throttle distance checks to reduce CPU usage (~6 checks per second at 60 FPS)
    distance_check_frame_counter = distance_check_frame_counter + 1
    if distance_check_frame_counter < DISTANCE_CHECK_INTERVAL then
        return
    end
    distance_check_frame_counter = 0
    
    local target_name = config.get('target_name')
    
    -- Skip if no target name is set
    if target_name == '' then
        alert_triggered = false
        return
    end
    
    -- Get distance to target
    local distance, error_msg = get_distance_to_entity(target_name)
    
    -- Skip if target not found or error
    if error_msg then
        alert_triggered = false
        return
    end
    
    local threshold = config.get('alert_distance')
    
    -- Check if distance exceeds threshold
    if distance > threshold then
        -- Play alert only once when threshold is first exceeded
        if not alert_triggered then
            play_alert_sound()
            alert_triggered = true
            print(chat.header(addon.name):append(chat.error(
                string.format('%s has fallen and can\'t get up!', target_name)
            )))
        end
    else
        -- Reset alert when distance drops below threshold
        alert_triggered = false
    end
end

--[[
    Command Handler
]]--

-- Handle /fallen command
-- Usage: /fallen - Toggles the configuration GUI
ashita.events.register('command', 'command_cb', function (e)
    -- Parse command arguments
    local args = e.command:args()
    if #args == 0 or args[1]:lower() ~= '/fallen' then
        return
    end
    
    -- Block the command from being sent to the server
    e.blocked = true
    
    -- Toggle GUI visibility
    local new_state = config.toggle('show_gui')
    if new_state then
        print(chat.header(addon.name):append(chat.message('Configuration panel opened')))
    else
        print(chat.header(addon.name):append(chat.message('Configuration panel closed')))
    end
end)

--[[
    Event Handlers
]]--

-- Load event
ashita.events.register('load', 'load_cb', function ()
    print(chat.header(addon.name):append(chat.message('Loaded! Use /fallen to open configuration panel')))
end)

-- Unload event
ashita.events.register('unload', 'unload_cb', function ()
    print(chat.header(addon.name):append(chat.message('Unloaded.')))
end)

-- D3D Present event (called every frame)
ashita.events.register('d3d_present', 'present_cb', function ()
    -- Render GUI
    render_gui()
    
    -- Monitor distance and trigger alerts
    monitor_distance()
end)
