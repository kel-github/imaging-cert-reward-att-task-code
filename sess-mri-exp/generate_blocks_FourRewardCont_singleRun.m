function [trials] = generate_blocks_FourRewardCont_singleRun(tblocks)
%GENERATE_TRIALS Generate trial blocks for habit reward task.
%   Creates a list of randomised trials. Counterbalancing will be over 128
%   trials
%   

%   The format of the returned matrix is:
%
%   trial_num, block_num, cue, reward_trial, probability, position, ccw, hrz
%
%   where reward_type is the value identity of the trial (1:4) (1 = h/h, 2 = h/l, 3 = l/l, 4 = l/h) 
%   h = .8 prob high value, l = .2 prob high value
%   reward trial is a
%   logical denoting the reward value of the trial (1 = high reward, 0 = low reward), 
%   probability determines whether there
%   is an 80% (1), 20% (2) or 50% (3) chance of the target appearing on the left,
%   position is whether the target appears on the left (0) or right (1),
%   ccw designates a clockwise (0) or counter-clockwise (1) distractor, and
%   hrz designates a vertical (0) or horizontal (1) target.

%   wRandConstraints = this version takes the first half of each key
%   counterbalance, and randomises the presentation order within each half.
%   This ensures that when performed over 2 blocks in the scanner, each
%   trial is represented
for iBlock = 1:tblocks

    column_names = {'trial_num', 'block_num', 'reward_type', ...
                    'reward_trial', ...
                    'probability', 'position', 'ccw', 'hrz'};
    
    probabilities  = [ repmat(1, 1, 36), repmat(2, 1, 36), repmat(3, 1, 28*2)];
    trial_position = [ repelem([0, 1], [28, 8]), repelem([1, 0], [28, 8]), repelem([0, 1], [28, 28]) ]; % but actually use 28 & 28 for last condition
%    reward_type    = [ repmat([ repelem([1, 2, 3, 4], 7), repelem([1, 2, 3, 4], 2)], 1, 2), repmat( repelem([1, 2, 3, 4], 7), 1, 2)];           
    reward_type    = [ repmat([ repelem([3, 4, 1, 2], 7), repelem([3, 4, 1, 2], 2)], 1, 2), repmat( repelem([3, 4, 1, 2], 7), 1, 2)];  
    % the (clunky code) below ensures that the unexpected rewards are distributed equally
    % across the invalid trial types over the 4 iterations of the
    % reward_type pattern. Basically, there are 2 iterations, the first two
    % lines are the reward conditions for the valid trials ( 4 x 7 ), the
    % next two rows are the distribution of reward conditions for the
    % invalid trials ( 8 ), this is then repeated for the right cue ( n =
    % 36 ) and the neutral cues are added onto the end ( 28 * 2 )
    reward_on = [ repmat( repelem([ 0, 1 ], [ 5, 2 ] ), 1, 2 ), ... % ll, lh valid
                  repmat( repelem([ 0, 1 ], [ 2, 5 ] ), 1, 2 ), ... % hh, hl valid
                  repelem( [ 0, 1 ], [ 3, 1 ] ), ...
                  repelem( [ 0, 1 ], [ 1, 3 ] ), ...
                  repmat( repelem([ 0, 1 ], [ 5, 2 ] ), 1, 2 ), ... % ll, lh valid
                  repmat( repelem([ 0, 1 ], [ 2, 5 ] ), 1, 2 ), ... % hh, hl valid;
                  repelem( [ 0, 1, 0 ], [ 1, 1, 2 ] ), ...
                  repelem( [ 1, 0, 1 ], [ 2, 1, 1 ] ), ...
                  repmat( repelem([ 0, 1 ], [ 5, 2 ] ), 1, 2 ), ... % ll, lh valid
                  repmat( repelem([ 0, 1 ], [ 2, 5 ] ), 1, 2 ), ... % hh, hl valid;                 
                  repmat( repelem([ 0, 1 ], [ 5, 2 ] ), 1, 2 ), ... % ll, lh valid
                  repmat( repelem([ 0, 1 ], [ 2, 5 ] ), 1, 2 )] ;              

    trial_ccw      = repmat( [ 0, 1], 1, numel( reward_type ) / numel( [ 0, 1 ] ) );
    trial_hrz      = repmat( [ 0, 0, 1, 1], 1, numel( reward_type ) / numel( [ 0, 0, 1, 1 ] ) );

    order = randperm( numel( probabilities ) );
                   
    if iBlock == 1
        start = 0;
    else
        start = max(trials(:, 1));
    end
    trials      = [ (start+1) :( start + numel( probabilities ) )]';
    trials(:,2) = repelem( iBlock, numel( probabilities ) );
    trials(:,3) = reward_type( order );
    trials(:,4) = reward_on( order );
    trials(:,5) = probabilities( order );
    trials(:,6) = trial_position( order );
    trials(:,7) = trial_ccw( order );
    trials(:,8) = trial_hrz( order );
    
    if iBlock == 1
        block_trials  = array2table(trials, 'VariableNames', column_names);
    else
        nu_trials     = array2table(trials, 'VariableNames', column_names);
        block_trials   = [ block_trials;  nu_trials ];
        
    end
end

trials = block_trials;
