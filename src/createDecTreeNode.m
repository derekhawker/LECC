function [node] = createDecTreeNode(datapoints, featuresp, costn, ancestor,ldesc,
                             rdesc, class, numMisClassified, hyperplane, dsId)
    node = struct('ancestor', ancestor,                 
                  'class' , class,
                  'costn', costn,
                  'datapoints', datapoints,
                  'dsId',dsId,
                  'featuresp', featuresp,
                  'hyperplane', hyperplane,
                  'ldesc', ldesc,
                  'numMisClassified',numMisClassified,
                  'rdesc', rdesc);
end
