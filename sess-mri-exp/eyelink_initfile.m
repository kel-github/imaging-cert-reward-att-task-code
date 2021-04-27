function [sess, el, edf_file] = eyelink_initfile(el, sess, input)

testid = input.testid;
runid = input.runid;
bgrnd = input.bground;

[sess.eyelink_version, sess.eyelink_vstring] = ...
    Eyelink('GetTrackerVersion');

edf_file = sprintf('%s_%s.edf', testid, runid);

Eyelink('Openfile', edf_file); % Create and open your Eyelink File
% Set calibration type.
% Eyelink('command', 'saccade_velocity_threshold = 35'); %Default from Eyelink Demo
% Eyelink('command', 'saccade_acceleration_threshold = 9500'); %Default from Eyelink Demo
% % Set EDF file contents.
% Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); %Event data to collect
% Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS'); %Sample data to collect
el.backgroundcolour = bgrnd;
EyelinkUpdateDefaults(el);
end