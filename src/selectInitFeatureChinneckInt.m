% given an input node, determine an acceptable starting feature(s) to use 
% before finding a separating hyperplane for the node
%% Uses Chinneck's Int method 

function [featuresp] = selectInitFeatureChinneckInt (node)
    global population;

    printf ('selecting initial feature to use.\n');
    defaultFeaturesp = node.featuresp;

    node.datapoints;
    node.featuresp;

    % Add all feature constraints back in (exclude all features)
    for f = 1:(population.F-1)
        population.lb(f) = 0;
        population.ub(f) = 0;
        node.featuresp(f) = 0;
    end

    % Add all datapoints constraints into f that are in node
    for f = (population.F+1):population.N
        if(node.datapoints(f-population.F) == 1)
            population.f(f) = 1;
        else
            population.f(f) = 0;
        end
    end

    % Determine a hyperplane with no features available to use
    [x, fval, exitflags, output, lambda] = linprog(population.f, population.A, 
        population.b, population.Aeq, 
        population.beq, population.lb, 
        population.ub);

    SINFLastBest = fval;
    
    % Try to find a single feature that improves DC over the no-DC ref
    SINFMin = Inf; 
    feature = -1;

    for f = 1:(population.F-1)
        % Relax constraint and allow feature f to be used
        population.lb(f) = -Inf;
        population.ub(f) = Inf;
        node.featuresp(f) = 1;

        % Find separating hyperplane with feature f included
        [x, fval, exitflags, output, lambda]=  linprog(population.f, population.A, 
            population.b, population.Aeq, 
            population.beq, population.lb, 
            population.ub);

	%% if SINF < SINFMin then SINFMin<--SINF
	if fval < SINFMin
	   SINFMin = fval;
	   feature = f;
	end

        node.featuresp(f) = 0;
        population.lb(f) = 0;
        population.ub(f) = 0;
    end


    if (SINFMin < SINFLastBest)
        printf('Selected feature on first phase\n')
        node.featuresp(feature) = 1;
        featuresp = node.featuresp;
        return;
    end


    SINFRef = SINFLastBest %% else if no good single feature was found %% Save original dc with all feature constraints 

    %% Remove all feature constraints (include all features)
    for f = 1:(population.F-1)
        population.lb(f) = -Inf;
        population.ub(f) = Inf;
        node.featuresp(f) = 1;
    end


    for i = 1:(population.F-1)
        SINFCand = Inf;
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

            if (fval < SINFCand)
                SINFCand = fval
                feature = f;
            end

            % remove the temporaryfeature constraint
            population.lb(j) = -Inf;
            population.ub(j) = Inf;
            node.featuresp(j) = 1;

        end


        % Check if the lowest candidate is still less than the ref
        if (SINFCand < SINFRef)
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
    % loop. Definitely an error. Print message and try to bring the program down
    printf('WARNING: selectInitFeature did not select a feature. Using defaults.\n')
    node.featuresp = defaultFeaturesp;
    featuresp = defaultFeaturesp;

    if sum(node.featuresp) == 0
        printf('Warning: selectInitFeature was not able to select a feature(s). Using all features\n')
	node.featuresp = repmat(1,1,population.F-1);
	featuresp = node.featuresp;
%%        exit(1)
    end


end
