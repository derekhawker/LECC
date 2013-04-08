%% Recursive function for nodes

function cost = postProcessNode(nodeIndex)
	 global outDecTree;
	 global population;
	 global k;

	 %% Compute total cost of the node

	 %% Compute the cost of misclassification for the given node
	 if (outDecTree(nodeIndex).class == k.CLASS_0)
	    misclassificationCosts = \
	    population.mc(2)*outDecTree(nodeIndex).numMisClassified;
	 else 
	   if(outDecTree(nodeIndex).class == k.CLASS_1)
	     misclassificationCosts = population.mc(1)*outDecTree(nodeIndex).numMisClassified;
	   else
	   %% Root node assume we will choose the lowest cost
	     m0 = population.mc(1)*population.numClass0;
	     m1 = population.mc(2)*population.numClass1;
	     if (m0 > m1)
		misclassificationCosts = m1;
	     else
	       misclassificationCosts = m0;
	     end
	   end
	 end

	 %% Compute the overall features used
	 ancestor = outDecTree(nodeIndex).ancestor;
	 if (ancestor ~= k.NULL)
	   fp = outDecTree(ancestor).featuresp;
	   ancestor = outDecTree(ancestor).ancestor;
	   while (ancestor ~= 0)
	     fp = bitor(outDecTree(ancestor).featuresp, fp);
	     ancestor = outDecTree(ancestor).ancestor;
	   endwhile
	 else
	   fp = zeros(1, population.F-1);
	 endif
	     
	 %% Compute total feature cost
	 featureCosts = sum(fp .* population.fc * \
		       (sum(outDecTree(nodeIndex).datapoints)));

	 %% Sum for total cost
	 totalCost = misclassificationCosts + featureCosts;
	 
	 %% Check if node is a leaf by seeing if it has any descendants
	 if ((outDecTree(nodeIndex).ldesc == k.LEAF_NODE) && \
	     (outDecTree(nodeIndex).rdesc == k.LEAF_NODE))
	    cost = totalCost;
	    printf('Leaf: %d  TotalCost: %f\n',nodeIndex,cost)
	    return;
	 else
	     %% This node has descendants, compute the cost of
	     %% descendants
	   totalCostOfDescendants = \
	   postProcessNode(outDecTree(nodeIndex).ldesc) + \
	   postProcessNode(outDecTree(nodeIndex).rdesc);
	   printf('Anc: %d  TotalCost: %f  CostDec: %f\n',nodeIndex,totalCost, totalCostOfDescendants)
	   if (totalCost < totalCostOfDescendants)
	      %% If stopping at node is cheaper than descending then
	     %% remove the descendants by clearing their references
	      printf('PRUNE: %d prunes %d & %d\n',nodeIndex,outDecTree(nodeIndex).ldesc,outDecTree(nodeIndex).rdesc)
	     outDecTree(nodeIndex).ldesc = k.LEAF_NODE;
	     outDecTree(nodeIndex).rdesc = k.LEAF_NODE;
	     cost = totalCost;
	     return;
	   else
	       %% Descending is cheaper, send the descendant cost up
	       cost = totalCostOfDescendants;
	       return;
	   endif
	 endif
endfunction
