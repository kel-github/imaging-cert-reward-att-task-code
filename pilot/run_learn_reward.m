% 'learn-att-v1_step2-reward-v1'
% Learn cue-shape-probability contingency component of visual orienting
% task - and run test of mixed trials, 120 per level of each factor
% K. Garner, 2019
%
% Borrows from C. Nolan, 2017, HABIT REWARD EXP
%
% NOTES:
%
% Dimensions calibrated for [](with viewing distance
% of 570 mm)

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
% for each cue, there is a block of single task trials (N = 50)
% then a block of mixed trials (N = 100 per cue)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TO-DO - 
% CHECK FULL FILE LOG TO MAKE SURE TRIAL ALLOCATIONS WORK IN REAL LIFE 

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
% Screen('Preference', 'SkipSyncTests', 1);

sess.date = clock;
if debug
    sess.sub_num = 2;
    sess.session = 1;
    sess.eye_on  = 0;
    sess.skip_init_train = 1;
else
    sess.sub_num = input('Subject Number? ');
    sess.session = input('Session? ');
    sess.eye_on  = input('Eye tracker? (0 or 1)? ');
    sess.skip_init_train = 0;
end

% time cheats
expand_time = 1;
parent = cd;

%% Monitor settings
monitor = 0;
ref_rate = 60;
resolution = [1024 768]; % might change this with psychtoolbox - get stuff

%% Parameters
reward_colours = [253, 106, 2; 100, 0, 100]; % rgb

load('counterBalance_task_learn_att_v1')
sess.shapes     = p_counterbalance(1:3, sess.sub_num); % shape/direction allocation, pos 1 = .8 left, pos 2 = .2 left, pos 3 = .5 left
sess.col_map    = p_counterbalance(4, sess.sub_num); % colour-reward mapping - 0 = high = [241, 163, 64], low = [153, 142, 195], 1 = high = [153, 142, 195], low = [241, 163, 64],
sess.resp_order = p_counterbalance(5, sess.sub_num); % response order - 1 = '1' is clockwise, and '2' is counterclockwise
                                                                      % 2 = '1' is counterclockwise, and '2' is clockwise
clear p_counterbalance

% reward parameters
% the idea here is that participants will earn a proportion of the
% available reward, based on their rt. Here we set the start parameters
% for the proportion of reward to be computed from in the do_trial
% function,
sess.reward_base_rt = .85;
sess.reward_max_bonus_rt = .35;
sess.reward_base = 50;
sess.reward_bonus = 50;
sess.reward_base_low = 5;
sess.reward_bonus_low = 5;
if ~any(sess.col_map)
    sess.reward_colours = reward_colours;
else
    sess.reward_colours = reward_colours([2, 1], :);
end
% Angle of gabor target
angle = 45;
%% Randomisation seed now based on subject and session number
r_num = ['1' num2str(sess.sub_num) '000' num2str(sess.session)];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;

%% Initialise Eyelink
% NOTE - this references a Screen output (grey) and must happen after the
% screens have been drawn
if sess.eye_on
    fixation_eye_box = CenterRectOnPointd([0 0 100 100], xc, yc);
    el = EyelinkInitDefaults(w); % Initialization
    if ~EyelinkInit(0) % Fail nice if you are going to fail
        fprintf('Eyelink Init aborted.\n');
        return;
    end
    [sess.eyelink_version, sess.eyelink_vstring] = ...
        Eyelink('GetTrackerVersion');
    
    if sess.sub_num < 10
        edf_file = generate_filename('_ses-%0d_task-learn-att-v1-reward', sess, 'edf');
    else
        edf_file = generate_filename('_ses-%d_task-learn-att-v1-reward', sess, 'edf');
    end
    Eyelink('Openfile', edf_file); % Create and open your Eyelink File
    % Set calibration type.
    Eyelink('command', 'calibration_type = HV9'); %This is a typical 9 point calibration
    Eyelink('command', 'saccade_velocity_threshold = 35'); %Default from Eyelink Demo
    Eyelink('command', 'saccade_acceleration_threshold = 9500'); %Default from Eyelink Demo
    % Set EDF file contents.
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); %Event data to collect
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS'); %Sample data to collect
    el.backgroundcolour = grey;
else
    sess.eyelink_version = -1;
    sess.eyelink_vstring = [];
end

%% Generate json metadata for this task and session
addpath('JSONio/');
if sess.sub_num < 10
    sub_dir = sprintf('sub-0%d_ses-%d_task-learn-att-v1', sess.sub_num, sess.session);
else
    sub_dir = sprintf('sub-%d_ses-%d_task-learn-att-v1', sess.sub_num, sess.session);
end
if ~(exist(sub_dir))
    mkdir(sub_dir);
