% dsId: dataset id. Refers to a line number in the dataset locations tables. 
% cand_selection_method Int value where 0=use all datapoints that are violated as candidate constraitns, 1=use top n% datapoints taht are violated as candidates where n is a values between 0 and 1 and provided as the third function argument, 2=use best two candidate method
% cand_selection_percent Value betweeen 0 and 1 showing the percent of total available datapoint candidates to use 
% Builds a decision tree for a dataset specified by dsId.
% unpruned: The first attempt at a decision tree
% dectree: a processed version of unpruned where nodes are removed based on
%   cost effectiveness as determined by postProcess()
% lpsSolved: statistic that outputs the number of lps used in generation of hyperplane
function [dectree, unpruned, lpsSolved] = genDecTree (dsId, \
					   cand_selection_method=0, \
					   cand_selection_percent=0, \
					  memory=0,fc_file="", mc_file="", \
				     data_file="")
    global population;
    global nodes;
    global k;
    
    debugcount=0;
    % initialize the population structure
    if (dsId == 0)
       population = createPopulation(dsId, fc_file, mc_file, \
				     data_file);
    else
      population = createPopulation(dsId);
    end

    % Create the very root node(all datapoints, no costs are zeroed. No hyperplane)
    nodes  = [buildRootNode()];

    % create a decision tree
    buildTree(cand_selection_method, cand_selection_percent,memory)

    % output statistics for the unpruned decision tree
    [accuracy total_cost ec ef] = getTreeAccuracy(nodes);
    debugcount=debugcount+1;
    printf('DEBUG COUNT: %d\n',debugcount);
    printf('UNPRUNED: Accuracy %f, Cost %f, EC %f EF ',accuracy,total_cost,ec)
    disp(ef)


    % Post process the tree to remove cost ineffective nodes
    unpruned = nodes;
    dectree = postProcess(nodes);     

    [accuracy total_cost ec ef] = getTreeAccuracy(dectree);
    printf('Debug Count: %d\n', debugcount);
    printf('PRUNED: Accuracy %f, Cost %f, EC %f, EF %f',accuracy,total_cost,ec)
    disp(ef)
    printf('lpsUsed: %d\n',population.lpsSolved);
    lpsSolved = population.lpsSolved;
end


% creates a decision tree (breadth first)
function buildTree(cand_selection_method, cand_selection_percent,memory)
    global population;
    global nodes;
    global k;

    n = 1;

    % n points to the current nodes we are trying to create branches on. We linearly
    % walk through the tree list of nodes attempting to branch on those nodes that 
    % are not leafs(able to branch). We stop when we reach the end of hte node list
    % because this means all the nodes prior to it have become leafs or are already
    % branched.
    while(n < size(nodes)(1)+1)
        % Check if there are a minimum number of datapoints in the node. If there are
        % not enough datapoints at the node, then this node becomes a leaf
        if(sum(nodes(n).datapoints) < k.MIN_POPULATION_SIZE)
            nodes(n).ldesc = k.LEAF_NODE;
            nodes(n).rdesc = k.LEAF_NODE;
            n = n+1;
            continue;
        % Check if this node either has branches(>1) or is a leaf(=0) and skip it
        elseif(nodes(n).ldesc != k.NULL)
            n = n+1;
            continue;
        end

        % Since we aren't a leaf or already branched, create branches
        [ldesc,rdesc,hyperplane] = GenDCHyper(nodes(n),cand_selection_method, cand_selection_percent,memory);
        printf('BUILDING NODES: %d\n',n)
        nodes(n),ldesc, rdesc;
        descs = [ldesc, rdesc];
        dtree_size = size(nodes)(1);

    	%% Copy up the features used to create these nodes and clear
    	%% their features to avoid bugs at the leaves
    	nodes(n).featuresp = ldesc.featuresp;
    	descs(1).featuresp = repmat(0,1,population.F-1);
    	descs(2).featuresp = repmat(0,1,population.F-1);
    	nodes(n).hyperplane = hyperplane; %% copy up the hyperplane

        % Need to set up the new branches
        % Have the ancestor point to the decendants. Check the accuracy of the
        % descendants. if they are above thresholds, then set them up as leaf node
        for d = 1:2
            descAccuracy = getAccuracy(descs(d));
            nodes = [nodes(:); descs(d) ];
            nodes(dtree_size+d).ancestor=n;
            if(d == 1)
                nodes(n).ldesc = dtree_size+d;
            else 
               nodes(n).rdesc = dtree_size+d;              
            end
            if(descAccuracy < k.THRESHOLD_ACCURACY)
                nodes(dtree_size+d).ldesc = k.NULL;
                nodes(dtree_size+d).rdesc = k.NULL;
            else
                nodes(dtree_size+d).ldesc = k.LEAF_NODE;
                nodes(dtree_size+d).rdesc = k.LEAF_NODE;
            end
       end

        % Edge case where all the datapoints were placed in a single branch.
        % As this doesn't satisfy the previous tests and would cause the 
        % decision tree builder to build indefinitely, we set the newly 
        % created branches as leaf nodes.
        if(sum(ldesc.datapoints) == 0 || sum(rdesc.datapoints) == 0)
            nodes(dtree_size+1).ldesc = k.LEAF_NODE;
            nodes(dtree_size+1).rdesc = k.LEAF_NODE;
            nodes(dtree_size+2).ldesc = k.LEAF_NODE;
            nodes(dtree_size+2).rdesc = k.LEAF_NODE;
        end

       n = max(1,n-4);
    end
    
end


% Create the root node containing all data points.
function [root] = buildRootNode()
    global population;
    global k;

    % Initialize most field to temporary values. Indicate all datapoints and features available.
    ancestor = k.NULL;
    class  = k.NO_CLASS;
    costn = [population.fc];
    datapoints =  [repmat([1], 1, population.M)];
    featuresp =  [repmat([0], 1, population.F-1)];
    hyperplane = [];
    ldesc = k.NULL;
    numMisClassified = k.NO_MISCLASSIFICATION;
    rdesc = k.NULL;
    dsId = population.dsId;

    root = createDecTreeNode(datapoints, featuresp, costn, ancestor, ldesc, rdesc,
                      class, numMisClassified, hyperplane, dsId);
end

