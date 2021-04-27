function [targets, ccw, hrz] = generate_trial_block_params(n_trials, n_positions)
% generate trial parameters for a block.
% inputs
% ---------------------------------------------------------------
% n_trials    = number of trials at each location
% n_positions = number of possible target locations

% outputs
% ----------------------------------------------------------------
% ALL OUTPUT VARIABLES ARE ORDERED ACCORDING TO THE SAME
% PSEUDORANDOMIZATION
% targets = index for target location, 1=left, 2=right
% ccw     = clockwise or counterclockwise?
% hrz     = off the horizontal or vertical meridian

targets = reshape(repmat(1:n_positions, [n_trials, 1]), 1, []);
ccw     = repmat([0, 1], [1, numel(targets)/2]);
hrz     = repmat([0, 0, 1, 1], [1, numel(targets)/4]); 

order = randperm(numel(targets));
targets = targets(order);
ccw     = ccw(order);
hrz     = hrz(order);

end