end
root_dir = cd;
json_log_fname = generate_filename('_ses-%d_task-learn-att-v1-reward', sess, '.json');
meta_data.sub          = sess.sub_num;
meta_data.session      = sess.session;
meta_data.date         = datetime;
meta_data.task         = 'learn-att-v1_step1-rewards-v1';
meta_data.BIDS         = 'v1.1';
meta_data.resp_order   = sess.resp_order;
if ~any(sess.resp_order)
    meta_data.resp_key      = 'clockwise: f, anticlockwise: j';
else
    meta_data.resp_key      = 'clockwise: j, anticlockwise: f';
end
meta_data.reward_key   = 'row 1 = high reward col, row 2 = low reward col, rgb';
meta_data.reward_cols  = sess.reward_colours;

root_dir       = pwd;
project_dir    = sub_dir;

% get filename to read contrast params from initital session
json_rd_fname = generate_filename('_ses-%d_task-learn-att-v1-gabors', sess, '.json');
tmp = jsonread(fullfile(sub_dir, json_rd_fname));
meta_data.target_contrasts = tmp.target_contrasts;
sess.contrast = meta_data.target_contrasts; % for use during the session
clear tmp
meta_data.cue_probs = '.8/.2, .5/.5, .2/.8';
meta_data.cue_order = sess.shapes;
generate_meta_data_jsons(meta_data, root_dir, project_dir, json_log_fname);

%% Generate basis for trial structure and set up log files for writing to
events_fname = generate_filename('_ses-%d_task-learn-att-v1-learn-rewards-v1_events', sess, '.tsv');
events_fid = fopen(fullfile(root_dir, sub_dir, events_fname), 'w');
fprintf(events_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'rew', 'loc', 'cue', 'co1', 'co2', 'or', 'resp', 'rt');
trl_form = '%d\t%d\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\n';

%% SCREEN / DRAWING
screen_index = max(Screen('Screens'));
%PsychDebugWindowConfiguration;
Screen('Preference','SkipSyncTests', 1);
white = WhiteIndex(screen_index);
black = BlackIndex(screen_index);
grey = white * 0.5;
stim_dark = white * 0.2;
sess.config.white = white;
sess.config.black = black;
sess.config.grey = grey;
sess.config.stim_dark = stim_dark;
sess.config.reward_colour = [255, 211, 0]; % earned points appear in this colour

[w, rect] = Screen('OpenWindow', screen_index, grey, [], [], [], 0, 8);
Screen(w, 'Flip');
[x_pix, y_pix] = Screen('WindowSize', w);
xc = x_pix / 2;
yc = y_pix / 2;
yq = y_pix / 4;
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
ifi = Screen('GetFlipInterval', w); % timing control
% Retrieve the maximum priority number
topPriorityLevel = 1; %MaxPriority(w);
gabor_r = round(3*get_ppd());
[gabor_id, gabor_rect] = ...
    CreateProceduralGabor(w, gabor_r, gabor_r, 0, [0.5, 0.5, 0.5, 1.0], ...
    1, 0.5);
sess.config.gabor_id = gabor_id;
sess.config.gabor_rect = gabor_rect;

% Setup text
Screen('TextStyle', w, 1);
Screen('TextSize', w, 30);

% Define responses and initiate kb queue
keys = zeros(1,256);
if sess.resp_order
    task.responses = KbName({'j','f'});
    keys(task.responses) = 1;
else
    task.responses = KbName({'f','j'});
    keys(task.responses) = 1;
end
KbQueueCreate(-1, keys);

%% Timing
session_hold_times = {[0.5, 0.4, 0.4], ...
    [0.5, 0.5, 1.0]};
time.fixation = 0.5 * expand_time;
time.baseline = 1 * expand_time;
time.cue = session_hold_times{sess.session}(1) * expand_time; % was 0.2
time.hold = session_hold_times{sess.session}(2) * expand_time; % was 0.1 - base time to hold the fix pre-tgts
time.hold_v = session_hold_times{sess.session}(3) * expand_time; % was 1.4 - seed for variable time to add
time.target = 0.067 * expand_time;
time.mask = 0.067 * expand_time;
time.reward = 1.4 * expand_time;
time.abort = 1.0 * expand_time;
sess.time = time;

%% Setup eye tracking
if sess.eye_on
    EyelinkDoTrackerSetup(el);
    sess.eyetrack = el;
end

%% Start experiment
if ~debug
    HideCursor;
end

% run instructions
run_reward_instructions(w, white);

% randomise which reward is learned about first, 0 = low, 1 = high
reward_order = [1 0];
reward_order = reward_order(randperm(numel(reward_order)));
reward_total = 0; % initiate to collate reward values

n_trials_between_breaks = 20;
trial_count = 0;

