function [reward_order] = get_reward_order(reward_order, targets, prob, replace)

% use this function to get a proportion (prob) of trials with targets from the left and from the 
% right, and replace with replace

l = find(targets == 1);
lidx = l(randperm(numel(l), round(numel(l)* prob)));
r = find(targets == 2);
ridx = r(randperm(numel(r), round(numel(r)* prob)));
reward_order([lidx, ridx]) = replace;
end