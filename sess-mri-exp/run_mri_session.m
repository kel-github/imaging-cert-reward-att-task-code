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
debug = 1;

% initialise mex files etc
KbCheck;
KbName('UnifyKeyNames');
GetSecs;
AssertOpenGL
Screen('Preference', 'SkipSyncTests', 1);

sess.date = clock;
sess.proj_loc = '~/Documents/striwp1';
proj_loc = sess.proj_loc;
if debug
    sess.sub_num = 10; 
    sess.session = 2;
    sess.run = 1;
    sess.eye_on  = 0;
    sess.TR = 1.51;
    sess.contrast = [.4, .4];
    reward_total = 0; % initiate reward total variable   
else
    sess.sub_num = input('Subject Number? ');
    sess.session = input('Session? ');
    sess.run = input('Run? ');
    sess.eye_on  = input('Eye tracker? (0 or 1)? ');
    sess.TR      = 1.51; % or does it?!
    %sess.contrast = input('Contrasts? ');
    reward_total = input('Total Rewards? ');
end

% set acquisition variable for naming files
sess.acq = sess.TR*1000;
% time cheats
expand_time = 1;
parent = cd;

%% Randomisation seed now based on subject and stage number
stage = '5';
r_num = ['1' num2str(sess.sub_num) '000' num2str(sess.session) stage];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;

run_setup;

%% Generate json metadata for this task and session
addpath('JSONio');
if sess.sub_num < 10
    subref = '-00%d';
elseif sess.sub_num > 9 && sess.sub_num < 100
    subref = '-0%d';
else
    subref = '-%d';
end
sub_dir = [proj_loc '/' sprintf(['sub' subref '/ses-0%d'], sess.sub_num, sess.session) '/beh'];
if ~(exist(sub_dir))
    mkdir(sub_dir);
end


%% Generate json metadata for this task and session
task_str = 'learnAtt';
if sess.sub_num < 10
    sub_str = '00%d';
elseif sess.sub_num > 9 && sess.sub_num < 100
    sub_str = '0%d';
else
    sub_str = '%d';
end

json_log_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_bold_run-0%d.json'], sess.sub_num, sess.session, sess.acq, sess.run);
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
meta_data.map          = 'j = 2@, f = 3#';
meta_data.reward_key   = 'row 1 = high reward col, row 2 = low reward col, rgb';
meta_data.reward_cols  = sess.reward_colours;
% meta_data.target_contrast = sess.contrast;
meta_data.matlabVersion = '2018b';
meta_data.PTBVersion    = '3.0.15';


if ~any(debug)
    json_rd_fname = generate_filename('_ses-0%d_task-learnGabors', sess, '.json');
    tmp = jsonread(fullfile(sub_dir, json_rd_fname));
    meta_data.target_contrasts = tmp.target_contrasts;
    sess.contrast = meta_data.target_contrasts; % for use during the session
    clear tmp
    %meta_data.target_contrasts = sess.contrast;
    generate_meta_data_jsons(meta_data, sub_dir, json_log_fname); 

else
    meta_data.target_contrasts = [.2 .2];
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
fprintf(trls_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'rew', 'loc', 'cue', 'co1', 'co2', 'or', 'resp', 'rt', 'rew_tot','left_col','right_col');
trl_form = '%d\t%d\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\t%d\t%d\t%d\n';
% insert one json generate here
event_data.sub = 'subject number';
event_data.sess = 'session number';
event_data.date = datetime;
event_data.t = 'trial number';
event_data.rew = 'reward available: 1 = high (50), 0 = low (5)';
event_data.loc = '1=tgt left, 2=tgt right';
event_data.cue = 'ptgtleft|cue, 1=.8, 2=.2,3=.5';
event_data.co1 = 'contrast: left gabor';
event_data.co2 = 'contrast: right gabor';
event_data.or = '0=cw, 1=ccw';
event_data.resp = '0=cw, 1=ccw';
event_data.rt = 'response time';
event_data.rew_tot = 'total reward accrued';
event_json_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_trls.json'], ...
                            sess.sub_num, sess.session, sess.acq, sess.run);
generate_meta_data_jsons(event_data, sub_dir, event_json_fname); 

trials = generate_blocks_FourRewardCont_singleRun(1); % for 128 trials
% save the trial table to a file so that we can get other parameters later
% (such as block number, hrz)
tbl_fname       = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_trls_tbl'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run);
trial_tbl_fname = fullfile(sub_dir, tbl_fname);
writetable(trials, trial_tbl_fname);
% insert a second json generate here
trls_data.date = datetime;
trls_data.trial_num = 'trial number (t)';
trls_data.block_num = '2 blocks x 360 t';
trls_data.reward_type = 'reward cueing condition: 1=h/h, 2=h/l, 3=l/l, 4=l/h';
trls_data.reward_trial = 'high or low reward on this trial: 1 = high reward, 2 = low reward';
trls_data.probability = 'p target left | cue: 1=.8, 2=.2,3=.5';
trls_data.position = 'target location: 0 = left, 1 = right';
trls_data.ccw = 'target orientation: 0 = cw, 1 = ccw';
trls_data.hrz = 'distracter orientation" 0 = hrz, 1 = vertical';
tbl_json_fname  = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_trls_tbl.json'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run);
generate_meta_data_jsons(trls_data, sub_dir, tbl_json_fname); 

