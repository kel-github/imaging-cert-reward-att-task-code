% Influence of reward on habit formation and extinction task
% C. Nolan 2017
% Borrows from K. Garner 2016 REL VAL/FREQ TAG EXP
%
% NOTES:
%
% Dimensions calibrated for G-Master GB2788HS (with viewing distance
% of 570 mm)
%
% Run with 512 Hz sample rate, aux (if want diode input), 64 channels
% and 8 externals.
%
% Psychtoolbox 3.0.14 - Flavor: beta - Corresponds to SVN Revision 8301
% Matlab R2017a

% clear all the tings
clear all
clear mex

debug = 0;
skip_train = 0;

% initialise mex files etc
KbCheck;
KbName('UnifyKeyNames');
% RestrictKeysForKbCheck([192]);
GetSecs;
AssertOpenGL
% Screen('Preference', 'SkipSyncTests', 1);
% if debug
%     PsychDebugWindowConfiguration(1, 0.5);
% end
% dbug = input('Debug Mode? (1 or 0) ');
sess.date = clock;
if debug
    sess.sub_num = 2;
    sess.session = 1;
    sess.diode = 0;
    sess.eye_on = 0;
else
    sess.sub_num = input('Subject Number? ');
    sess.session = input('Session? ');
    sess.diode = input('Diode? (0 or 1) ');
    sess.eye_on = input('Eye tracker? (0 or 1)? ');
end
% sess.diode = input('Diode?' );

% time cheats
expand_time = 1;

parent = cd;

%% Monitor settings
monitor = 0;
ref_rate = 60;
resolution = [1024 768]; % might change this with psychtoolbox - get stuff

%% Parameters
% Randomly assign cues to probability-reward states: 3x2 matrix where rows
% are probabilities and columns are reward states (see generate_trials for
% index meanings - logicals will be value+1 i.e. logical 0 is index 1,
% logical 1 is index 2... Matlab indexing is the worst).
% Generate using rng based on subject number alone.
r_num = ['1' num2str(sess.sub_num)];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;
sess.cue_mapping = reshape(randperm(6), [], 2);

% Block order permutations
% 0 = Non-reward first, 1 = reward first
block_order = [0, 1, 1, 0, 1, 0, 0, 1];
% Response order permutation: 0 means 'f' is clockwise and 'j' is
% counterclockwise, 1 means the reverse. Counterbalances between every set
% of two consecutive participants but also between block orders.
response_order = [0, 1, 0, 1, 0, 1, 0, 1];

% Reward scope.
2_base_extinct = 1;
sess.reward_bonus_extinct = 4;
sess.reward_base_low = 5;
sess.reward_bonus_low = 5;
sess.reward_base = 50;
sess.reward_bonus = 50;
sess.reward_base_rt = 0.85;
sess.reward_max_bonus_rt = 0.35;

% Subject and session parameters
sess.block_order = ...
    block_order(mod(sess.sub_num-1, length(block_order))+1);
sess.response_order = ...
    response_order(mod(sess.sub_num-1, length(response_order))+1);

% Trial information
% Per session set order (same for all participants).
% Session is row, set is column, two sessions, four sets per session (and
% two blocks per set).
set_types = [0, 0, 0, 1;
             0, 0, 1, 1;
             1, 1, 1, 2;
             2, 3, 3, 3];
n_positions = 2;

sess.set_types = set_types(mod(sess.session-1, size(set_types, 1))+1, :);

% Calibration is done per position.
% Both training and calibration per position need to be a multiple
% of four.
n_calibrate_per_position = 32;
n_train_per_position = 24;
if skip_train
    n_train_per_position = 0;
end

% Angle of gabor target
angle = 45;

%% Randomisation seed now based on subject and session number
r_num = ['1' num2str(sess.sub_num) '000' num2str(sess.session)];
r_num = str2double(r_num);
rng(r_num);
rngstate = rng;

