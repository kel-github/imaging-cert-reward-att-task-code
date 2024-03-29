% Run test of mixed trials in the MRI scanner
% Run once for one run
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
    sess.session = 1;
    sess.eye_on  = 0;

else
    sess.sub_num = input('Subject Number? ');
    sess.session = input('Session? ');
    sess.eye_on  = input('Eye tracker? (0 or 1)? ');
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

%% Generate json metadata for this task and session
addpath('JSONio/');
if sess.sub_num < 10
    sub_dir = sprintf('sub-0%d_ses-%d_task-mri-val-inf-att-v1', sess.sub_num, sess.session);
else
    sub_dir = sprintf('sub-%d_ses-%d_task-mri-val-inf-att-v1', sess.sub_num, sess.session);
end
if ~(exist(sub_dir))
    mkdir(sub_dir);
end
root_dir = cd;
json_log_fname = generate_filename('_ses-%d_task-mri-val-inf-att-v1', sess, '.json');
meta_data.sub          = sess.sub_num;
meta_data.session      = sess.session;
meta_data.date         = datetime;
meta_data.task         = 'mri-val-inf-att-v1';
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
if ~any(debug)
    json_rd_fname = generate_filename('_ses-%d_task-learn-att-v1-gabors', sess, '.json');
    tmp = jsonread(fullfile(sub_dir, json_rd_fname));
    meta_data.target_contrasts = tmp.target_contrasts;
    sess.contrast = meta_data.target_contrasts; % for use during the session
    clear tmp
else
    meta_data.target_contrasts = [.5, .5];
    sess.contrast = meta_data.target_contrasts; % for use during the session
end

generate_meta_data_jsons(meta_data, root_dir, project_dir, json_log_fname);

%% Generate basis for trial structure and set up log files for writing to
events_fname = generate_filename('_ses-%d_task-mri-val-inf-att-v1_events', sess, '.tsv');
events_fid = fopen(fullfile(root_dir, sub_dir, events_fname), 'w');
fprintf(events_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'rew', 'loc', 'cue', 'co1', 'co2', 'or', 'resp', 'rt');
trl_form = '%d\t%d\t%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\n';

%% Start experiment
if ~debug
    HideCursor;
end

% run instructions
run_reward_instructions(w, white);

% randomise which reward is learned about first, 0 = low, 1 = high
learn_reward_order = sess.learn_order; % high and low, 
reward_total = 0; % initiate to collate reward values
n_trials_between_breaks = 20;
trial_count = 0;

if ~any(sess.skip_init_train)
    
    for count_reward = 1:length(learn_reward_order)
        
        % starting parameters for single task blocks
        n_positions             = 2;
        training                = 0;
        block_locs              = [8, 8]; % number of trials at each location for that block
        iterations              = 1; % how many times to loop over the block locs
        contrast                = sess.contrast;
        % to construct the trial order I follow these steps: 1) over three loops: -
        % a) gather some trials for each cue type (once for each cue type), b)
        % concatenate into a vector, c) shuffle the trial order, 2) add back to the
        % main trial params vectors, 3) repeat. This allows mixing of the trial
        % types while making sure the local probabilities don't get too out of
        % whack
                   
        % get trials for that shape
        % out rest of params
        [targets, ccw, hrz] = generate_trial_block_params_for_cue(block_locs, n_positions);
        % add to the vectors for this iteration
        % is the same as where the target is in this instance
        
        % get the correct colour map
        switch learn_reward_order( count_reward )
            case 1
                % get the colour to be learned
                cCols = [sess.reward_colours(:,1), [sess.config.stim_dark, sess.config.stim_dark, sess.config.stim_dark]'];               
                % now do informative set
                tmp = ones(1, length(targets));
                tmp = get_reward_order(tmp, targets, .2, 0);
            case 2
                cCols = [sess.reward_colours(:,2), [sess.config.stim_dark, sess.config.stim_dark, sess.config.stim_dark]'];
                tmp = zeros(1, length(targets)); 
                tmp = get_reward_order(tmp, targets, .2, 1);
        end
        
        % concatenate trials and mix together to get full set
        order   = randperm(numel(targets));
        targets = targets(order);
        ccw     = ccw(order);
        hrz     = hrz(order);
        reward_order = tmp;
        reward_order = reward_order(order);
 
        %%%%%%%%%% now go through trials for this level of reward
        
        for count_trials = 1:length(targets)
            
            trial_count = trial_count + 1;
            % put the colour on the target location
            col_map = [cCols(:, targets(count_trials)), cCols(:, max(targets)+1-targets(count_trials))];

            trial_count = trial_count + 1;
            Priority(topPriorityLevel);
            [valid, response, ts] = ...
                do_trial(w, sess, task, -1, targets(count_trials), ccw(count_trials), hrz(count_trials), col_map, ...
                angle, contrast, 1, reward_order(count_trials), reward_total, training);
            Priority(0);
            
            reward_total = reward_total + response.reward_value;
            
            % print the output
            fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, reward_order(count_reward), targets(count_trials), -1, contrast(1), contrast(2), ccw(count_trials), response.correct, response.rt);
            
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
trials = generate_blocks_FourRewardCont(2); % for 720 trials
% save the trial table to a file so that we can get other parameters later
% (such as block number, hrz)
tbl_fname       = generate_filename('_ses-%d_task-learn-att-v1-test-v1_trls', sess, '.csv');
trial_tbl_fname = fullfile(root_dir, sub_dir, tbl_fname);
writetable(trials, trial_tbl_fname);

% take a preceding break
take_break(w, white, task);


run_task_instructions(w, white);


n_trials_between_breaks = 20;
n_positions             = 2;
training                = 0;
% cues                    = [1, 3, 2];
contrast                = sess.contrast;

%%
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
            cCols(:, 3-target_loc) = sess.reward_colours(:,2);
        case 3
            cCols = [sess.reward_colours(:,2), sess.reward_colours(:,2)];
        case 4
            cCols = zeros(3,2);
            cCols(:, target_loc)   = sess.reward_colours(:,2);
            cCols(:, 3-target_loc) = sess.reward_colours(:,1);
    end
    
   
    Priority(topPriorityLevel);
    [valid, response, ts] = ...
        do_trial(w, sess, task, trial_cue, target_loc, ccw, hrz, cCols,...
                 angle, contrast, 1, reward, reward_total, training);
    Priority(0);
    
    reward_total = reward_total + response.reward_value;

    % print the output
    fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, reward, target_loc, trial_cue, contrast(1), contrast(2), ccw, response.correct, response.rt, response.reward_value);
    
    % take break?
    if ~any(mod(trial_count, n_trials_between_breaks))
        take_break_w_feedback(w, white, task, trial_count, max(trials.trial_num), n_trials_between_breaks, reward_total);
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




