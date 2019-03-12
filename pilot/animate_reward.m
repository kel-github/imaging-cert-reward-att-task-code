function [ts] = animate_reward(wh, sess, response, current_reward)
    % inputs
    % --------------------------------------------------------------
    % wh             = window handle
    % sess           = subject session structure
    % response       = trial response structure containing rt, correct, and
    % current_reward = current accrued reward value 

    if response.correct
        colour = sess.config.reward_colour;
    else
        colour = sess.config.stim_dark;
    end
    [w, h] = Screen('WindowSize', wh);

    if response.reward_value > 0
        reward_text = sprintf('%05d + %03d', current_reward, ...
                              response.reward_value);
    else
        reward_text = sprintf('%05d', current_reward);

    end
    DrawFormattedText(wh, reward_text, 'Center', 'Center', ...
                      colour, 115);
    [ts] = Screen('Flip', wh);
    
    % Now animate any additional reward.
    if response.reward_value > 0
        n_frames = min(response.reward_value, 20);
        v = response.reward_value;
        cv = current_reward;
        dv = round(response.reward_value / n_frames);
        next_ts = ts + 0.25;
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
end
