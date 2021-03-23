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
        %reward_text = sprintf('%05d + %03d', current_reward, response.reward_value);
        reward_text = sprintf('+ %03d -> %05d', response.reward_value, current_reward + response.reward_value);
        %total_text = sprintf('', );
    else
        reward_text = sprintf('%05d', current_reward);

    end
    DrawFormattedText(wh, reward_text, 'Center', 'Center', ...
                      colour, 115);
    [ts] = Screen('Flip', wh);
    WaitSecs(1);

end
