% K. Garner, 2020. Free to use and share responsibly. Software comes with no
% guarantees. 
%
% this is the wrapper for a set of functions that tests the accuracy of an
% Eyelink 1000 as a participant views fixation. Note that if you want to
% test a wider array of locations you will need to adapt the code (which
% should be relatively simple). Also note that the logic is entirely
% dependent on your participant maintaining fixation.
%
% User defines background colours, fixation colours 1: while recording, 2:
% while resting, duration of recording, and number of recording blocks.
% Note that this code is not written for super high precision of visual
% onsets.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
clear mex

%% initialisations

KbCheck;
KbName('UnifyKeyNames');
GetSecs;
AssertOpenGL
Screen('Preference', 'SkipSyncTests', 1);
screen_index = max(Screen('Screens'));

sess.date = clock;
debug = 1;

%% get user inputs

if debug
    %PsychDebugWindowConfiguration;
    Screen('Preference','SkipSyncTests', 1); 
    inputs.bground = [255, 255, 255] * 0.5;
    inputs.fixdown = [255, 255, 255];
    inputs.fixon = [255, 255, 255] * 0.45;
    inputs.blockdur = 10;
    inputs.nblock = 2;
    inputs.fixsize = 100;
    inputs.scDim = [530 300];
    inputs.eyeDistmm = [650 550];
    inputs.testid = 'dbg';
    sess.eye_on = 1;
else
    inputs.bground = input('Please enter RGB values for background: [r, g, b] ');
    inputs.fixdown = input('Please enter RGB values for rest fixation: [r, g, b] ');
    inputs.fixon = input('Please enter RGB values for fixation during recording: [r, g, b] ');
    inputs.blockdur = input('Now enter block duration in seconds: ');
    inputs.nblock = input('How many blocks would you like to record? ');
    inputs.fixsize = input('Enter the size of the total fixation area in pixels\nNote: enter 1 value of length, assumes a square: '); 
    inputs.scDim = input('Screen width and height in mm [w, h]: ');
    inputs.eyeDistmm = input('Distance of eyes to top and bottom of the screen in mm [t, b]: ');
    inputs.testid = input('test id for file - e.g. t1: ');
    sess.eye_on = 1;
end

%% set up screen things
% get screen, central fixation and flip interval
[w, rect] = Screen('OpenWindow', screen_index, inputs.bground, [], [], [], 0, 8);
Screen(w, 'Flip');
[x_pix, y_pix] = Screen('WindowSize', w);
xc = x_pix / 2;
yc = y_pix / 2;
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
ifi = Screen('GetFlipInterval', w);

% text
Screen('TextStyle', w, 1);
Screen('TextSize', w, 35); 

% fixation Rect
fixbox = CenterRectOnPointd([0 0 inputs.fixsize, inputs.fixsize], xc, yc);
r = inputs.fixsize;

% timing in frames time
time = get_time_in_frames(inputs, ifi);
time.instruct_on = 5;

%% initialise eyetracker
if sess.eye_on
    el=initialise_eyes(w);
    sess.eyetrack = el;
%    sess.elstatus = set_up_for_eyetracking(el, x_pix, y_pix, inputs.scDim(1), inputs.scDim(2), inputs.eyeDistmm(1), inputs.eyeDistmm(2));
end

%% set up Eyetracker
if sess.eye_on
    EyelinkDoTrackerSetup(el); % calibrate
    [sess, el, edf] = eyelink_initfile(el, sess, inputs); 
    % set up log file
    lg_fn = sprintf('ElinkPrecTest_%s.txt', inputs.testid);
    lg_fid = fopen(lg_fn, 'w');
    fprintf(lg_fid, '%s\t%s\t%s\t%s\t%s\t%s\n', 'x','y','xc','yc','r','rf'); % eylink x, eyelink y, screen center x, screen center y, radius from center, radius flag (point outside radius>) 
end

%% set up display
HideCursor;

if sess.eye_on
    WaitSecs(0.1);
    Eyelink('StartRecording');
    WaitSecs(0.1);
    
    eye_used = Eyelink('EyeAvailable'); % Tracked eye - re-establish this after each calibration/recalibration
    if eye_used == el.BINOCULAR % if both eyes are tracked
        eye_used = el.LEFT_EYE; % use left eye
    end    
end

%% go!
for iBlock = 1:inputs.nblock
    
    run_instructions(w, inputs.fixdown, time.instruct_on);

    % draw the recording display
    %draw_visuals(w, inputs.fixon, [0 255 0]/255, inputs.fixsize);
    Screen('Flip', w);
    for i = 1:time.blockdur
        draw_visuals(w, inputs.fixon, [0 255 0], fixbox);
        Screen('Flip', w);
        % get samples
        if sess.eye_on
            [x, y] = check_eyegaze_location(eye_used, el); % GET EYEUSED VARIABLE
            check_dist(x, y, xc, yc, r, lg_fid);
        end             
    end
    
    for i = 1:time.offdur
        draw_visuals(w, inputs.fixdown, inputs.bground, fixbox);
        Screen('Flip', w);
    end
    if iBlock < inputs.nblock && sess.eye_on
        % calibrate and validate again
      %sess.elstatus = set_up_for_eyetracking(el, x_pix, y_pix, inputs.scDim(1), inputs.scDim(2), inputs.eyeDistmm(1), inputs.eyeDistmm(2));
      % may need EyelinkDoTrackerSetup here   
       EyelinkDoTrackerSetup(el); % calibrate
    end
end

%% thank participant
run_thankyou(w, inputs.fixdown, time.instruct_on);

%% save the outputs and plot
if sess.eye_on
    fclose(lg_fid);
    tdfread(lg_fn, '\t');
    plot_data(r, rf);
    saveas(gcf, sprintf('ElinkPrecTest_%s', inputs.testid), 'pdf');
end



%% close it all down
if sess.eye_on == 1
    Eyelink( 'StopRecording' );
    Eyelink( 'CloseFile' );
    Eyelink( 'ReceiveFile', upper(edf) );
end

% close log files
fclose('all');
while (~KbCheck); end; WaitSecs(1);
Screen('CloseAll');

