# plugin_drawImportedParameters
A Praat plugin draw images using a TextGrid, Sound file, and Table containing parameters imported from another source.
This script is designed to work best with a single short utterance.

It requires [Praat version 6.x.x](http://www.fon.hum.uva.nl/praat/).

To use the plugin, select the green "Code" icon above, followed by "Download ZIP".
Extract the ZIP file and copy the plugin_drawImportedParameters folder to your Praat preferences directory. (See http://www.fon.hum.uva.nl/praat/manual/preferences_directory.html for more information.)

----------------
## Accessing the plugin
In order to run the plugin from Praat, simply selects a Sound object along with its associated TextGrid and data Table.
An option to "Compare Parameters" will appear in the Objects window.
Click on it to bring up the Menu to compare different parameters across the utterance.

![image](https://user-images.githubusercontent.com/46627448/153032854-f77e1613-5fac-4a0b-bc2e-2a77a92855ea.png)

## User Interface

**TextGrid Information**
|Parameter|Function
|--|--
|Reference tier|A single tier from the TextGrid to be used for reference purposes in the image. You can use either the tier number or the tier name. Note that this must be an interval tier, and it is also used to determine the start and end times for the image.

**Table Column Information**
|Parameter|Function
|--|--
|Time axis|The name of the column in the table contain in the time axis values.
|Y axis parameters|A comma-separated list of columns containing the parameter data to be printed. Note that the scale for the first parameter will be drawn on the left side and the second on the right. Note also that the names of the y-axes will use the column names as labels. If there is only one y-axis parameter, the spectrograph units will be drawn on the right. It is not possible to accommodate more than two scales on the y-axis.

**Pitch Information**
|Parameter|Function
|--|--
|Pitch floor|Minimum f0 in Hertz.
|Pitch ceiling|Maximum f0 in Hertz.
|Run advanced pitch settings|Select to call the advanced pitch settings menu before the image is drawn.

**Draw Information:**
|Parameter|Function
|--|--
|Title|Image title.
|Image height|Image height in inches.
|Image width|Image width in inches.
|Base font size|Smallest font size which will appear in the image.
|Adjust time to zero|Select this to adjust the x-axis so that it shows time at leftmost point as zero.
|Mark y axis from zero where possible|Select this so that the y-axis will be plotted from zero whenever there are no negative values for that parameter. Otherwise, the parameter will be plotted with a y-axis that has a 10% buffer between the lowest and highest value.
|Draw spectrogram|Select this if you want include a spectrogram in the image.
|Draw boundaries|Select this if you want to draw boundaries based on the reference tier in the TextGrid. Note that if you don't draw a spectrogram, the plugin will insist on drawing boundaries regardless of your preference.
|Line colours|A comma-separated list of colours for the image. Each colour must either be a value between 0 and 1 for grayscale or a named colour from the default Praat colour list. Colours will be assigned in order based on the list of y-axis parameters. Note that if there are fewer colours listen than parameters, the script will simply cycle through the list again.
|Show legend|Select this if you want to draw a legend for the image. The plugin will try to draw the legend in a region which avoids obscuring the line graphs.

![image](https://user-images.githubusercontent.com/46627448/153032949-4ea1af4c-5b17-4522-b4c9-d4846312fd85.png)

## Error handling
The plug should be able to catch most input menu errors and warn the user.
If the script crashes unexpected, please get in touch with me.