%% Initialise Eyelink
if sess.eye_on
    fixation_eye_box = CenterRectOnPointd([0 0 100 100], xc, yc);
    el = EyelinkInitDefaults(w); % Initialization
    if ~EyelinkInit(0) % Fail nice if you are going to fail
        fprintf('Eyelink Init aborted.\n');
        return;
    end
    [sess.eyelink_version, sess.eyelink_vstring] = ...
        Eyelink('GetTrackerVersion');
    % fprintf('Running experiment on a ''%s'' tracker.\n', vs ); % optional
    edf_file = generate_filename('habit_reward_eyetrack', r_num, ...
                                sess.date, 'edf');
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

%% Save session information
sess_log_fname = generate_filename('habit_reward_sess_log', sess, ...
                                   r_num, 'txt', 0);
ssid = fopen(sess_log_fname, 'w');
fprintf(ssid, '# Block order key: 0 = non-reward / reward\n');
fprintf(ssid, '#                  1 = reward / non-reward\n');
fprintf(ssid, '# Response order key: 0 = f for cw, j for ccw\n');
fprintf(ssid, '#                     1 = f for ccw, j for cw\n');
fprintf(ssid, '# Reward location key: 0 = reward on top row\n');
fprintf(ssid, '#                      1 = reward on bottom row\n');
fprintf(ssid, '# Cue mapping key: 1 = circle\n');
fprintf(ssid, '#                  2 = trapezium\n');
fprintf(ssid, '#                  3 = triangle\n');
fprintf(ssid, '#                  4 = diamond\n');
fprintf(ssid, '#                  5 = pentagon\n');
fprintf(ssid, '#                  6 = star\n');
fprintf(ssid, 'Subject number: %d\n', sess.sub_num);
fprintf(ssid, 'Subject session: %d\n', sess.session);
fprintf(ssid, 'Base reward: %d\n', sess.reward_base);
% fprintf(ssid, 'Block order: %d\n', sess.block_order);
fprintf(ssid, 'Non-reward cues: [%d %d %d] # 80 / 20 / 50\n', ...
        sess.cue_mapping(:, 1));
fprintf(ssid, 'Response order: %d\n', sess.response_order);
fprintf(ssid, 'Reward cues: [%d %d %d] # 80 / 20 / 50\n', ...
        sess.cue_mapping(:, 2));
fprintf(ssid, 'Eyetracking / version: %d / %s', ...
        sess.eye_on, sess.eyelink_vstring);
fclose(ssid);

%% Generate trials
trial_fname = generate_filename('habit_reward_trials', sess, r_num, ...
                                'csv', 0);
% trials = generate_trials(n_blocks, n_trials_pspb, 1, sess.block_order);
% trials = generate_mixed_blocks(n_blocks);
% trials = generate_reward_blocks(n_blocks);
trials = generate_blocks(sess.set_types, sess.block_order);
writetable(trials, trial_fname);
trials.response = zeros(height(trials), 1);
trials.RT = ones(height(trials), 1) * -1;

% position_shift = -1 * ones(1, 4);
contrast_min = 0.1;
calibrated = 0;
calibrate_fname = generate_filename('habit_reward_calibrate', sess, ...
                                    r_num, 'csv', 1);
contrast = [0.4, 0.4];
if exist(['.' filesep calibrate_fname], 'file') == 2
    % If the calibration file exists, the last orientations for each target
    % are the best estimates.
    ct = readtable(calibrate_fname);
    ti = max(ct.trial_num(ct.position == 1 | ct.position == 3));
    contrast(1) = ct.estimate(ti);
    ti = max(ct.trial_num(ct.position == 2 | ct.position == 4));
    contrast(2) = ct.estimate(ti);
    calibrated = 1;
else
    names = {'trial_num', 'position', 'ccw', 'horizontal', 'contrast', ...
             'response', 'correct', 'RT', 'estimate'};
    ct = array2table(zeros(n_calibrate_per_position*n_positions, 9), ...
                     'VariableNames', names);
end

results_log_fname = generate_filename('habit_reward_resp_log', sess, ...
                                       r_num, 'csv', 0);
rsid = fopen(results_log_fname, 'w');
fprintf(rsid, 'trial_num, block_num, trial_type, reward_trial, ');
fprintf(rsid, 'condition_type, probability, position, ');
fprintf(rsid, 'shift, horizontal, response, correct, RT, reward, ');
fprintf(rsid, 'baseline_ts, cue_ts, hold_ts, target_ts, ');
fprintf(rsid, 'mask_ts, pending_ts, response_ts, reward_ts\n');

