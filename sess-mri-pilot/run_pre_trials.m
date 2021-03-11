%%%% this code runs 3 inital trials, without waiting for pulses
%%%% so that all functions are used prior to the first trial

for count_trials = 1:3
    
    % set parameters here
    trial_count = trials.trial_num(count_trials);
    trial_type  = trials.probability(count_trials); % which trial type
    trial_cue   = trials.probability(count_trials);   
    target_loc  = trials.position(count_trials) + 1;
    ccw         = trials.ccw(count_trials);
    hrz         = trials.hrz(count_trials);
    reward      = trials.reward_trial(count_trials);
    reward_cond = trials.reward_type(count_trials);
    
    switch reward_cond
        case 1
            % get the colour to be learned
            cCols = [sess.reward_colours(:,1), sess.reward_colours(:,1)];
        case 2
            cCols = zeros(3,2);
            cCols(:, target_loc)   = sess.reward_colours(:,1);
            cCols(:, 3-target_loc) = sess.reward_colours(:,2);
        case 3
            cCols = [sess.reward_colours(:,2), sess.reward_colours(:,2)];
        case 4
            cCols = zeros(3,2);
            cCols(:, target_loc)   = sess.reward_colours(:,2);
            cCols(:, 3-target_loc) = sess.reward_colours(:,1);
    end
    
   
    Priority(topPriorityLevel);    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VISUAL EVENTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % the following function will take between .9340 and 1.0340 s. The idea
    % is that the visual events function will fun - then the code will wait
    % until the pulse_time + the relevant number of seconds, before
    % continuing
    % get trial start time 
    pulse_time = GetSecs;
    do_visual_events(w, count_trials, ts, sess, trial_cue, target_loc, ccw, hrz, cCols, ...
                            angle, contrast, 1, event_fid, event_form); % visual events have occurred
    % now draw fixation, but don't flip until the relevant time period has
    % gone by
    do_fix_full(w, sess, cCols, 1);
    pulse_time = GetSecs;
    Screen('Flip', w, pulse_time+(TR.TR*TR.nVis)-time.pre_pulse_flip); % so the flip should occur 10 ms before the desired pulse   

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % RESPONSE PERIOD
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    do_fix_full(w, sess, cCols, 1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SCORE AND GIVE FEEDBACK
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    [response, ts] = do_response_score(count_trials, task, ts, sess, reward, ccw, event_fid, event_form);
    [ts] = animate_reward(w, count_trials, ts, sess, time, response, reward_total, event_fid, event_form);
    % collect trial data, and draw fixation, ready to present at the end of the feedback period
    reward_total = 0;

    do_fixation(w, sess);
    pulse_time = GetSecs;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FINAL FIXATION PERIOD
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    do_fixation(w, sess);    
    Screen('Flip', w, pulse_time+(TR.TR*TR.nFix)-time.pre_pulse_flip);

end