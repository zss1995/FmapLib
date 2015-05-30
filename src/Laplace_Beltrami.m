classdef Laplace_Beltrami < dynamicprops
    
    properties (GetAccess = public, SetAccess = private)
        W           = [];               % Weight matrix of cotangent Laplacian.
        M           = [];               % Associated Mesh of LB.   
        spectra     = containers.Map;   % A dictionary carrying various types of eigenvalues and eigenvectors
    end
    
    
    
    methods
    
        function obj = Laplace_Beltrami(in_mesh)
            % Class constructor.
            if nargin == 0                                                
                obj.M = [];          
                obj.W = [];
                obj.spectra = containers.Map;                
            else
                obj.M       = in_mesh;
                obj.spectra = containers.Map;
                if isprop(in_mesh, 'angles')
                    obj.W  = Laplace_Beltrami.cotangent_laplacian(in_mesh.vertices, in_mesh.triangles, in_mesh.angles);
                else
                    obj.W  = Laplace_Beltrami.cotangent_laplacian(in_mesh.vertices, in_mesh.triangles);
                end                       
            end                                                                            
        end
                
        function [evals, evecs] = get_spectra(obj, eigs_num, area_type)
            if ~ Mesh.is_supported_area_type(area_type)
                error('You specidied an area_type which is not supported by the Mesh Library.')
            end
            
            
            if ~ obj.spectra.isKey(area_type) || ...           % This type of spectra has not been computed before, or,
                size(obj.spectra(area_type).evals, 1) < eigs_num      % the requested number of eigenvalues is larger than what has been previously calculated.                
                
                try % Retrieve the vertex areas or compute them.
                    A = obj.M.get_vertex_areas(area_type);
                catch                                       
                    obj.M.set_vertex_areas(area_type);
                    A = obj.M.get_vertex_areas(area_type);
                end                
                A              = spdiags(A, 0, length(A), length(A));
                [evecs, evals] = Laplace_Beltrami.compute_spectra(obj.W, A, eigs_num);                
                obj.spectra(area_type) = struct('evals', evals, 'evecs', evecs); % Store computed spectra.
           
            else                                        % Use previously computed spectra.
                evals = obj.spectra(area_type).evals;
                evals = evals(1:eigs_num);                
                evecs = obj.spectra(area_type).evecs;
                evecs = evecs(:, 1:eigs_num);
            end
        end
        
        
%          function obj = set_cotangent_laplacian(obj)
%                 obj.addprop('cot_laplacian');            
%                 if isprop(obj, 'angles')
%                     obj.cot_laplacian = Mesh.cotangent_laplacian(obj.vertices, obj.triangles, obj.angles);
%                 else
%                     obj.cot_laplacian = Mesh.cotangent_laplacian(obj.vertices, obj.triangles);
%                 end            
%          end   
    
    
    end
    
    methods (Static)
        
        function [W] = cotangent_laplacian(V, T, varargin)
                % Add comments
                I = [T(:,1); T(:,2); T(:,3)];
                J = [T(:,2); T(:,3); T(:,1)];        
                                
                if nargin == 3
                    A = varargin{1};
                else
                    A = Mesh.angles_of_triangles(V, T);
                end
                
                S = 0.5 * cot([A(:,3); A(:,1); A(:,2)]);
                In = [I; J; I; J];
                Jn = [J; I; I; J];
                Sn = [-S; -S; S; S];
                
                nv = size(V, 1);
                W  = sparse(In, Jn, Sn, nv, nv);
                assert(isequal(W, W'))
        end
        
        function [Phi, lambda] = compute_spectra(W, vertex_areas, eigs_num)
            % Returns the sorted ..add comments..
            if eigs_num < 1 || eigs_num > size(W, 1)-1;
                error('Eigenvalues must be in range of [1, num_of_vertices-1].')
            end
            
            [Phi, lambda] = eigs(W, vertex_areas, eigs_num, -1e-5);
            lambda        = diag(lambda);
            lambda        = abs(real(lambda));
            [lambda, idx] = sort(lambda);
            Phi           = Phi(:,idx);
            Phi           = real(Phi);                 % LB is symmetric, thus Phi's are real.
        end
            
    end
    
end
