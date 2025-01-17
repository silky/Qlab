% The abstract base sweep class.

% Author/Date : Blake Johnson / October 15, 2010
% Copyright 2013 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
classdef Sweep < handle
	properties
		label = 'Sweep'
		plotPoints
		points
        numSteps
		Instr
	end
	
	methods (Abstract)
		step(obj, index)
    end
    
    methods
        function val = get.plotPoints(obj)
            val = obj.points;
        end
    end
end