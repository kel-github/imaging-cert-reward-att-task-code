function [response, ts] = do_response_score(n, task, ts, sess, reward, ccw, event_fid, event_form)
%%%% inputs
% n = trial number
% task = task structure containing response assignments
% ts = structure of timestamps
% sess = subject session structure
% reward  = reward case, 0 = low reward, 1 = high reward, 2 = none
% event_ - details for event fid, and form of data going in
[key_is_down, first_press] = KbQueueCheck;
KbQueueStop;

if any(key_is_down)
    
    if first_press(task.responses(1)) > 0 && ... % if both keys have been pressed
            first_press(task.responses(2)) > 0
        response.ccw = first_press(task.responses(2)) < ...
            first_press(task.responses(1)); % if counterclockwise occurred earlier than the clockwise response then put counterclockwise, if not put 1 for counterclockwise, if not put 0 for clockwise
        % returns a 1 if response(1)[ccw] was pressed before
        % response(2)[cw]
        ts.response(n) = min(first_press(task.responses)); % and put the time of the response that occurred first
    else
        response.ccw = first_press(task.responses(2)) > 0; % if the second response was pressed put a 1 for counterclockwise, if not a zero for clockwise
        ts.response(n) = max(first_press(task.responses)); % put down the only recorded time for a response time
    end
    response.rt = ts.response(n) - ts.target(n);
    
    
    response.correct = response.ccw == ccw;
    if response.correct
        % Calculate reward based on RT.
        rt0 = sess.reward_max_bonus_rt;
        rt1 = sess.reward_base_rt;
        reward_frac = (response.rt - rt0) / (rt1 - rt0);
        reward_frac(reward_frac < 0) = 0.0;
        reward_frac(reward_frac > 1.0) = 1.0;
        reward_frac = 1.0 - reward_frac;
        switch reward
            case 0
                response.reward_value = ...
                    round(sess.reward_base_low + sess.reward_bonus_low * reward_frac);
            case 1
                response.reward_value = ...
                    round(sess.reward_base + sess.reward_bonus * reward_frac);
            case 2
                response.reward_value = 0;
            case 9
                response.reward_value = 0;
        end
    else
        response.reward_value = 0;
    end
else
    
    response.reward_value = 0;
    response.correct = 0;
    response.rt = -999;
    ts.response(n) = -999;
end


fprintf(event_fid, event_form, ts.response(n), response.rt, 'response'); % event info stuff

end