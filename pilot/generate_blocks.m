function [trials] = generate_blocks(set_type, block_order)
%GENERATE_TRIALS Generate trial blocks for habit reward task.
%   Creates a list of randomised trials for blocks with both rewarded and
%   unrewarded trials. Each set consists of 80 trials broken into two
%   blocks, counterbalanced for reward per position per target orientation
%   per distractor orientation per probability. Counterbalancing will
%   always be over the smallest window possible which is 120 trials. There
%   is one set per element in set type, where each element designates
%   either an ordered set of a 'low reward' block followed by a 'high
%   reward' block (set_type = 0), a set where low and high reward trials
%   are randomly mixed (set_type = 1), a set of mixed trials where an extra
%   low reward is given (set_type = 2), or a set of mixed trials but
%   where all probabilities are set to 50/50 and extra low reward is given
%   (set_type = 3). If block_order is > 0, the order of any ordered sets is
%   reversed (reward followed by non-reward).
%
%   The format of the returned matrix is:
%
%   trial_num, block_num, cue, reward_trial, probability, position, ccw, hrz
%
%   where trial_type is the identity of the trial (1-4), reward trial is a
%   logical denoting the trial type, probability determines whether there
%   is an 80% (1) or 20% (2) chance of the target appearing on the left,
%   position is whether the target appears on the left (0) or right (1),
%   ccw designates a clockwise (0) or counter-clockwise (1) distractor, and
%   hrz designates a vertical (0) or horizontal (1) target.
    column_names = {'trial_num', 'block_num', 'trial_type', ...
                    'reward_trial', 'condition_type', ...
                    'probability', 'position', 'ccw', 'hrz'};
    conditions = [[0, 0, 0, 0, 0, 0, 0, 0, 1, 1]; ...  % 80% left
                  [0, 0, 1, 1, 1, 1, 1, 1, 1, 1]; ...  % 20% left
                  [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]]; ... % 50% left
    conditions_ext = [[0, 0, 0, 0, 0, 1, 1, 1, 1, 1]; ...
                      [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]; ...
                      [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]];
    % A set of conditions per reward state.
    trial_rewards = [zeros(size(conditions) .* [1, 2]); ...
                     ones(size(conditions) .* [1, 2])];
    trial_rewards = reshape(trial_rewards', 1, []);
    if block_order
        trial_rewards = ~trial_rewards;
    end
    % Two full sets of conditions.
    trial_conditions = [repmat(conditions, 1, 2); ...
                        repmat(conditions, 1, 2)];
    trial_conditions = reshape(trial_conditions', 1, []);
    trial_conditions_ext = [repmat(conditions_ext, 1, 2); ...
                            repmat(conditions_ext, 1, 2)];
    trial_conditions_ext = reshape(trial_conditions_ext', 1, []);

    % Trial types.
    trial_types = repmat((1:3)', 2, size(conditions, 2) * 2);
    trial_types = reshape(trial_types', 1, []);
    trial_types = trial_types + 3*trial_rewards;
    % Trial orientation.
    trial_ccw = [zeros(size(conditions) .* [2, 1]), ...
                 ones(size(conditions) .* [2, 1])];
    trial_ccw = reshape(trial_ccw', 1, []);
    % Trial distractor orientation.
    trial_hrz = [zeros(size(conditions) .* [2, 0.5]), ...
                 ones(size(conditions) .* [2, 0.5])];
    trial_hrz = [fliplr(trial_hrz), trial_hrz];
    trial_hrz = reshape(trial_hrz', 1, []);
    % Trial probabilities.
    trial_probabilities = repmat((1:3)', 2, size(conditions, 2) * 2);
    trial_probabilities = reshape(trial_probabilities', 1, []);
    
    n_blocks = length(set_type) * 2;
    n_trials_per_shuffle = numel(trial_conditions);
    n_trials_per_block = n_trials_per_shuffle / 2;
    trials = zeros(n_trials_per_shuffle*length(set_type), 9);
    trials(1:end, 1) = 1:size(trials, 1);
    trials(1:end, 2) = reshape(repmat(1:n_blocks, n_trials_per_block, 1), ...
                               1, []);
    for i = 1:length(set_type)        
        ti = (i-1) * n_trials_per_shuffle + 1;
        ti_end = ti + n_trials_per_shuffle - 1;
        if set_type(i) > 0
            order = randperm(n_trials_per_shuffle);
        else
            order = [randperm(n_trials_per_block), ...
                     randperm(n_trials_per_block) + n_trials_per_block];
        end
        trials(ti:ti_end, 3) = trial_types(order);
        if set_type(i) >= 2
            trials(ti:ti_end, 4) = 2;
        else
            trials(ti:ti_end, 4) = trial_rewards(order);
        end
        if set_type(i) == 3
            trials(ti:ti_end, 5) = 1;
        else
            trials(ti:ti_end, 5) = 0;
        end
        trials(ti:ti_end, 6) = trial_probabilities(order);
        if set_type(i) == 3
            trials(ti:ti_end, 7) = trial_conditions_ext(order);
        else
            trials(ti:ti_end, 7) = trial_conditions(order);
        end            
        trials(ti:ti_end, 8) = trial_ccw(order);
        trials(ti:ti_end, 9) = trial_hrz(order);
    end
    trials = array2table(trials, 'VariableNames', column_names);
end
