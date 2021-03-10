% 'learn-att-v1_step1-gabors-v1'
% Learn Gabor component of visual orienting task
% K. Garner, 2019
% 
% Borrows from C. Nolan 2017 HABIT_REWARD EXP
%
% NOTES:
%
% Dimensions calibrated for [] (with viewing distance
% of 570 mm)

% Psychtoolbox 3.0.14 - Flavor: beta - Corresponds to SVN Revision 8301
% Matlab R2017a

% this code presents gratings on the left and right sides of the screen
% (LVF), participants make a respone with 1 of 2 keys to indicate whether
% one of the gratings was rotated clockwise or counterclockwise. After
% 18/20 correct trials, the  grating is followed by a mask. 
% the luminance of the gratings is adjusted until people perform at 80% 
% correct (16/20)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear all the tings
clear all
clear mex

% debug just automatically assigns some subject numbers/starting parameters, skips the initital 20 training 
% trials, and results in the cursor not being hidden
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
    sess.sub_num = 5;
    sess.session = 2;
    sess.eye_on  = 0;
    sess.skip_init_train = 0;
else
    sess.sub_num = input('Subject Number? ');
    sess.session = 2;
    sess.eye_on  = input('Eye tracker? (0 or 1)? ');
    sess.skip_init_train = 0;
end

% time cheats
expand_time = 1;

% directory things
parent = cd;

%% Randomisation seed now based on subject and session number
stage = '4';
r_num = ['4' num2str(sess.sub_num) '000' num2str(sess.session) stage];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;

run_setup;


%% Generate json metadata for this task and session
addpath('JSONio');
if sess.sub_num < 10
    sub_dir = sprintf([proj_loc, '/', 'sub-0%d/ses-0%d/func'], sess.sub_num, sess.session);
else
    sub_dir = sprintf([proj_loc, '/', 'sub-%d/ses-0%d/func'], sess.sub_num, sess.session);
end
if ~(exist(sub_dir))
    mkdir(sub_dir);
end

%% meta data stuff
task_str = 'learnGabors';
json_log_fname = generate_filename(['_ses-0%d_task-' task_str], sess, '.json');

meta_data.sub          = sess.sub_num;
meta_data.session      = sess.session;
meta_data.date         = datetime;
meta_data.task         = task_str;
meta_data.BIDS         = 'v1.0.2';
meta_data.resp_order   = sess.resp_order;
if ~any(sess.resp_order)
    meta_data.resp_key      = 'clockwise: f, anticlockwise: j';
else
    meta_data.resp_key      = 'clockwise: j, anticlockwise: f';
end
meta_data.map          = 'j = 2@, f = 3#';

project_dir    = sub_dir;

%% Generate basis for trial structure and set up log files for writing to
events_fname = generate_filename(['_ses-0%d_task-' task_str '_trls'], sess, '.tsv');
events_fid = fopen(fullfile(sub_dir, events_fname), 'w');
fprintf(events_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'loc', 'co1', 'co2', 'or', 'resp', 'rt');
trl_form = '%d\t%d\t%d\t%d\t%.4f\t%.4f\t%d\t%d\t%.3f\n';
events_json = generate_filename(['_ses-0%d_task-' task_str '_trls'], sess, '.json');
generate_event_data_jsons(sub_dir, events_json);

%% start running experiment
if ~debug
    HideCursor;
    
end

% starting parameters
contrast_min = 0.05;
calibrate    = 0;
accuracy     = 0;
trial_count  = 0;
min_trials   = 20; % min number of trials to sample accuracy from (pre-calibration)
done         = 0; % finished flag
n_positions  = 2;
reward       = 2; % no rewards available
cols4cues = repmat([sess.config.stim_dark, sess.config.stim_dark, sess.config.stim_dark]', 1, 2);
training = 2;
n_train_per_position = 4;
[targets, ccw, hrz] = generate_trial_block_params(n_train_per_position, n_positions);
contrast = [0.4, 0.4];

%%%%%%%% MASKING INSTRUCTIONS HERE
run_masking_instructions(w, gabor_rect, white, grey, 1, task);

for i = 1:numel(targets)
    trial_count = trial_count + 1;
    ci = targets(i);
    Priority(topPriorityLevel);
    [valid, response, ts] = do_trial(w, sess, task, -1, targets(i), ccw(i), ...
        hrz(i), cols4cues, angle, contrast, 1, reward, 0, training);
    Priority(0);

    % print the output file
    fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, targets(i), 1, 1, ccw(i), response.correct, response.rt);
    start_ts = ts.end;
end