% set up name of event file that the timing outputs will be sent to
events_fname = sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_events.tsv'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run);
event_fid = fopen(fullfile( sub_dir, events_fname ), 'w' );
fprintf( event_fid, '%s\t%s\t%s\n','onset', 'duration', 'event');
event_form = '%f\t%1.4f\t%s\n';

% 1 last json here
ets.onset = 'onset time';
ets.duration = 'duration of event';
ets.event = 'event type';
ets_fname =  sprintf(['sub-', sub_str, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_events.json'], ...
                        sess.sub_num, sess.session, sess.acq, sess.run); 
generate_meta_data_jsons(ets, sub_dir, ets_fname); 
                                      
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
elseif TR.TR == TRs(3)
    TR.nVis = 1;
    TR.nResp = .65/1.9; % to give .85 seconds
    TR.nFeed = 1/1.9; % to give 1 second
    TR.nFix = 1;
    time.pre_pulse_flip = .05; 
end

% variables for collection time stamps
ts.fix_off = zeros(1, size(trials, 1));
ts.pre_vis = ts.fix_off;
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
% time cheats
run_pre_trials; % to pre-load all variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show instructions for dummy scans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run_task_instructions(w, white, task);
[ts.start_dummy] = Screen('Flip', w);

newt = 0;
if ~any(debug)
    pulse_time = waitPulse;
else 
    pulse_time = GetSecs;
end
fprintf(event_fid, event_form, pulse_time, 0, 'pulse'); % 1

if sess.eye_on
    WaitSecs(0.1);
    Eyelink('StartRecording');
    WaitSecs(0.1);
    
    eye_used = Eyelink('EyeAvailable'); % Tracked eye - re-establish this after each calibration/recalibration
    if eye_used == el.BINOCULAR % if both eyes are tracked
        eye_used = el.LEFT_EYE; % use left eye
    end    
end

% start dummy scans
for i = 1:5
    WaitSecs(TR.TR*.9);
    %newt = pulse_time - newt;   
    if ~any(debug)
        pulse_time = waitPulse;
    else
        pulse_time = GetSecs;
    end
    fprintf(event_fid, event_form, pulse_time, 0, 'dummy scan'); % 5
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
    target_loc  = trials.position(count_trials) + 1; % 1 = left, 2 = right
    ccw         = trials.ccw(count_trials); % 0 or 1
    hrz         = trials.hrz(count_trials);
    reward      = trials.reward_trial(count_trials);
    reward_cond = trials.reward_type(count_trials);
    
    switch reward_cond
        % CASES:
        % case 1 = HtgtvHdst
        % case 2 = HtgtvLdst
        % case 3 = LtgtvLdst
        % case 4 = LtgtHDst
        % colour 1 = High
        % colour 2 = Low
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
    fprintf(event_fid, event_form, ts.pulses(1, count_trials), 0, 'pulse - start trial'); % 1st trial pulse, 2nd trial onwards = iti
    
    pre_pause = time.pre_vis_max*rand;
    ts.pre_vis(count_trials) = GetSecs;
    
    WaitSecs(pre_pause); % pre-cue display interval
    
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
    fprintf(event_fid, event_form, ts.pulses(2, count_trials), 0, 'pulse - end actv');
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
    fprintf(event_fid, event_form, ts.pulses(3, count_trials), 0, 'pulse - end resp'); % should be < 1.92
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SCORE AND GIVE FEEDBACK
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    [response, ts] = do_response_score(count_trials, task, ts, sess, reward, ccw, event_fid, event_form);
    [ts] = animate_reward(w, count_trials, ts, sess, time, response, reward_total, event_fid, event_form);
    % collect trial data, and draw fixation, ready to present at the end of the feedback period
    reward_total = reward_total + response.reward_value;
    % print the output
    fprintf(trls_fid, trl_form, sess.sub_num, sess.session, trial_count, reward, target_loc, trial_cue, contrast(1), contrast(2), ccw, response.correct, response.rt, response.reward_value, cCols(1,1), cCols(1,2));
 
    ts.f_fix_on(count_trials) = Screen('Flip', w, pulse_time+(TR.TR*TR.nFeed)-time.pre_pulse_flip);
    if ~any(debug)
        pulse_time = waitPulse;
    else
        pulse_time = GetSecs;
    end
    ts.pulses(4, count_trials) = pulse_time;
    fprintf(event_fid, event_form, ts.pulses(4, count_trials), 0, 'pulse - end trial');
    
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
    fprintf(event_fid, event_form, pulse_time, 0, 'pulse - end iti');
%    fprintf( event_fid, event_form, ts.fix_off(count_trials), 0, 'final fix' ); % this is happening 2.81 secs after the feedback message is being sent
    
    % save the ts structure
    save([sub_dir '/' events_mat_fname], 'ts');
       
    
end
Priority(0);

% close the behaviour log
fclose( trls_fid );
fclose( event_fid );

% end this stage of the experiment
instructions = ...
    sprintf('Well done,\n you excellent point winner! :)\n');
DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
Screen('Flip', w);
start_ts = KbWait;
WaitSecs(0.5);

% %% Finalise
if sess.eye_on == 1
    fclose(lg_fid);
    Eyelink( 'StopRecording' );
    Eyelink( 'CloseFile' );
    Eyelink( 'ReceiveFile', upper(edf));
end
 
% close log files
fclose('all');
Screen('CloseAll');   




