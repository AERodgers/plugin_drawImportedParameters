# plugin_drawImportedParameters v.1.2.0
A Praat plugin draw images using a TextGrid, Sound file, and Table containing parameters imported from another source.
This script is designed to work best with a single short utterance.

It requires [Praat version 6.2.x](http://www.fon.hum.uva.nl/praat/).

To install the plugin, select the green "Code" icon above, followed by "Download ZIP".
Extract the ZIP file and copy the plugin_drawImportedParameters folder to your Praat preferences directory. (See http://www.fon.hum.uva.nl/praat/manual/preferences_directory.html for more information.)

![compare parameters](https://user-images.githubusercontent.com/46627448/153866668-df7f11e4-2b70-4a9e-a245-680bb89240f8.png)
![compare utterances](https://user-images.githubusercontent.com/46627448/153866004-a4277ca5-2587-433f-a4de-b5347b9abff0.png)

----------------
## Accessing the plugin
In order to run the plugin from Praat, simply select a **Sound object** along with its associated **TextGrid** and data **Table**.
An option to "Compare multiple parameters in one utterance... " will appear in the Objects window below a new heading, "Draw imported Parameters".
Click on "Compare multiple parameters in one utterance... " to bring up the Menu for comparing different parameters across the utterance.
If you select multiple  **Sound objects**, **TextGrids** and data **Tables**, you will also have the option to "Compare Utterances by one parameter...".

![image](https://user-images.githubusercontent.com/46627448/153032854-f77e1613-5fac-4a0b-bc2e-2a77a92855ea.png)

## User Interface

**TextGrid Information**
|Parameter|Function
|--|--
|Reference tier|A single tier from the TextGrid to be used for reference purposes in the image. You can use either the tier number or the tier name. Note that this must be an interval tier, and it is also used to determine the start and end times for the image.

**Table Column Information**
|Parameter|Function
|--|--
|Time axis|The name of the column in the table contain in the time axis values. The script will automatically detect if the time is in seconds or by sample frame and adjust appropriately.
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

## Final notes
I'm not too sure how this plugin will cope with negative values. If you find it does / does not do well with them, do let me know.

## Updates
1.0.1 the plugin now automatically detects if the time column refers to time in seconds or to the sample rate, and adjusts accordingly.


----
## Notes for improving ```@drawUtterance``` (and ```@drawParameters```)
Unfortunately, I haven't had time to write instructions for this or to make the scripts particularly elegant (to say the least). Below is a summary of issues encountered while writing the script, solutions to them, and a to do list.

This code is currently very clunky and has been hacked together from the ```@compareParameters``` script. However, it al presented a considerably more complex problem. This is because it needs to perform time normalization, i.e., it needs to warp the timing of all contours to align their interval boundaries with those in the reference utterance.
Furthermore, both the script hijacks the pitch object and replaces the pitch values in the object with the VS parameters from the VS table. This worked well in ```@compareParameters```, since the unvoiced portions of the single target utterance were not accidentally populated with spurious values or misleading interpolations. However, in ```@compareUtterances```, it does not work so well. The draw function needs to use a pitch object which aligns with the reference utterance. This must be done for all utterances. Unfortunately the voiced and unvoiced (VUV) sections of each target utterance will not neatly align with the VUV of the reference tier.
The solution for this was to:

1. Generate an all voiced dummy pitch object from the reference utterance, any portion of which could be unvoiced.
2. Generate a 2D VUV matrix from each target utterance, where each row represented a Voiced or Unvoiced section of the utterance (col_1 = tmin, col_2 = tmax, col_3 = voicing flag).
3. Normalize the VUV matrix to the reference tier of the same utterance so that the pre-decimal component equals the interval number, and the decimal component equals the timing of the onset and offset of the VUV section as a proportion of the interval.
4. Warp the normalized values of the VUV matrix to the reference utterance interval times.
5. De-voice the portions of the dummy pitch object based on the time-normalized and warped VUV matrix.

This solution meant that only portions of the original utterance which were voiced would be reflected in the figure (rather than the output misleadingly reflecting the voiced and unvoiced sections of the reference utterance only).
A second issue occurred with the ```@drawLegend``` functions. The function _should_ place the legend key in the least populated area of the image space; however, this appears to be broken. Therefore, I added a function called ```@drawLegend_manual``` and updated the UI so that the user manually selects the location of the legend. NOTE also that the script only uses a small number of the original options for the ```@drawLegend``` set of procedures, so these have been removed from the current script.

## TO DO
Currently there is a lot of redundancy in both main scripts, since they use the same procedures. Rather than using Praat's  built-in ```include``` command, they are simply added to the bottom of the main script. This is largely because it makes finding line numbers easier during debugging. Also, in order to save time, some of the new scripts created for ```@compareParameters``` took a few shortcuts, most noticeably in using global rather than local variables, this mitigating the need for arguments for several procedures. This made them less generalizable. Therefore, as a rather clunk time-saving device, these were simply modified for purpose in ```@compareUtterances```. It will take time to untangle this mess and to generate more efficient generalized alternatives. So...

1. Update the GitHub markdown to ```include``` the instructions for drawUtterance
2. Fix the auto-placement algorithm in the drawLegend procedures. (Remember, the user should only really need to use the ```@legend``` procedure to populate the legend database and the ```@drawLegend``` procedure to draw with legend, including only a _minimal_ number ofdraw parameters.)
3. Allow the script to work with both auto-placement and manual
placement of the legend.
4. Rationalize duplicated scripts by placing them in a separate script file and utilizing the ```include``` command.
5. Where reasonable, generalize scripts which are shared across the two main procedures and if possible make them generalizable even beyond.
