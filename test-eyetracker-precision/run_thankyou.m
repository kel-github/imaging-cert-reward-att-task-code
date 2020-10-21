function [] = run_thankyou(wh, white, dur)

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 80);
    instructions = ...
        sprintf(['Thanks! You shall imminently\n' ...
                'regain your freedom :-)\n']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    WaitSecs(dur);
end