% inst: an index into the population.A structure that denotes the datapoint
% Determines the class that a datapoint belongs to. 
% class: 0 or 1 value denoting the real class that a datapoint belongs to
function [class] = getClass(inst)
    global population;
    global k;

    % All datapoints are ordered by class with class 0 first. Figuring out class
    % is then a matter of checking if the index is < than the total class 0 datapoints
    if inst <= population.numClass0
        class = k.CLASS_0;
    else
        class = k.CLASS_1;
    end
end
