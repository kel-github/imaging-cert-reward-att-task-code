# Imaging the influence of value and certainty on visual attention  
## STRIAVISE WP1

Task code for collection of behavioural data in the MRI scanner with TRs 1.92

(c) Kelly Garner, 2018  
Free to use and share, please cite author/source  

This repository contains the software written for running the behavioural paradigm outlined in WP1 of the STRIAVISE project proposal. Cues indicate the probability of an upcoming target's location amd the number of points available if the task is correct.   

Dependencies are listed in the notes in the code.  
Run all *.m files from the same folder. Keep all *.m files in the folder from which the files are stored. See the notes within the *.m files for further details.  

The code is written to handle the three TRs mentioned above. Accepts '5%' as the trigger from the scanner. '2@' and '3#' for responses.

Run duration:
Staircasing (learn_gabors) = 10 minutes
5 * 1.92 (dummy scans) + 128 * 3 * 1.92 (trials) + 5 seconds (end) = 12:53 per run

For each participant, the code is run _n_ times for _n_ blocks

Any questions? getkellygarner@gmail.com  


