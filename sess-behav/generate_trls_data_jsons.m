function [] = generate_trls_data_jsons(project_dir, fname)
% written by K. Garner, 2020
% this code generates a json file of the event codes and levels
% for STRIAVISE WP1 exp, using the structure json format
% project_dir = project folder
% fname = fname of json filename with extension (use generate_filename
% function

addpath('JSONio')

% generate the electrode location file 
proj = project_dir;
name = fname;
full_json_name = fullfile(proj,...
                          name);
 
trls_data.date = datetime;
trls_data.trial_num = 'trial number (t)';
trls_data.block_num = '2 blocks x 360 t';
trls_data.reward_type = 'reward cueing condition: 1=h/h, 2=h/l, 3=l/l, 4=l/h';
trls_data.reward_trial = 'high or low reward on this trial: 1 = high reward, 2 = low reward';
trls_data.probability = 'p target left | cue: 1=.8, 2=.2,3=.5';
trls_data.position = 'target location: 0 = left, 1 = right';
trls_data.ccw = 'target orientation: 0 = cw, 1 = ccw';
trls_data.hrz = 'distracter orientation" 0 = hrz, 1 = vertical';

json = trls_data;

json_options.indent = '    '; % this makes the json look pretier when opened in a txt editor
jsonwrite(full_json_name,json,json_options)