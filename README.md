# Fallen 
### Simple tool to help you keep track of your Alt getting stuck

<img width="498" height="497" alt="monday-mood" src="https://github.com/user-attachments/assets/b6058e42-d1a8-4ced-870e-a4ea993efdf9" />

## Features

- **Distance Monitoring**: Automatically monitors the distance between you and your tracked alt character
- **Audio Alerts**: Plays a customizable sound alert when your alt exceeds the configured distance threshold
- **Sound Picker**: Choose from any WAV file in the sounds folder with instant preview playback
- **Chat Alerts**: Customizable chat messages when distance threshold is exceeded
- **Circle Overlay**: Visual expanding circle that grows based on distance to your tracked character
- **Color-Coded Distance**: Circle shows green (safe) or red (threshold exceeded)
- **Configurable Settings**: Adjustable alert distance, circle size, text size, and more
- **Per-Character Settings**: Settings are saved per character

## Installation

1. Place the `Fallen` folder (including the `sounds` subfolder) in your `Ashita\addons\` directory
2. Load the addon in-game: `/addon load fallen`

## Commands

- `/fallen` - Toggle the configuration panel

## Configuration

Open the configuration panel with `/fallen` to adjust:

- **Status Display**: Shows current distance to your alt (color-coded green/red) at the top of the panel
- **Player Name**: The name of your alt character to track
- **Alert Distance**: Distance threshold (in yalms) for audio alerts (5-30 yalms)
- **Circle Overlay**: Enable/disable the circle overlay (checkbox)
  - **Circle Size**: Maximum size of the circle in pixels (10-50px, only visible when overlay is enabled)
  - **Text Size**: Scale factor for the distance text (0.5x - 2.0x, only visible when overlay is enabled)
- **Alert Sound**: Enable/disable audio alerts (checkbox)
  - **Sound Selector**: Choose from available WAV files in the sounds folder (only visible when enabled)
  - Sounds play automatically when selected for instant preview
- **Chat Alert**: Enable/disable chat notifications (checkbox)
  - **Message**: Customize the alert message text (only visible when enabled)
  - Use `%s` as a placeholder for the player name

The GUI layout places labels on one line with their corresponding controls on the line below for a compact, organized interface.

## How to Use

1. Open the configuration panel: `/fallen`
2. Enter your alt's character name in the "Player Name" field
3. Set your desired alert distance threshold
4. Configure your alerts:
   - Check "Alert Sound" and select your preferred sound from the dropdown
   - Check "Chat Alert" and customize the message text if desired
5. Optionally enable the circle overlay for visual feedback
6. The addon will now:
   - Monitor your distance to the alt
   - Play an audio alert when distance exceeds the threshold (if enabled)
   - Display a chat message (if enabled)
   - Display an expanding circle that grows with distance (if overlay enabled)
   - Show the current distance when threshold is exceeded

## How the Circle Works

The circle overlay provides visual distance feedback:
- **Circle Growth**: Starts at 1px when directly on top of your alt, grows linearly up to your configured max size at the alert threshold, then stops growing
- **Color Coding**:
  - **Green**: Below alert threshold (safe distance)
  - **Red**: At or above threshold (alert triggered)
- **Distance Text**: White text displays the exact distance in yalms, but only appears when the threshold is met or exceeded

## Custom Sounds

To add your own alert sounds:
1. Place any WAV files in the `Fallen\sounds` folder
2. Reload the addon or restart the game
3. Your sounds will appear in the sound selector dropdown
4. Select any sound to preview it instantly

The default sound is `ive-fallen-and-i-cant-get-up.wav`.

## Notes

- Distance is measured in yalms (FFXI world units)
- Settings are automatically saved per character
- The addon uses optimized entity scanning for minimal performance impact
- The circle overlay is position-independent and only reflects distance, not direction
- Sound files are scanned once when the addon loads
- All alerts (sound and chat) can be independently enabled or disabled

