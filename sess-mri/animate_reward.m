function [ts] = animate_reward(wh, n, ts, sess, time, response, current_reward, event_fid, event_form)
    % inputs
    % --------------------------------------------------------------
    % wh = window handle
    % n = trial number
    % ts = trial stamp structure
    % sess = subject session structure
    % time = timing structure for experiment
    % response  = trial response structure containing rt, correct, and
    % reward values
    % current_reward = current accrued reward value 
    % event form, event_fid are the identifying details of, and
    % datastructure for, the event file
    gabor_rect = sess.config.gabor_rect;
    white = sess.config.white;
    stim_dark = sess.config.stim_dark;
    grey = sess.config.grey;
    
    if response.correct
        colour = sess.config.reward_colour;
    else
        colour = sess.config.stim_dark;
    end

    if response.reward_value > 0
        reward_text = sprintf('%05d + %03d', current_reward, ...
                              response.reward_value);
    else
        reward_text = sprintf('%05d', current_reward);

    end
    DrawFormattedText(wh, reward_text, 'Center', 'Center', ...
                      colour, 115);
    [ts.feed_on(n)] = Screen('Flip', wh);
    
    % Now animate any additional reward.
    if response.reward_value > 0
        n_frames = min(response.reward_value, 20);
        v = response.reward_value;
        cv = current_reward;
        dv = round(response.reward_value / n_frames);
        next_ts = ts.feed_on(n) + 0.25;
        ts_i = 0.3 / n_frames;
        for i = 1:n_frames
            cv = min(cv + dv, current_reward + response.reward_value);
            v = max(v - dv, 0);
            reward_text = sprintf('%05d + %03d', cv, v);
            DrawFormattedText(wh, reward_text, 'Center', 'Center', ...
                              colour, 115);
            [next_ts] = Screen('Flip', wh, next_ts);
            next_ts = next_ts + ts_i;
        end
    end
    
    % Display fixation.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5*get_ppd(), white, grey);
    draw_stim(wh, 0, stim_dark);
    ts.fix_on(n) = Screen('Flip', wh, ts.feed_on(n)+time.reward);
    fprintf( event_fid, event_form, ts.feed_on(n), ts.fix_on(n) - ts.feed_on(n), 'feedback' );
    
end
