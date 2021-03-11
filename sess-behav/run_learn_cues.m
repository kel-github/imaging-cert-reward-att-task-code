% 'learn-att-v1_step2-cues-v1'
% Learn cue-shape-probability contingency component of visual orienting
% task
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
% clear all the tings
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
Screen('Preference', 'SkipSyncTests', 0);

sess.data_loc = '~/Documents/striwp1';
session_data_loc = sess.data_loc;
sess.date = clock;

if debug
    sess.sub_num = 54;
    sess.session = 1;
    sess.eye_on  = 0;
    sess.skip_init_train = 1;
else
    sess.sub_num = input('Subject Number? ');
    sess.session = 1;
    sess.eye_on  = 0;
    sess.skip_init_train = 0;
    %sess.contrast = [.0739, .05];
end

% time cheats
expand_time = 1;

parent = cd;


%% Randomisation seed now based on subject and session number
stage = '2';
r_num = ['1' num2str(sess.sub_num) '000' num2str(sess.session) stage];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;

run_setup;

%% Generate the folder for this session
if sess.sub_num < 10
    subref = '-00%d';
elseif sess.sub_num > 9 && sess.sub_num < 100
    subref = '-0%d';
else
    subref = '-%d';
end
sub_dir = [session_data_loc '/' sprintf(['sub' subref '/ses-0%d'], sess.sub_num, sess.session) '/behav'];
if ~(exist(sub_dir))
    mkdir(sub_dir);
end


%% Generate json metadata for this task and session
addpath('JSONio/');
task_str = 'learnCues'; 
json_log_fname = generate_filename(['_ses-0%d_task-', task_str], sess, '.json');
meta_data.sub          = sess.sub_num;
meta_data.session      = sess.session;
meta_data.date         = datetime;
meta_data.task         = 'learnCues';
meta_data.BIDS         = 'v1.0.2';
meta_data.Matlab       = 'v';
meta_data.PTB          = 'v';
meta_data.PC           = ' ';
meta_data.display      = ' ';
meta_data.display_dist = '57 cm';
meta_data.resp_order   = sess.resp_order;
if sess.resp_order == 1
    meta_data.resp_key      = 'clockwise: f, anticlockwise: j';
else
    meta_data.resp_key      = 'clockwise: j, anticlockwise: f';
end
root_dir       = pwd;
project_dir    = sub_dir;
 
% get filename to read contrast params from initital session
if ~any(debug)
    json_rd_fname = generate_filename('_ses-0%d_task-learnGabors', sess, '.json');
    tmp = jsonread(fullfile(sub_dir, json_rd_fname));
    meta_data.target_contrasts = tmp.target_contrasts;
    sess.contrast = meta_data.target_contrasts; % for use during the session
    clear tmp
    meta_data.target_contrasts = sess.contrast;
else
    meta_data.target_contrasts = [.2 .2];
end

generate_meta_data_jsons(meta_data, project_dir, json_log_fname);

%% Generate basis for trial structure and set up log files for writing to
events_fname = generate_filename(['_ses-0%d_task-' task_str '_events'], sess, '.tsv');
events_fid = fopen(fullfile(sub_dir, events_fname), 'w');
fprintf(events_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'loc', 'cue', 'co1', 'co2', 'or', 'resp', 'rt');
trl_form = '%d\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\n';
events_json = generate_filename(['_ses-0%d_task-' task_str '_events'], sess, '.json');
generate_event_data_jsons(sub_dir, events_json);

%% Start experiment
if ~debug
    HideCursor;
end

% run instructions
run_learn_cue_instructions(w, white); 

% starting parameters for single task blocks
n_positions             = 2;
training                = 1;
cues                    = sess.shapes;

if ~any(debug)
    contrast            = sess.contrast;
else
    contrast            = [0.5 0.5];
end

 % set break params   
n_trials_between_breaks = 20;
trial_count      = 0;

%%%%%%%%%% now do the mixed block
block_locs              = [16 4; 8 8; 4 16]; % number of trials at each location for that block
iterations              = 2; % how many times to loop over the block locs

cols4cues = repmat([sess.config.stim_dark, sess.config.stim_dark, sess.config.stim_dark]', 1, 2);

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
for count_iterations = 1:iterations
    
    within_iteration_targets = [];
    within_iteration_ccw     = []; 
    within_iteration_hrz     = [];
    within_iteration_shps    = [];
    
for count_shapes = 1:length(cues)
    
    % get trials for that shape
    [tmp_targets, tmp_ccw, tmp_hrz] = generate_trial_block_params_for_cue(block_locs(count_shapes, :), 1);
    % add to the vectors for this iteration
    within_iteration_targets = [tmp_targets, within_iteration_targets];
    within_iteration_ccw     = [tmp_ccw, within_iteration_ccw];
    within_iteration_hrz     = [tmp_hrz, within_iteration_hrz];
    within_iteration_shps    = [repmat(cues(count_shapes), 1, numel(tmp_targets)), within_iteration_shps];    
end
    order   = randperm(numel(within_iteration_targets));
    targets = [targets, within_iteration_targets(order)];
    ccw     = [ccw, within_iteration_ccw(order)];
    hrz     = [hrz, within_iteration_hrz(order)];
    shps    = [shps, within_iteration_shps(order)];
end

for count_trials = 1:length(targets)
    
    trial_count = trial_count + 1;
    Priority(topPriorityLevel);
    [valid, response, ts] = ...
        do_trial(w, sess, task, shps(count_trials), targets(count_trials), ccw(count_trials), hrz(count_trials),...
        cols4cues, angle, contrast, 1, 2, 0, training);
    Priority(0);
    
    % print the output
    fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, targets(count_trials), shps(count_trials), contrast(1), contrast(2), ccw(count_trials), response.correct, response.rt);
    
    
    % take break?
    if ~any(mod(trial_count, n_trials_between_breaks))
        take_break(w, white, task);
    end
end

% close the behaviour log
fclose(events_fid);
% end this stage of the experiment
instructions = ...
    sprintf(['Well done! You have finished level 2\n' ...
    'see the experimenter for instructions for\n' ...
    'level 3!\n']);
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