trig_log_fname = generate_filename('habit_reward_trig_log', sess, ...
                                   r_num, 'csv', 0);
trid = fopen(trig_log_fname, 'w');
fprintf(trid, 'trigger_num, timestamp');
sess.trid = trid;


%% SCREEN / DRAWING
screen_index = max(Screen('Screens'));
white = WhiteIndex(screen_index);
black = BlackIndex(screen_index);
grey = white * 0.5;
stim_dark = white * 0.2;
sess.config.white = white;
sess.config.black = black;
sess.config.grey = grey;
sess.config.stim_dark = stim_dark;

[w, rect] = Screen('OpenWindow', screen_index, grey, [], [], [], 0, 8);
Screen(w, 'Flip');
[x_pix, y_pix] = Screen('WindowSize', w);
xc = x_pix / 2;
yc = y_pix / 2;
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
if sess.response_order
    task.responses = KbName({'c','f'});
    keys(task.responses) = 1;
else
    task.responses = KbName({'f','c'});
    keys(task.responses) = 1;
end
KbQueueCreate(-1, keys);

%% Timing
session_hold_times = {[0.5, 0.75, 2.2], ...
                      [0.5, 0.5, 1.0], ...
                      [0.5, 0.5, 1.0], ...
                      [0.5, 0.5, 1.0]};
time.fixation = 0.5 * expand_time;
time.baseline = 1 * expand_time;
time.cue = session_hold_times{sess.session}(1) * expand_time; % was 0.2
time.hold = session_hold_times{sess.session}(2) * expand_time; % was 0.1
time.hold_v = session_hold_times{sess.session}(3) * expand_time; % was 1.4
time.target = 0.067 * expand_time;
time.mask = 0.067 * expand_time;
time.reward = 1.0 * expand_time;
time.abort = 1.0 * expand_time;
sess.time = time;

%% Triggers
% Trigger code courtesy of Sara Assecondi
% labjack = lab_init_sa; % INIT LABJACK
labjack = 0;
sess.labjack = labjack;

% trigger codes (1-8)
triggers.trial_start = 1;
triggers.baseline = 2;
triggers.cue = 3;
triggers.hold = 4;
triggers.target = 5;
triggers.mask = 6;
triggers.response = 7;
triggers.reward = 8;
sess.triggers = triggers;

%% Setup test diode colours
test_base_rect = [0 0 150 150]; % double check this - 
if sess.diode
    test_colors = [black black black; 255 255 255];
else
    test_colors =  [black black black; black black black];
end

%% Setup eye tracking
if sess.eye_on
    EyelinkDoTrackerSetup(el);
    sess.eyetrack = el;
end

%% Start experiment
if ~debug
    HideCursor;
end

% draw_targets(w, gabor_id, gabor_rect, 1, 45, 1, [0.1, 0.6], white, grey);
% Screen('Flip', w);
% start_ts = KbWait;
% WaitSecs(0.5);
% draw_masks(w, gabor_rect, 0.5*get_ppd(), white, grey);
% Screen('Flip', w);
% start_ts = KbWait;
% WaitSecs(0.5);
% draw_pedestals(w, 1:2, gabor_rect, 0.5*get_ppd(), white, grey);
% Screen('Flip', w);
% start_ts = KbWait;
% WaitSecs(0.5);
% for i = 1:6
%     draw_stim(w, i, white);
%     Screen('Flip', w);
%     start_ts = KbWait;
%     WaitSecs(0.5);
% end

