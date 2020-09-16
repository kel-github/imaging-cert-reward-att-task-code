function [] = generate_meta_data_jsons(json, root_dir, project_dir, fname)
% written by K. Garner, 2019
% this code generates a json file, using the structure json
% format
% json.field = 'info'
% root_dir = parent directory
% project_dir = project folder
% fname = fname of json filename with extension (use generate_filename
% function

addpath('JSONio')

% generate the electrode location file 
r_dir = root_dir;
proj = project_dir;
name = fname;
full_json_name = fullfile(r_dir, proj,...
                 name);

json_options.indent = '    '; % this makes the json look pretier when opened in a txt editor
%    jsonwrite(elec_json_name,anat_json,json_options)
jsonwrite(full_json_name,json,json_options)