if ~any(debug)
    
    for count_reward = 1:length(reward_order)
        
        % starting parameters for single task blocks
        n_positions             = 2;
        training                = 0;
        block_locs              = [8 4; 4 4; 4 8]; % number of trials at each location for that block
        iterations              = 1; % how many times to loop over the block locs
        cues                    = sess.shapes;
        contrast                = sess.contrast;
        % to construct the trial order I follow these steps: 1) over three loops: -
        % a) gather some trials for each cue type (once for each cue type), b)
        % concatenate into a vector, c) shuffle the trial order, 2) add back to the
        % main trial params vectors, 3) repeat. This allows mixing of the trial
        % types while making sure the local probabilities don't get too out of
        % whack
        targets = [];
        ccw     = [];
        hrz     = [];
        shps    = [];
        
        for count_shapes = 1:length(cues)
            
            % get trials for that shape
            [tmp_targets, tmp_ccw, tmp_hrz] = generate_trial_block_params_for_cue(block_locs(count_shapes, :), 1);
            % add to the vectors for this iteration
            targets = [tmp_targets, targets];
            ccw     = [tmp_ccw, ccw];
            hrz     = [tmp_hrz, hrz];
            shps    = [repmat(cues(count_shapes), 1, numel(tmp_targets)), shps];
        end
        
        order   = randperm(numel(targets));
        targets = targets(order);
        ccw     = ccw(order);
        hrz     = hrz(order);
        shps    = shps(order);
        
        %%%%%%%%%% now go through trials for this level of reward
        
        for count_trials = 1:length(targets)
            
            trial_count = trial_count + 1;
            Priority(topPriorityLevel);
            [valid, response, ts] = ...
                do_trial(w, sess, task, shps(count_trials), targets(count_trials), ccw(count_trials), hrz(count_trials),...
                angle, contrast, 1, reward_order(count_reward), reward_total, training);
            Priority(0);
            
            reward_total = reward_total + response.reward_value;
            
            % print the output
            % print the output
            fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, reward_order(count_reward), targets(count_trials), shps(count_trials), contrast(1), contrast(2), ccw(count_trials), response.correct, response.rt);
            
        end
        
        % take break?
        if ~any(mod(trial_count, n_trials_between_breaks))
            take_break(w, white, task);
        end
        
    end
end
%%%%%%%%%%%% NOW RUN FINAL TEST
% create trial types, broken down by whether the cue is informative or not,
% the idea is to get small blocks that can be mixed together so that the
% local probabilities are close to what would be expected globally. But
% once all the trials are done, then each cue would have been seen the same
% number of times, in each colour

% OPEN A FILE TO RECORD THE LOG HERE
%% Generate basis for trial structure and set up log files for writing to
fclose(events_fid); % close the previous event file
events_fname = generate_filename('_ses-%d_task-learn-att-v1-test-v1_events', sess, '.tsv');
events_fid = fopen(fullfile(root_dir, sub_dir, events_fname), 'w');
fprintf(events_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'rew', 'loc', 'cue', 'co1', 'co2', 'or', 'resp', 'rt', 'rew_tot');
trl_form = '%d\t%d\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\t%d\n';

sess.set_types = [1 1 1 1 1 1];
trials = generate_blocks(sess.set_types, 0);
% save the trial table to a file so that we can get other parameters later
% (such as block number, hrz)
tbl_fname       = generate_filename('_ses-%d_task-learn-att-v1-test-v1_trls', sess, '.csv');
trial_tbl_fname = fullfile(root_dir, sub_dir, tbl_fname);
writetable(trials, trial_tbl_fname);

% take a preceding break
take_break(w, white, task);

n_trials_between_breaks = 20;
n_positions             = 2;
training                = 0;
cues                    = sess.shapes;
contrast                = sess.contrast;

for count_trials = 1:length(sess.set_types)*120
    
    % set parameters here
    trial_count = trials.trial_num(count_trials);
    trial_type  = trials.trial_type(count_trials); % which trial type
    
    % determine cue
    if trial_type == 1 || trial_type == 4
        trial_cue = cues(1);
    elseif trial_type == 2 || trial_type == 5
        trial_cue = cues(3);
    elseif trial_type == 3 || trial_type == 6
        trial_cue = cues(2);
    end
    
    target_loc = trials.position(count_trials) + 1;
    ccw = trials.ccw(count_trials);
    hrz = trials.hrz(count_trials);
    reward = trials.reward_trial(count_trials);
    
    Priority(topPriorityLevel);
    [valid, response, ts] = ...
        do_trial(w, sess, task, trial_cue, target_loc, ccw, hrz,...
        angle, contrast, 1, reward, reward_total, training);
    Priority(0);
    
    reward_total = reward_total + response.reward_value;

    % print the output
    fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, reward, target_loc, trial_cue, contrast(1), contrast(2), ccw, response.correct, response.rt, response.reward_value);
    
    % take break?
    if ~any(mod(trial_count, n_trials_between_breaks))
        take_break_w_feedback(w, white, task, trial_count, length(sess.set_types)*120, n_trials_between_breaks, reward_total);
    end    
    
end

% close the behaviour log
fclose(events_fid);
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




