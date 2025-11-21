function s = run_model(p, t, f, a, path_out)

% RUN_MODEL Run FjordRPM simulation.
%   s = RUN_MODEL(p, t, f, a, path_out) runs the FjordRPM simulation for
%   parameters structure p, time vector t, forcings structure f, initial
%   conditions structure a, and returns solution structure s. If path_out
%   is specified, RUN_MODEL will save a file.

%% check for errors in the given inputs
[p, t, f, a] = check_inputs(p, t, f, a);

%% preallocate and initialise variables
s = initialise_variables(p, t, f, a);

%% the timestepping loop
for i = 1:length(t)-1

    % homogenise heat & salt content of layers where density is unstable
    s = homogenise_unstable_layers(i, p, s);
    
    % compute the fluxes ready for next timestep
    s = compute_fluxes(i, p, s);

    % step the tracers forward in time
    s = step_solution_forwards(i, p, s);

    % optional runtime plotting
    if p.plot_runtime
        plot_runtime_profile(i, p, t, s);
    end

    % check for errors at this new timestep
    status = check_solution(i, s);
    
end

%% organise final output to save
s = get_final_output(p, t, s, status);

%% save output if a path and file name are provided
if nargin > 4
    save_output(p, t, f, a, s, path_out);
end

end