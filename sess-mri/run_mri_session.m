% Run test of mixed trials in the MRI scanner
% Run once for one run
% K. Garner, 2019
% NOTES:
%
% Dimensions calibrated for see get_ppd() for viewing distance/resolution
% info

% Psychtoolbox 3.0.14 - Flavor: beta - Corresponds to SVN Revision 8301
% Matlab R2017a
%
% this code presents gratings on the left and right sides of the screen
% (LVF), participants make a respone with 1 of 2 keys to indicate whether
% one of the gratings was rotated clockwise or counterclockwise. Gratings are presented
% at a contrast that results in accuracy of .75 (titrated by using
% run_learn_gabors.m). Targets are cued by shapes that indicate the target
% location (p - Left) with .8, .5, .2. Target-prob allocation is 
% counterbalanced across participants
% participants respond under 4 value conditions - hh, ll, lh, hl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
clear mex

% debug just automatically assigns some subject numbers/starting parameters, and results in the
% cursor not being hidden
debug = 0;

% initialise mex files etc
KbCheck;
KbName('UnifyKeyNames');
GetSecs;
AssertOpenGL
% Screen('Preference', 'SkipSyncTests', 1);

sess.date = clock;
if debug
    sess.sub_num = 2;
    sess.session = 2;
    sess.run = 1;
    sess.eye_on  = 0;
    sess.TR = 1.92;
    sess.contrast = [.4, .4];
    reward_total = 0; % initiate reward total variable   
else
    sess.sub_num = input('Subject Number? ');
    sess.session = input('Session? ');
    sess.run = input('Run? ');
    sess.eye_on  = input('Eye tracker? (0 or 1)? ');
    sess.TR      = input('TR? ');
    sess.contrast = input('Contrasts? ');
    reward_total = input('Total Rewards? ');
end

% set acquisition variable for naming files
sess.acq = sess.TR*1000;

% time cheats
expand_time = 1;
parent = cd;

%% Randomisation seed now based on subject and stage number
stage = '4';
r_num = ['1' num2str(sess.sub_num) '000' num2str(sess.session) stage];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;

run_setup;

%% Generate json metadata for this task and session
task_str = 'learnAtt';
if sess.sub_num < 10
    sub_str = '0%d';
else
    sub_str = '%d';
end
if sess.run == 1
    json_log_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_bold.json'], sess.sub_num, sess.session, sess.acq);
    meta_data.sub          = sess.sub_num;
    meta_data.session      = sess.session;
    meta_data.date         = datetime;
    meta_data.task         = 'learnAtt';
    meta_data.BIDS         = 'v1.0.2';
    meta_data.resp_order   = sess.resp_order;
    if sess.resp_order == 1
        meta_data.resp_key      = 'clockwise: f, anticlockwise: j';
    else
        meta_data.resp_key      = 'clockwise: j, anticlockwise: f';
    end
    meta_data.reward_key   = 'row 1 = high reward col, row 2 = low reward col, rgb';
    meta_data.reward_cols  = sess.reward_colours;
    meta_data.target_contrast = sess.contrast;
    meta_data.matlabVersion = '2018b';
    meta_data.PTBVersion    = '3.0.15';
    generate_meta_data_jsons(meta_data, sub_dir, json_log_fname);
end

%% Start experiment
if ~debug
    HideCursor;
end

%%%%%%%%%%%% 
% create trial types, broken down by whether the cue is informative or not,
% the idea is to get small blocks that can be mixed together so that the
% local probabilities are close to what would be expected globally. But
% once all the trials are done, then each cue would have been seen the same
% number of times, in each colour
% OPEN A FILE TO RECORD THE LOG HERE
%% Generate basis for trial structure and set up log files for writing to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trls_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_trls.tsv'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run);
trls_fid = fopen(fullfile( sub_dir, trls_fname), 'w');
fprintf(trls_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'rew', 'loc', 'cue', 'co1', 'co2', 'or', 'resp', 'rt', 'rew_tot');
trl_form = '%d\t%d\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\t%d\n';

