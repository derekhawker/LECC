% node: a node that we want to separate with an hyperplane
% given an input node, determine an acceptable starting feature(s) to use 
% before finding a separating hyperplane for the node
% featuresp: a list of 0s and 1s that shows the features to use initially in
% hyperplane placement
function [featuresp] = selectInitFeature (node)
    global population;

    printf ('selecting initial feature to use.\n')
    defaultFeaturesp = node.featuresp;

    % Add all feature constraints back in
    for f = 1:(population.F-1)
        population.lb(f) = 0;
        population.ub(f) = 0;
        node.featuresp(f) = 0;
    end

    % Add all datapoints constraints into f
    for f = (population.F+1):population.N
        if(node.datapoints(f-population.F) == 1)
            population.f(f) = population.mc(getClass(f-population.F)+1);
        else
            population.f(f) = 0;
        end
    end

    % Determine a hyperplane with no features available to use
    [x, fval, exitflags, output, lambda] = linprog(population.f, population.A, 
        population.b, population.Aeq, 
        population.beq, population.lb, 
        population.ub);

    % Use the decision cost (DC) of the no feature hyperplane as a ref
    dcLastbest = getDC(x, node.datapoints, node.featuresp, node.costn)
    
    % Try to find a single feature that improves DC over the no-DC ref
    dcMin = Inf; 
    feature = -1;
    for f = 1:(population.F-1)
        % Relax constraint and allow feature f to be used
        population.lb(f) = -Inf;
        population.ub(f) = Inf;
        node.featuresp(f) = 1;
        % population.lb(1)=-Inf;
        % population.ub(1)=Inf;

        % Find separating hyperplane with feature f included
        [x, fval, exitflags, output, lambda]=  linprog(population.f, population.A, 
            population.b, population.Aeq, 
            population.beq, population.lb, 
            population.ub);

        % Compute the decision cost with the new separating hyperplane
        dcCurr = getDC(x, node.datapoints, node.featuresp, node.costn);
        printf('\tP1  f:%d dcCurr:%f\n',f,dcCurr)

        % Save the DC if less than the minimum DC calculated so far
        % Also note the feature that was used in the separating hyperplane
        if (dcCurr < dcMin)
            dcMin = dcCurr
            feature = f;
        end

        node.featuresp(f) = 0;
        population.lb(f) = 0;
        population.ub(f) = 0;
    end


    if (dcMin < dcLastbest)
        printf('Selected feature on first phase\n')
        node.featuresp(feature) = 1;
        featuresp = node.featuresp;
        return;
    end


    dcRef = dcLastbest %% else if no good single feature was found %% Save original dc with all feature constraints 

    %% Remove all feature constraints in preparation for stage two where we select
    % all features and then iteratively remove them
    for f = 1:(population.F-1)
        population.lb(f) = -Inf;
        population.ub(f) = Inf;
        node.featuresp(f) = 1;
    end


    for i = 1:(population.F-1)
        dcCand = Inf;
        feature = -1;
        for j = 1:(population.F-1)
            if(node.featuresp(j) == 0)
                continue;
            end

            population.lb(j) = 0; 
            population.ub(j) = 0;
            node.featuresp(j) = 0;

            [x, fval, exitflags, output, lambda]=  linprog(population.f, population.A, 
                population.b, population.Aeq, 
                population.beq, population.lb, 
                population.ub);

            dcCurr = getDC(x, node.datapoints, node.featuresp, node.costn);
            printf('\tP2  f:%d dcCurr:%f\n',j,dcCurr)

            if (dcCurr < dcCand)
                dcCand = dcCurr
                feature = f;
            end

            % remove the temporaryfeature constraint
            population.lb(j) = -Inf;
            population.ub(j) = Inf;
            node.featuresp(j) = 1;

        end


        % Check if the candidate with the lowest decison cost is still less than the ref
        % Otherwise we are done with phase two
        if (dcCand < dcRef)
            % It is, so permanently add the feature constraint
            population.lb(j) = 0;
            population.ub(j) = 0;
            node.featuresp(j) = 0;
        else
            printf('Selected features on second phase\n')
            featuresp = node.featuresp;
            return;
        end

    end


    % Shouldn't get here. It means we readded all feature constraints in the previous
    % loop. Definitely an error. Print message and just use the previous nodes 
    % selected features
    printf('WARNING: selectInitFeature did not select a feature. Using defaults.\n')
    node.featuresp = defaultFeaturesp;
    featuresp = defaultFeaturesp;

    % Edge case where defaultFeaturesp has no features. Just add all features in
    if sum(node.featuresp) == 0
        printf('Warning: selectInitFeature was not able to select a feature(s). Using all features\n')
    	node.featuresp = repmat(1,1,population.F-1);
    	featuresp = node.featuresp;
    end


end
