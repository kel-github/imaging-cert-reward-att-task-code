% generate stimulus/response counterbalancing matrix to be read in as task
% parameters for 'run_learn_att_task.m', 'run_learn_gabars.m' and ''
% K. Garner, 2019

% NOTES:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all

all_cues  = 1:3;
n_cols    = 2;
n_resps   = 2;

cues = perms(all_cues)';
cues = [cues, cues];

% add colour mapping counterbalancing
cues(end+1,:) = 0;
cols          = repmat((1:n_cols)-1, 1, size(cues, 2)/n_cols);
cols          = sort(cols, 'ascend');
cues(end, :)  = cols; 

% add response mapping counterbalancing
cues = [cues, cues];
cues(end+1,:) = 0;
resps         = repmat((1:n_cols)-1, 1, size(cues, 2)/n_resps);
resps         = sort(resps, 'ascend');
cues(end, :)  = resps;

p_counterbalance = cues;
save('counterBalance_task_learn_att_v1', 'p_counterbalance');

