%% Monitor settings
monitor = 0;
ref_rate = 60;
resolution = [1024 768]; % might change this with psychtoolbox - get stuff

%% Parameters
load('counterBalance_task_learn_att')
colours = [143, 126, 160; 230 93 85]';

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
% function,
% although we don't actually use these parameters in this learning stage of
% the task
load('task_parameters_v1');
sess.reward_base_rt = reward.reward_base_rt;
sess.reward_max_bonus_rt = reward.reward_max_bonus_rt;
sess.reward_base = reward.reward_base;
sess.reward_bonus = reward.reward_bonus;
sess.reward_base_low = reward.reward_base_low;
sess.reward_bonus_low = reward.reward_bonus_low;

% Angle of gabor target
angle = 45;


%% Generate json metadata for this task and session
if sess.sub_num < 10
    sub_dir = sprintf('sub-0%d_ses-%d_task-learn-att-v1', sess.sub_num, sess.session);
else
    sub_dir = sprintf('sub-%d_ses-%d_task-learn-att-v1', sess.sub_num, sess.session);
end
if ~(exist(sub_dir))
    mkdir(sub_dir);
end


%% SCREEN / DRAWING
screen_index = max(Screen('Screens'));
%PsychDebugWindowConfiguration;
Screen('Preference','SkipSyncTests', 1); 
white = WhiteIndex(screen_index);
black = BlackIndex(screen_index);
grey = white * 0.5;
stim_dark = white * 0.45;
sess.config.white = white;
sess.config.black = black;
sess.config.grey = grey;
sess.config.stim_dark = stim_dark;
sess.config.reward_colour = [255, 215, 0];

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
if sess.resp_order
    task.responses = KbName({'j','f'});
    keys(task.responses) = 1;
else
    task.responses = KbName({'f','j'});
    keys(task.responses) = 1;
end
KbQueueCreate(-1, keys);

%% Timing
session_hold_times = timing.session_hold_times;
time.fixation = timing.fixation * expand_time;
time.baseline = timing.baseline * expand_time;
time.cue = session_hold_times{sess.session}(1) * expand_time; % was 0.2
time.spatial = session_hold_times{sess.session}(2);
time.hold = session_hold_times{sess.session}(3) * expand_time; % was 0.1 - base time to hold the fix pre-tgts
time.hold_v = session_hold_times{sess.session}(4) * expand_time; % was 1.4 - seed for variable time to add
time.target = timing.target * expand_time;
time.mask = timing.mask * expand_time;
time.reward = timing.reward * expand_time;
time.abort = timing.abort * expand_time;
sess.time = time;

%% Setup eye tracking
if sess.eye_on
    EyelinkDoTrackerSetup(el);
    sess.eyetrack = el;
end

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
         edf_file = generate_filename('_ses-%0d_task-learn-att-v1-gabors', sess, 'edf');
    else
         edf_file = generate_filename('_ses-%d_task-learn-att-v1-gabors', sess, 'edf');   
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