trials = generate_blocks_FourRewardCont_singleRun(1); % for 128 trials
% save the trial table to a file so that we can get other parameters later
% (such as block number, hrz)
tbl_fname       = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_trls'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run);
trial_tbl_fname = fullfile(sub_dir, tbl_fname);
writetable(trials, trial_tbl_fname);

% set up name of event file that the timing outputs will be sent to
events_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_events.tsv'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run);
event_fid = fopen(fullfile( sub_dir, events_fname ), 'w' );
fprintf( event_fid, '%s\t%s\t%s\n','onset', 'duration', 'event');
event_form = '%f\t%1.4f\t%s\n';

% and for the mat file
events_mat_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_events'], ...
                            sess.sub_num, sess.session, sess.acq, sess.run);

n_trials_between_breaks = 20;
n_positions             = 2;
training                = 0;
% cues                    = [1, 3, 2];
contrast                = sess.contrast;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set TR/time-based parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TR.TR = sess.TR;
TRs = [.7, 1.51, 1.92];
if TR.TR < 1
    TR.nVis = 2;
    TR.nResp = 2;
    TR.nFeed = 2;
    TR.nFix = 1;
    time.pre_pulse_flip = .08; % how long before the pulse to flip
elseif TR.TR > 1 && TR.TR ~= TRs(3)
    TR.nVis = 1;
    TR.nResp = 1;
    TR.nFeed = 1;
    TR.nFix = 1;
    time.pre_pulse_flip = .1; 
elseif TR.TR == 1.9
    TR.nVis = 1;
    TR.nResp = .65/1.9; % to give .85 seconds
    TR.nFeed = 1/1.9; % to give 1 second
    TR.nFix = 1;
    time.pre_pulse_flip = .05; 
end

% variables for collection time stamps
ts.fix_off = zeros(1, size(trials, 1));
ts.cue = ts.fix_off;
ts.spatial = ts.fix_off;
ts.hold = ts.fix_off;
ts.target = ts.fix_off;
ts.mask = ts.fix_off;
ts.pending = ts.fix_off;
ts.resp_start = ts.fix_off; % response period start
ts.resp_end = ts.fix_off; % response period end
ts.response = ts.fix_off; % timestamp of response on a given trial
ts.feed_on = ts.fix_off;
ts.fix_on = ts.fix_off;
ts.f_fix_on = ts.fix_off;
ts.pulses = zeros(4, size(ts.fix_off, 2)); % collect the onset time of every pulse
%% run experiment

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pre-load variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Priority(topPriorityLevel);    
run_pre_trials; % to pre-load all variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show instructions for dummy scans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run_task_instructions(w, white, task);
[ts.start_dummy] = Screen('Flip', w);

newt = 0;
pulse_time = waitPulse;
for i = 1:5
    WaitSecs(TR.TR*.9);
    newt = pulse_time - newt;
    fprintf(event_fid, event_form, newt, 0, 'dummy scan');
    if ~any(debug)
        pulse_time = waitPulse;
    else
        pulse_time = GetSecs;
    end
end
% set text variables for later drawing
Screen('TextStyle', w, 1);
Screen('TextSize', w, 80);

do_fixation(w, sess);
ts.end_dummy = Screen('Flip', w);
fprintf(event_fid, event_form, ts.end_dummy, 0, 'end dummy');

