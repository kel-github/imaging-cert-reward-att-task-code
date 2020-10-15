function [] = generate_event_data_jsons(project_dir, fname)
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
 
event_data.sub = 'subject number';
event_data.sess = 'session number';
event_data.date = datetime;
event_data.t = 'trial number';
event_data.loc = '1=tgt left, 2=tgt right';
event_data.cue = 'ptgtleft|cue, 1=.8, 2=.2,3=.5';
event_data.co1 = 'contrast: left gabor';
event_data.co2 = 'contrast: right gabor';
event_data.or = '0=cw, 1=ccw';
event_data.resp = '0=cw, 1=ccw';
event_data.rt = 'response time';

json = event_data;

json_options.indent = '    '; % this makes the json look pretier when opened in a txt editor
jsonwrite(full_json_name,json,json_options)