% now conduct tuning of luminance over two stages. Stage 1 (32 trials): run through a
% broad range of luminance values to hone in on a suggestion. In this
% stage, both target and distractor are set to the same contrast on each
% trial. Therefore, we ask the probability that the response to location x
% will be correct, given that both x and y are the same contrast.
% Stage 2 (32 trials?): refining the contrast values over a finer grained range. At this
% point, the luminance of x and y will be unique, so we ask the probability
% the response to location x will be correct, when y is at the contrast
% where the probability of getting a response to y correct is [value]?
% The contrast values applied in the final experiment will be the values
% for x and y derived from stage 2.
n_calibrate_per_position = 64;
ni1 = floor(n_calibrate_per_position / 2); % n per position for coarse calibration
ni2 = ceil( n_calibrate_per_position / 2); % n per position for fine calibration
% current settings use -range/2:grain:range/2 (101) options centred on
% contrast(1) or contrast (2) = .04, with the default Weibull
% settings. sd is currently lower (.15) as advised as this prevents large jumps
% between the two staircases - to be titrated/tested
% QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,[grain],[range],[plotIt])
guessSD = .15;
pThresh = .75;
bet     = 3.5;
delt    = .01;
gamm    = .5;
grn     = .01;
rng     = 1;
q = [QuestCreate(contrast(1), guessSD, pThresh, bet, delt, gamm, grn, rng), ...
     QuestCreate(contrast(2), guessSD, pThresh, bet, delt, gamm, grn, rng)];
 
    % Start with a set of targets between 0.25 and 0.65 intensity.
    [targets, ccw, hrz] =  generate_trial_block_params(ni1, n_positions);
    contrasts = reshape(repmat(linspace(0.25, 0.65, ni1)', [1, n_positions]), 1, []);
    

 % set break params   
n_trials_between_breaks = 24;
    for i = 1:numel(targets)
        
        trial_count = trial_count + 1;
        
        % perform trial
        ci = targets(i);
        contrast(ci) = contrasts(i);
        Priority(topPriorityLevel);
        [valid, response, ts] = ...
            do_trial(w, sess, task, -1, ci, ccw(i), hrz(i), cols4cues, ...
            angle, contrast(ci), 1, reward, 0, training);
        
        Priority(0);
        % update staircase
        q(ci) = QuestUpdate(q(ci), contrast(ci), response.correct);
        ct(i, :) = {i, targets(i), ccw(i), hrz(i), contrast(ci), ...
            response.ccw, response.correct, response.rt, ...
            QuestMean(q(ci))};
        start_ts = ts.end;
        
        % update trial log
        % print the output file
        fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, ci, contrast(ci), contrast(ci), ccw(i), response.correct, response.rt);
        
        % take break?
        if ~any(mod(trial_count, n_trials_between_breaks))
           take_break(w, white, task); 
        end
    end
% Now fine tune the estimates.
si = i;
    [targets, ccw, hrz] =  generate_trial_block_params(ni2, n_positions);
    for i = 1:numel(targets)
 
        trial_count = trial_count + 1;
        
        % perform trial
        ci = targets(i);
	    contrast(ci) = QuestQuantile(q(ci));
        Priority(topPriorityLevel);
        [valid, response, ts] = ...
                do_trial(w, sess, task, -1, ci, ccw(i), hrz(i),...
                         cols4cues, angle, contrast, 1, reward, 0, training);
        % update staircase       
        Priority(0);
        q(ci) = QuestUpdate(q(ci), contrast(ci), response.correct);
	    ct(i+si, :) = {i+si, targets(i), ccw(i), hrz(i), contrast(ci), ...
                       response.ccw, response.correct, response.rt, ...
                       QuestMean(q(ci))};
        start_ts = ts.end;
        
        % update trial log
        % print the output file
        fprintf(events_fid, trl_form, sess.sub_num, sess.session, trial_count, ci, contrast(1), contrast(2), ccw(i), response.correct, response.rt);
        % take break?
        if ~any(mod(trial_count, n_trials_between_breaks))
            take_break(w, white, task);
        end
        
     end
     contrast(1) = max(QuestMean(q(1)), contrast_min);
     contrast(2) = max(QuestMean(q(2)), contrast_min);

% now we have contrast info, save the metadata file
meta_data.target_contrasts = contrast;     
generate_meta_data_jsons(meta_data, project_dir, json_log_fname);

% close the behaviour log
fclose(events_fid);
% end this stage of the experiment
instructions = ...
    sprintf(['Thanks! You have finished level 1\n' ...
    'Level 2 coming up!\n']);
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
    
