%% Monitor settings
monitor = 0;
ref_rate = 60;
resolution = [1600 1200]; % 

%% Parameters
load('counterBalance_task_learn_att')
colours = [82, 95, 186;  0, 130, 0]'; %see York & Becker, 2020: doi.org/10.1167/jov.20.4.6
sess.cbalance = p_counterbalance(:, sess.sub_num);

% assign reward colours ([1, 2] or [2, 1]) - colour value mapping (1 = high
% colour, 2 = low colour)
% assign reward learn order [1, 2] or [2, 1] - which colour value mapping
% is learned about first (1 = high, 2 = low)
% resp_order - 1 = f = clockwise, j = counterclockwise, 2 = f =
% counterclockwise, j = clockwise
reward_cols         = [colours(:,sess.cbalance(1)), colours(:,sess.cbalance(2))];
sess.reward_colours = reward_cols;
sess.learn_order    = sess.cbalance(3:4); 
sess.resp_order     = sess.cbalance(5); % response order - 1 = '1' is clockwise, and '2' is counterclockwise                                                                       % 2 = '1' is counterclockwise, and '2' is clockwise

sess.shapes         = [1, 3, 2];                                                                         
clear p_counterbalance

% reward parameters
% the idea here is that participants will earn a proportion of the
% available reward, based on their rt. Here we set the start parameters
% for the proportion of reward to be computed from in the do_trial
% function
load('task_parameters_v1');
sess.reward_base_rt = reward.reward_base_rt;
sess.reward_max_bonus_rt = reward.reward_max_bonus_rt;
sess.reward_base = reward.reward_base;
sess.reward_bonus = reward.reward_bonus;
sess.reward_base_low = reward.reward_base_low;
sess.reward_bonus_low = reward.reward_bonus_low;

% Angle of gabor target
angle = 45;


%% SCREEN / DRAWING
screen_index = max(Screen('Screens'));
%PsychDebugWindowConfiguration;
white = WhiteIndex(screen_index);
black = BlackIndex(screen_index);
grey = white * 0.5;
stim_dark = white * 0.45;
stim_light = white * 0.75;
sess.config.white = white;
sess.config.black = black;
sess.config.grey = grey;
sess.config.stim_dark = stim_dark;
sess.config.stim_light = stim_light;
sess.config.reward_colour = [255, 215, 0];

[w, rect] = Screen('OpenWindow', screen_index, sess.config.black, [], [], [], 0, 8);
%[w, rect] = Screen('OpenWindow', screen_index, black, [], [], [], 0, 8);
Screen(w, 'Flip');

[x_pix, y_pix] = Screen('WindowSize', w);
xc = x_pix / 2;
yc = y_pix / 2;
sess.xc = xc;
sess.yc = yc; 
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
Screen('TextSize', w, 35); 

% Define responses and initiate kb queue
KbName('UnifyKeyNames');
keys = zeros(1,256);
if sess.resp_order == 1
    task.responses = KbName({'3#','2@'});
    keys(task.responses) = 1;
elseif sess.resp_order == 2
    task.responses = KbName({'2@','3#'});
    keys(task.responses) = 1;
end
KbQueueCreate(-1, keys);

%% Timing
session_hold_times = timing.session_hold_times;
time.fixation = timing.fixation * expand_time;
time.baseline = timing.baseline * expand_time;
time.pre_vis_max = timing.pre_vis_max*expand_time;
time.cue = session_hold_times{1}(1) * expand_time; % was 0.2
time.spatial = session_hold_times{1}(2);
time.hold = session_hold_times{1}(3) * expand_time; % was 0.1 - base time to hold the fix pre-tgts
time.hold_v = session_hold_times{1}(4) * expand_time; % was 1.4 - seed for variable time to add
time.target = timing.target * expand_time;
time.mask = timing.mask * expand_time;
time.reward = timing.reward * expand_time;
time.abort = timing.abort * expand_time;
sess.time = time;


%% Initialise Eyelink
% NOTE - this references a Screen output (grey) and must happen after the
% screens have been drawn
if sess.eye_on
    el=initialise_eyes(w);
    sess.eyetrack = el;
    sess.r = 100; % the fixation size box used to determine central fixation
%    sess.elstatus = set_up_for_eyetracking(el, x_pix, y_pix, inputs.scDim(1), inputs.scDim(2), inputs.eyeDistmm(1), inputs.eyeDistmm(2));  
else   
    sess.eyelink_version = -1;
    sess.eyelink_vstring = [];
end

%% set up Eyetracker
if sess.eye_on
    inputs.testid = subref;
    inputs.runid = num2str(sess.run);
    inputs.bground = sess.config.black;
    EyelinkDoTrackerSetup(el); % calibrate
    [sess, el, edf] = eyelink_initfile(el, sess, inputs); 
    % set up log file
    lg_fn = sprintf(['sub-', subref, '_ses-0%d_task-', task_str, '_acq-TR%d_run-0%d_eyetracklog.tsv'], ...
                     sess.session, sess.acq, sess.run);
    lg_fid = fopen(fullfile( sub_dir, lg_fn ), 'w' );
    fprintf(lg_fid, '%s\t%s\t%s\t%s\t%s\t%s\%d\n', 'x','y','xc','yc','r','rf', 't'); % eylink x, eyelink y, screen center x, screen center y, radius from center, radius flag (point outside radius>), trial
    sess.lg_fid = lg_fid;
end