if ~calibrated && ~debug && sess.session == 1
    Screen('TextStyle', w, 1);
    Screen('TextSize', w, 30); 
    instructions = ...
        sprintf(['During each trial of this task, you will see two\n'...
                 'gratings presented, one each on the left and right\n'...
                 'on the screen.\n\n'...
                 'Press a key now to see an example.\n']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    draw_targets(w, gabor_id, gabor_rect, 1, 45, 0, 1.0, white, grey);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['The goal is to identify which direction the target\n'...
                 'grating has been rotated. The target is the grating\n'...
                 'that is not vertical or horizontal.\n\n'...
                 'Press a key now to see a clockwise example.\n']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['Here the target on the right is rotated clockwise.\n']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    draw_targets(w, gabor_id, gabor_rect, 2, -45, 1, 1.0, white, grey);
    draw_placeholders(w, 2, white);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['The target presentations will be very brief. After\n'...
                 'the targets are presented, the two possible\n'...
                 'positions will be masked.\n\n'...
                 'Press a key now to see the masks.\n']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    draw_masks(w, gabor_rect, 10, white, grey);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['It is very important that you keep your eyes fixed\n'...
                 'on the cross in the middle of the screen at all\n'...
                 'times.\n\n'...
                 'Press a key to continue.']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
end  % first session information

if ~calibrated && ~debug
    % Start orientation tuning.
    Screen('TextStyle', w, 1);
    Screen('TextSize', w, 30); 
    instructions = ...
        sprintf(['Press %s for clockwise and %s for counterclockwise.\n'...
                 'Press any key to start\n'], ...
                KbName(task.responses(1)), KbName(task.responses(2)));
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    
    % Training (with tuning during training).
    % Get an order for targets.
    targets = reshape(repmat(1:n_positions, [n_train_per_position, 1]), 1, []);
    ccw = repmat([0, 1], [1, numel(targets)/2]);
    hrz = repmat([0, 0, 1, 1], [1, numel(targets)/4]);
    order = randperm(numel(targets));
    targets = targets(order);
    ccw = ccw(order);
    hrz = hrz(order);
    contrast = [1.0, 1.0];
    for i = 1:numel(targets)
        ci = targets(i);
        Priority(topPriorityLevel);
        [valid, response, ts] = ...
            do_trial(w, sess, task, start_ts, targets(i)>2, -1, ...
                     targets(i), ccw(i), hrz(i), angle, contrast(ci), 0, 0);
        Priority(0);
        % Drop contrast so it hits 0.4 by the end of training.
        contrast(ci) = contrast(ci) - 0.6 / n_train_per_position;
        start_ts = ts.end;
    end
    %contrast

    contrast = [0.4, 0.4];
    % Start orientation tuning.
    Screen('TextStyle', w, 1);
    Screen('TextSize', w, 30); 
    instructions = ...
        sprintf(['Press %s for clockwise and %s for counterclockwise.\n'...
                 'Press any key to start\n'], ...
                KbName(task.responses(1)), KbName(task.responses(2)));
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    
    % Reset the tuning and calibrate.
    % Get an order for targets.
    ni1 = floor(n_calibrate_per_position / 2);
    ni2 = ceil(n_calibrate_per_position / 2);
    q = [QuestCreate(contrast(1), 0.15, 0.75, 3.5, 0.01, 0.5, 0.01, 1.0), ...
         QuestCreate(contrast(2), 0.15, 0.75, 3.5, 0.01, 0.5, 0.01, 1.0)];
    % Start with a set of targets between 0.4 and 0.7 intensity.
    targets = reshape(repmat(1:n_positions, [ni1, 1]), 1, []);
    contrasts = reshape(repmat(linspace(0.25, 0.65, ni1)', [1, n_positions]), 1, []);
    ccw = repmat([0, 1], [1, numel(targets)/2]);
    hrz = repmat([0, 0, 1, 1], [1, numel(targets)/4]);
    order = randperm(numel(targets));
    targets = targets(order);
    contrasts = contrasts(order);
    ccw = ccw(order);
    hrz = hrz(order);
    for i = 1:numel(targets)
        ci = targets(i);
        contrast(ci) = contrasts(i);
        Priority(topPriorityLevel);
        [valid, response, ts] = ...
            do_trial(w, sess, task, start_ts, targets(i)>2, -1, ...
                     targets(i), ccw(i), hrz(i), angle, contrast(ci), 0, 0);
        
        Priority(0);
        q(ci) = QuestUpdate(q(ci), contrast(ci), response.correct);
        ct(i, :) = {i, targets(i), ccw(i), hrz(i), contrast(ci), ...
                    response.ccw, response.correct, response.rt, ...
                    QuestMean(q(ci))};
        start_ts = ts.end;
    end
    % Now fine tune the estimates.
    si = i;
    targets = reshape(repmat(1:n_positions, [ni2, 1]), 1, []);
    ccw = repmat([0, 1], [1, numel(targets)/2]);
    hrz = repmat([0, 0, 1, 1], [1, numel(targets)/4]);
    order = randperm(numel(targets));
    targets = targets(order);
    ccw = ccw(order);
    hrz = hrz(order);
    for i = 1:numel(targets)
        ci = targets(i);
        contrast(ci) = QuestQuantile(q(ci));
        Priority(topPriorityLevel);
        [valid, response, ts] = ...
            do_trial(w, sess, task, start_ts, targets(i)>2, -1, ...
                     targets(i), ccw(i), hrz(i), angle, contrast, 0, 0);
        
        Priority(0);
        q(ci) = QuestUpdate(q(ci), contrast(ci), response.correct);
        ct(i+si, :) = {i+si, targets(i), ccw(i), hrz(i), contrast(ci), ...
                       response.ccw, response.correct, response.rt, ...
                       QuestMean(q(ci))};
        start_ts = ts.end;
    end
    contrast(1) = max(QuestMean(q(1)), contrast_min);
    contrast(2) = max(QuestMean(q(2)), contrast_min);
    % Write table
    writetable(ct, calibrate_fname);
end
contrast

% Shape positions.
Screen('TextStyle', w, 1);
Screen('TextSize', w, 30);
if sess.session == 1
    instructions = ...
        sprintf(['Now a coloured shape will be presented\n' ...
                 'before each target. Press a key to see\n' ...
                 'what each shape can tell you about the\n' ...
                 'location the target grating will appear.\n']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    show_shapes(w, sess, sess.block_order);
    instructions = ...
        sprintf(['Press a key to see those shapes again.\n']);
    DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', w);
    start_ts = KbWait;
    WaitSecs(0.5);
    show_shapes(w, sess, sess.block_order);
else
    if sess.set_types(1) == 0
        instructions = ...
            sprintf(['Press a key for a reminder about the shape \n' ...
                     'meanings.\n']);
        DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
        Screen('Flip', w);
        start_ts = KbWait;
        WaitSecs(0.5);
        show_shapes(w, sess, sess.block_order);
    end    
end

instructions = ...
    sprintf(['Try to be as fast as possible while answering\n' ...
             'correctly.\n']);
DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
Screen('Flip', w);
start_ts = KbWait;
WaitSecs(0.5);

Screen('TextStyle', w, 1);
Screen('TextSize', w, 30); 
instructions = ...
    sprintf(['Press %s for clockwise and %s for counterclockwise.\n' ...
             'Press any key to start\n'], ...
            KbName(task.responses(1)), KbName(task.responses(2)));
DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
Screen('Flip', w);
start_ts = KbWait;
WaitSecs(0.5);

block_index = 1;
set_index = 1;
trial_indices = trials.trial_num(trials.block_num == block_index);
trial_aborts = [];
ti = 1;
reward_block = 0;
reward_total = 0;
n_blocks = length(sess.set_types) * 2;
while block_index < n_blocks || ti <= length(trial_indices)
    new_block = 0;
    % Prepare next trial indices if needed.
    if ti > length(trial_indices)
        if isempty(trial_aborts)
            % Next block.
            block_index = block_index + 1;
            set_index = floor((block_index-1) / 2) + 1;
            trial_indices = ...
                trials.trial_num(trials.block_num == block_index);
            new_block = 1;
        else
            % Re-test aborted trials.
            trial_indices = trial_aborts;
            trial_aborts = [];
        end
        ti = 1;
    end
    i = trial_indices(ti);
        
    if new_block
        % Between blocks
        text = sprintf(['Huzzah! %d of %d blocks finished!\n' ...
                        'You received %d points in this block,\n' ...
                        'and %d points in total.\n' ...
                        'Press any key to continue...'], ...
                        block_index - 1, n_blocks, ...
                        reward_block, reward_total);
        DrawFormattedText(w, text, 'Center', 'Center', white, 115);
        Screen('Flip', w);
%         if sess.eye_on
%             DriftCross(w);
%             Screen(w, 'Flip');
%             Eyelink('DriftCorrStart', xc, yc, 1, 0, 1) %Start drift correct
%         end
        start_ts = KbWait;
        reward_block = 0;
        WaitSecs(0.5);
        
        if sess.session == 1 && block_index == 2
            instructions = ...
                sprintf(['In this block you''ll see three different\n' ...
                         'shapes. Press a key to see what these new\n' ...
                         'shapes can tell you about the location the\n' ...
                         'target grating will appear.\n']);
            DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
            Screen('Flip', w);
            start_ts = KbWait;
            WaitSecs(0.5);
            show_shapes(w, sess, ~sess.block_order);
            instructions = ...
                sprintf(['Press a key to see those shapes again.\n']);
            DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
            Screen('Flip', w);
            start_ts = KbWait;
            WaitSecs(0.5);
            show_shapes(w, sess, ~sess.block_order);
        end
        
        if sess.set_types(set_index) == 0 && ~(sess.session == 1 && block_index <= 2)
            instructions = ...
                sprintf(['Press a key for a reminder about the shape \n' ...
                         'meanings.\n']);
            DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
            Screen('Flip', w);
            start_ts = KbWait;
            WaitSecs(0.5);
            block_type = sess.block_order == ~mod(block_index-1, 2);
            show_shapes(w, sess, block_type);
        end

        instructions = ...
            sprintf(['Press %s for clockwise and %s for counterclockwise.\n' ...
                     'Press any key to start\n'], ...
                    KbName(task.responses(1)), KbName(task.responses(2)));
        DrawFormattedText(w, instructions, 'Center', 'Center', white, 115);
        Screen('Flip', w);
        start_ts = KbWait;
        WaitSecs(0.5);

    end
    
    % Set up trial
    cue = sess.cue_mapping(trials.trial_type(i));
    % Trial type determines original reward mapping: 1 or 2 is no reward, 3
    % or 4 is reward. Cue type is 0 for originally no reward, 1 otherwise.
    cue_type = trials.trial_type(i) > 3;
    target = trials.position(i) + 1;
    ccw = trials.ccw(i);
    hrz = trials.hrz(i);
%     shift = position_shift(target);
    shift = angle;
    reward = trials.reward_trial(i);
    Priority(topPriorityLevel);
    [valid, response, ts] = ...
        do_trial(w, sess, task, start_ts, cue_type, cue, target, ccw, ...
                 hrz, shift, contrast, reward, reward_total);
    Priority(0);
    reward_block = reward_block + response.reward_value;
    reward_total = reward_total + response.reward_value;
    % Write log
    fprintf(rsid, [repmat('%d, ', 1, 20) '%d\n'], ...
            trials.trial_num(i), trials.block_num(i), ...
            trials.trial_type(i), trials.reward_trial(i), ...
            trials.condition_type(i), trials.probability(i), ...
            trials.position(i), trials.ccw(i), trials.hrz(i), ...
            response.ccw, response.correct, response.rt, ...
            response.reward_value, ...
            ts.baseline, ts.cue, ts.hold, ts.target, ...
            ts.mask, ts.pending, ts.response, ts.reward);
    
    start_ts = ts.end;
    % Increment pointer to trial number.
    ti = ti + 1;
end
% draw_targets(w, gabor_id, gabor_rect, 1, 10);
% draw_stim(w, 2, 2, white);
text = sprintf(['Thanks! You''re all finished!\n' ...
                'Your total reward was %d.'], ...
               reward_total);
DrawFormattedText(w, text, 'Center', 'Center', white, 115);
Screen('Flip', w);
reward_total

%% Finalise
if sess.eye_on == 1
    Eyelink( 'StopRecording' );
    Eyelink( 'CloseFile' );
    Eyelink( 'ReceiveFile', upper(edfFile));
end

KbQueueRelease;  % clear queue 
% close log files
fclose('all');

while (~KbCheck); end; WaitSecs(1);
Screen('CloseAll');


