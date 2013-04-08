

function [dectree, unpruned] = genDecTreeSINF (dsId,fc_file="", mc_file="", \
				     data_file="")
    global population;
    global nodes;
    global k;
debugcount=0;
   
    if (dsId == 0)
       population = createPopulation(dsId, fc_file, mc_file, \
				     data_file);
    else
      population = createPopulation(dsId);
    end


    % Create the very root node(all datapoints, no costs are zeroed. No hyperplane)
    rootNode = buildRootNode();
    nodes  = [rootNode];


    % build tree(recursively)
    buildTreeSINF()

    %%for n=1:size(nodes)
    %%    printf('Node (%d)\n',n);
  %%      nodes(n);
%%    end
  %%  outputDecTreeToFile(nodes,'unpruned');
    [acc tc ec ef] = getTreeAccuracy(nodes);
    debugcount=debugcount+1;
    printf('DEBUG COUNT: %d\n',debugcount);
    printf('UNPRUNED: Accuracy %f, Cost %f, EC %f EF ',acc,tc,ec)
    disp(ef)
    % Post process the tree to remove cost ineffective nodes
    unpruned = nodes;
    dectree = postProcess(nodes);     
%%    outputDecTreeToFile(dectree, 'pruned');
    [acc tc ec ef] = getTreeAccuracy(dectree);
    printf('Debug Count: %d\n', debugcount);
    printf('PRUNED: Accuracy %f, Cost %f, EC %f, EF %f',acc,tc,ec)
    disp(ef)
end


function buildTreeSINF()
    global population;
    global nodes;
    global k;

    n = 1;

    while(n < size(nodes)(1)+1)
        % printf('dtree count: %d of %d\n',n, size(nodes)(1))
        if(sum(nodes(n).datapoints) < k.MIN_POPULATION_SIZE)
            nodes(n).ldesc = k.LEAF_NODE;
            nodes(n).rdesc = k.LEAF_NODE;
            n = n+1;
            continue;
        elseif(nodes(n).ldesc != k.NULL)
            n = n+1;
            continue;
        end


        [ldesc,rdesc,hyperplane] = GenSINFHyper(nodes(n));
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

        for d = 1:2
            descs(d).datapoints;
            descs(d).class;
            descAccuracy = getAccuracy(descs(d));
            descs(d).numMisClassified;
%%            descs(d).hyperplane = hyperplane;

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

        if(sum(ldesc.datapoints) == 0 || sum(rdesc.datapoints) == 0)
            nodes(dtree_size+1).ldesc = k.LEAF_NODE;
            nodes(dtree_size+1).rdesc = k.LEAF_NODE;
            nodes(dtree_size+2).ldesc = k.LEAF_NODE;
            nodes(dtree_size+2).rdesc = k.LEAF_NODE;
        end

       n = max(1,n-4);
    end
end


function [root] = buildRootNode()
    global population;
    global k;

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

