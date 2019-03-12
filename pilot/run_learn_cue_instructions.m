function [] = run_learn_cue_instructions(wh, white) 

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30); 
    instructions = ...
        sprintf(['From now, before the target appears you will \n' ...
                 'see a shape in the centre of the screen\n\n'...
                 'There will be 3 shapes in total.\n\n' ...
                 'Each shape provides probabilistic information.\n'...
                 'about where your target could be.\n\n'...
                 'Although it wont be 100 prcnt correct, it will\n'...
                 'tell you something\n\n'...
                 'Good luck!']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    start_ts = KbWait;

    WaitSecs(0.5);
end