for count_trials = 1:max(trials.trial_num)
    
    % set parameters here
    trial_count = trials.trial_num(count_trials);
    trial_type  = trials.probability(count_trials); % which trial type
    trial_cue   = trials.probability(count_trials);   
    target_loc  = trials.position(count_trials) + 1;
    ccw         = trials.ccw(count_trials);
    hrz         = trials.hrz(count_trials);
    reward      = trials.reward_trial(count_trials);
    reward_cond = trials.reward_type(count_trials);
    
    switch reward_cond
        case 1
            % get the colour to be learned
            cCols = [sess.reward_colours(:,1), sess.reward_colours(:,1)];
        case 2
            cCols = zeros(3,2);
            cCols(:, target_loc)   = sess.reward_colours(:,1);
            cCols(:, 3-target_loc) = sess.reward_colours(:,2); % the second colour in this variable is the high reward value
        case 3
            cCols = [sess.reward_colours(:,2), sess.reward_colours(:,2)];
        case 4
            cCols = zeros(3,2);
            cCols(:, target_loc)   = sess.reward_colours(:,2);
            cCols(:, 3-target_loc) = sess.reward_colours(:,1);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VISUAL EVENTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % the following function will take between .9340 and 1.1 s. The idea
    % is that the visual events function will run - then the code will wait
    % until the pulse_time + the relevant number of seconds, before
    % continuing
    % get trial start time 
    ts.pulses(1, count_trials) = pulse_time;
    [ts] = do_visual_events(w, count_trials, ts, sess, trial_cue, target_loc, ccw, hrz, cCols, ...
                            angle, contrast, 1, event_fid, event_form); % visual events have occurred
    % now draw fixation, but don't flip until the relevant time period has
    % gone by
    do_fix_full(w, sess, cCols, 1);
    ts.resp_start(count_trials) = Screen('Flip', w, pulse_time+(TR.TR*TR.nVis)-time.pre_pulse_flip); % so the flip should occur 10 ms before the desired pulse   
    if ~any(debug)
        pulse_time = waitPulse; % collect new pulse time, to implement things in the response period
    else
        pulse_time = GetSecs;
    end
    ts.pulses(2, count_trials) = pulse_time;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % RESPONSE PERIOD
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    do_fix_full(w, sess, cCols, 1);
    ts.resp_end(count_trials) = Screen('Flip', w, pulse_time+(TR.TR*TR.nResp)-time.pre_pulse_flip); % flip should occur 10 ms before the end of the response period
    if TR.TR < 1.9
        if ~any(debug)
            pulse_time = waitPulse;
        else
            pulse_time = GetSecs;
        end
    else
        pulse_time = GetSecs;
    end
    ts.pulses(3, count_trials) = pulse_time;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SCORE AND GIVE FEEDBACK
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    [response, ts] = do_response_score(count_trials, task, ts, sess, reward, ccw, event_fid, event_form);
    [ts] = animate_reward(w, count_trials, ts, sess, time, response, reward_total, event_fid, event_form);
    % collect trial data, and draw fixation, ready to present at the end of the feedback period
    reward_total = reward_total + response.reward_value;
    % print the output
    fprintf(trls_fid, trl_form, sess.sub_num, sess.session, trial_count, reward, target_loc, trial_cue, contrast(1), contrast(2), ccw, response.correct, response.rt, response.reward_value);
 
    ts.f_fix_on(count_trials) = Screen('Flip', w, pulse_time+(TR.TR*TR.nFeed)-time.pre_pulse_flip);
    if ~any(debug)
        pulse_time = waitPulse;
    else
        pulse_time = GetSecs;
    end
    ts.pulses(4, count_trials) = pulse_time;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FINAL FIXATION PERIOD
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    do_fixation(w, sess);    
    ts.fix_off(count_trials) = Screen('Flip', w, pulse_time+(TR.TR*TR.nFix)-time.pre_pulse_flip);
    if ~any(debug)
        pulse_time = waitPulse;
    else
        pulse_time = GetSecs;
    end
  
    fprintf( event_fid, event_form, ts.fix_off(count_trials), 0, 'final fix' ); % this is happening 2.81 secs after the feedback message is being sent
    
    % save the ts structure
    save([sub_dir '/' events_mat_fname], 'ts');
       
    
end
Priority(0);

% close the behaviour log
fclose( trls_fid );
fclose( event_fid );

% end this stage of the experiment
instructions = ...
    sprintf('Well done! You have finished! :)\n');
DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
Screen('Flip', w);
start_ts = KbWait;
WaitSecs(0.5);

% %% Finalise
if sess.eye_on == 1
    Eyelink( 'StopRecording' );
    Eyelink( 'CloseFile' );
    Eyelink( 'ReceiveFile', upper(edfFile));
end
    
Screen('CloseAll');   




