function BW = createInclusionLetter(letter_size, letter)
    %% Create a letter-shaped inclusion mask (e.g., "R")
    % This function generates a binary mask containing the specified letter.
    % The letter is rendered using MATLAB text graphics, converted to grayscale,
    % thresholded to create a binary image, and resized to the desired size.
    %
    % Inputs:
    %   letter_size - Desired output size (in pixels) of the square mask
    %   letter      - Character to render (e.g., 'R')
    %
    % Output:
    %   BW          - Binary mask of size [letter_size x letter_size]
    %                 where 1 indicates the letter region

    % Create an invisible figure to render the letter
    f = figure('Visible','on');   % Change to 'off' to suppress window
    ax = axes(f);
    
    % Remove axes display
    axis(ax,'off')
    xlim([0 1]); 
    ylim([0 1])
    
    % Render the letter centered in the figure
    text(0.5, 0.5, letter, ...
        'FontSize', 200, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle');
    
    % Capture the rendered frame
    frame = getframe(ax);
    
    % Convert RGB image to grayscale
    img = rgb2gray(frame.cdata);
    
    % Binarize image using intensity threshold
    BW = img < 200;   % Pixels darker than threshold become 1
    
    % Resize binary mask to desired output dimensions
    BW = imresize(BW, [letter_size letter_size]);
    
    % Close figure to avoid memory accumulation
    close(f);
end