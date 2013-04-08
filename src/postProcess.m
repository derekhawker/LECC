%% decision tree
%% The output decision tree will have the same datastructure size as
%% the input, only the references will have changed

%% Nodes -> datapoints featuresp costn ancestor ldescendant
%% rdescendant class
function [outDecTree] = postProcess(inDecTree)
	 %% Make sure the decision tree is set to inDecTree
	 global outDecTree;
     outDecTree = inDecTree;

     disp('===================Unpruned Tree')
     decTreeTextVisualizer(outDecTree)
	 %% Call the recursive function that will update outDecTree 
	 postProcessNode(1);
    disp('====================Pruned Tree')
    decTreeTextVisualizer(outDecTree)

endfunction
