# This script opens each sound file in a directory, looks for a corresponding TextGrid in (possibly) a different directory, 
# and extracts f0, F1, F2 and intensity from the midpoint(s) of any labelled interval(s) in the specified TextGrid tier.  
# It also extracts the duration of the labelled interval(s) as well as labels from other intervals located at the same midpoint(s) on other tiers. 
# All these results are written to a tab-delimited text file.
# The script is a modified version of the script "collect_formant_data_from_files.praat" by 
# Mietta Lennes, available here: http://www.helsinki.fi/~lennes/praat-scripts/
# This script was first modified by Dan McCloy (drmccloy@uw.edu) in December 2011 and
# later modified to add intensity and labels from other tiers by Esther Le GrÃ©zause (elg1@uw.edu) in May 2016.
# Modified by Chiara Meluzzi (University of Pavia) for Italian data

# This script is distributed under the GNU General Public License.
# Copyright 4.7.2003 Mietta Lennes

form Get pitch formants intensity and duration from labeled segments in files
	comment Directory of sound files. Be sure to include the final "\"
	text sound_directory 
	sentence Sound_file_extension .wav
	comment Directory of TextGrid files. Be sure to include the final "\"
	text textGrid_directory 
	sentence TextGrid_file_extension .TextGrid
	comment Full path of the resulting text file (be sure to include "\resultsfile.txt"):
	text resultsfile resultsfile.txt
	comment Which tier do you want to analyze?
	integer Tier 3
	comment Formant analysis parameters
	positive Time_step 0.01
	integer Maximum_number_of_formants 5
	positive Maximum_formant_(Hz) 5500
	positive Window_length_(s) 0.025
	real Preemphasis_from_(Hz) 50
	comment Pitch analysis parameters
	positive Pitch_time_step 0.01
	positive Minimum_pitch_(Hz) 75
	positive Maximum_pitch_(Hz) 300
endform

# Make a listing of all the sound files in a directory:
Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

# Assigning tier number
frase_tier = 1
parola_tier = 2
fono_tier = 3

# Check if the result file exists:
if fileReadable (resultsfile$)
	pause The file 'resultsfile$' already exists! Do you want to overwrite it?
	filedelete 'resultsfile$'
endif

# Create a header row for the result file: (remember to edit this if you add or change the analyses!)
header$ = "Filename	TextGridLabel	duration	fono	parola	frase	f0_midpoint	F1_midpoint	F2_midpoint	intensity_midpoint'newline$'"
fileappend "'resultsfile$'" 'header$'

# Open each sound file in the directory:
for ifile to numberOfFiles
	filename$ = Get string... ifile
	Read from file... 'sound_directory$''filename$'

	# get the name of the sound object:
	soundname$ = selected$ ("Sound", 1)

	# Look for a TextGrid by the same name:
	gridfile$ = "'textGrid_directory$''soundname$''textGrid_file_extension$'"

	# if a TextGrid exists, open it and do the analysis:
	if fileReadable (gridfile$)
		Read from file... 'gridfile$'

		select Sound 'soundname$'
		To Formant (burg)... time_step maximum_number_of_formants maximum_formant window_length preemphasis_from

		select Sound 'soundname$'
		To Pitch... pitch_time_step minimum_pitch maximum_pitch
		
		select Sound 'soundname$'
		To Intensity... minimum_pitch time_step

		select TextGrid 'soundname$'
		numberOfIntervals = Get number of intervals... tier

		# Pass through all intervals in the designated tier, and if they have a label, do the analysis:
		for interval to numberOfIntervals
			label$ = Get label of interval... tier interval
			if label$ <> ""
				# duration:
				start = Get starting point... tier interval
				end = Get end point... tier interval
				duration = end-start
				midpoint = (start + end) / 2

				# get the matching interval (at the midpoint) in the parola tier
				parola_interval = Get interval at time... parola_tier midpoint
				# get label of interval in the parola tier
				label_parola$ = Get label of interval... parola_tier parola_interval

				# get the matching interval (at the midpoint) in the fono tier
				fono_interval = Get interval at time... fono_tier midpoint
				# get label of interval in the fono tier
				label_fono$ = Get label of interval... fono_tier fono_interval

				# get the matching interval (at the midpoint) in the frase tier
				frase_interval = Get interval at time... frase_tier midpoint
				# get label of interval in the frase tier
				label_frase$ = Get label of interval... frase_tier frase_interval

				# formants:
				select Formant 'soundname$'
				f1_50 = Get value at time... 1 midpoint Hertz Linear
				f2_50 = Get value at time... 2 midpoint Hertz Linear

				# pitch:
				select Pitch 'soundname$'
				f0_50 = Get value at time... midpoint Hertz Linear
				
				# intensity:
				select Intensity 'soundname$'
				intensity_50 = Get value at time... midpoint Cubic

				# Save result to text file:
				resultline$ = "'soundname$'	'label$'	'duration'	'label_fono$'	'label_parola$'	'label_frase$'	'f0_50'	'f1_50'	'f2_50'	'intensity_50''newline$'"
				fileappend "'resultsfile$'" 'resultline$'

				# select the TextGrid so we can iterate to the next interval:
				select TextGrid 'soundname$'
			endif
		endfor
		# Remove the TextGrid, Formant, and Pitch objects
		select TextGrid 'soundname$'
		plus Formant 'soundname$'
		plus Pitch 'soundname$'
		Remove
	endif
	# Remove the Sound object
	select Sound 'soundname$'
	Remove
	# and go on with the next sound file!
	select Strings list
endfor

# When everything is done, remove the list of sound file paths:
Remove