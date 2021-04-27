function [targets, ccw, hrz] = generate_trial_block_params_for_cue(n_trials, itrs)
% generate trial parameters for a block, given the specification of the cue probability
% cue probability implied by n_trials, which is a 2 element vector, each element corresponding
% to the number of trials at each location.
% This code takes the number of trials at each location, sets
% counterbalanced trial parameters and shuffles. This loops over the number
% of itrs to come up with the full set of trials for the block.
% this makes sure that local probabilities never get too out of whack with
% the global probability
% 
% inputs
% ---------------------------------------------------------------
% n_trials    = number of trials at each location
% n_positions = number of possible target locations
% itrs        = iterations, over how many times to loop the trial generation
%
% outputs
% ----------------------------------------------------------------
% ALL OUTPUT VARIABLES ARE ORDERED ACCORDING TO THE SAME
% PSEUDORANDOMIZATION
% targets = index for target location, 1=left, 2=right
% ccw     = clockwise or counterclockwise?
% hrz     = off the horizontal or vertical meridian

targets = [];
ccw     = [];
hrz     = [];

for count_iters = 1:itrs
    
    these_targets = [];
    these_ccw     = [];
    these_hrz     = [];
    
for i = 1:length(n_trials)
    
    these_targets = [these_targets, repmat(i, 1, n_trials(i))]; 
    these_ccw     = [these_ccw, repmat([0, 1], [1, n_trials(i)/length(n_trials)])];
    these_hrz     = [these_hrz, repmat([0, 0, 1, 1], [1, n_trials(i)/(length(n_trials)*2)])];
    
end

order   = randperm(numel(these_targets));
targets = [targets these_targets(order)];
ccw     = [ccw these_ccw(order)];
hrz     = [hrz these_hrz(order)];

end

end