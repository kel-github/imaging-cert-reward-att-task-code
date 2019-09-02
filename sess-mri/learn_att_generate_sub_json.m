function [] = learn_att_generate_sub_json(sub, fname)
% written by K. Garner, 2019
% Dependencies
% Matlab 2017a
% JSONio 1.1

% this code takes the information in the structure 'sub' and allocates to
% fields for writing to sidecar json file, for the participant

addpath('~/Dropbox/MATLAB/JSONio')

% generate the json file
if sub.num < 10
    root_dir = sprintf([cd '/sub-%0d/ses-%d/']);
else
    root_dir = sprintf([cd '/sub-%d/ses-%d/']);
end
sub_meta_name          = sprintf([root_dir 'sub-%0d_ses-%d_task-learn-att-v1_beh' '.json'], sub.num, sub.sess);

sub_meta_data.sub_num  = sub.num;
sub_meta_data.sub_sess = sub.sess;
sub_meta_data.date     = char(datetime('now'));
sub_meta_data.


json_options.indent = '    '; % this makes the json look pretier when opened in a txt editor
%    jsonwrite(elec_json_name,anat_json,json_options)
jsonwrite(sub_meta_name, sub_meta_data, json_options)