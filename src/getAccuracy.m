% node: The node of a decision tree that we want to determine the accuracy of
% Determines the accuracy of a given node by looking at the nominal class and seeing
% how many of the datapoints in that node share that nominal class
% accuracy: values between 0-1 denoting the accuracy
function [accuracy] = getAccuracy(node)
    global k;
    global population;


    totalDatapoints = sum(node.datapoints)
    % Check for divide by zero error
    if totalDatapoints == 0
        accuracy = 1;
    else
        % relies on the numMisclassified field as set in the GenDCHyper() function
        accuracy = 1-node.numMisClassified/sum(node.datapoints)    
    end

end
