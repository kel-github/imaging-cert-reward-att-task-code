function [trials] = generate_blocks_FourRewardCont(tblocks)
%GENERATE_TRIALS Generate trial blocks for habit reward task.
%   Creates a list of randomised trials. Counterbalancing will
%   always be over the smallest window possible which is 360 trials. 
%   
%   tblocks = the total number iof iterations over 360 trials to perform

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

for iBlock = 1:tblocks

    column_names = {'trial_num', 'block_num', 'reward_type', ...
                    'reward_trial', ...
                    'probability', 'position', 'ccw', 'hrz'};
     
    probabilities  = [ repmat(1, 1, 100), repmat(2, 1, 100), repmat(3, 1, 160) ];
    trial_position = [ repelem([0, 1], [80, 20]), repelem([1, 0], [80, 20]), repelem([0, 1], [80, 80]) ];
    reward_id_idx  = 1:4;
    reward_type    = repmat(reward_id_idx, 1, numel(trial_position)/numel(reward_id_idx));
    reward_on_idx  = [ repmat([ 1, 1, 0, 0], 1, 4), [9, 9, 9, 9] ];
    reward_on      = repmat( reward_on_idx, 1, numel( reward_type ) / numel( reward_on_idx ) );      
    
    trial_ccw      = repmat( [ 0, 1], 1, numel( reward_type ) / numel( [ 0, 1 ] ) );
    trial_hrz      = repmat( [ 0, 0, 1, 1], 1, numel( reward_type ) / numel( [ 0, 0, 1, 1 ] ) );

    order          = randperm( numel( probabilities ) );
    
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
