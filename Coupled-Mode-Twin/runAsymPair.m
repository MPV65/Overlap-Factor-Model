function [tout, Nout] = runAsymPair(tsim, QA, QB, etaAB, etaBA, theta, DW, param, varargin)
% RUNASYMPAIR Runs the temporal evolution of the asymmetric pair model 
%%
% *RUNASYMPAIR*
%
%%  Description
%
% Runs the temporal evolution of the asymmetric pair model 
%
%%  Usage
%
%   [tout, Nout] = runCoupled1D(tsim, QA, QB, d, DW, param, varargin)
%
%%  Arguments
%
%   tsim        integer specifying the simulation time tspan via tspan =
%               tsim/yn, where yn is the recombination rate (in 1/ns) 
%
%   QA          Pump power in guide (1)
%
%   QB          Pump power in guide (2)
%
%   etaAB       Amplitude of coupling coefficient of B laser in dYA/dt
%
%   etaBA       Amplitude of coupling coefficient of A laser in dYB/dt
%
%   theta       Phase of complex coupling 
%
%   DW          frequency detuning (rad/ns)
%
%   param       structure containing laser parameters:
%
%               param.aH    Linewidth enhancement factor
%               param.k0    free space wavevector (1/micron)
%               param.kp    1/(2*tau_p) - cavity loss rate (1/ns)
%               param.n1    core refractive index 
%               param.n2    cladding refractive index
%               param.yn    1/(tau_N) - carrier recombination rate (1/ns)
%
%   varargin    optional values:
%
%                   opt(1)  a numeric value. If greater than zero, the
%                           graphs are plotted
%                   opt(2)  a 5 x 1 array containing initial values:
%
%                       N0(1)   Carrier concentration in guide A
%                       N0(2)   Carrier concentration in guide B
%                       N0(3)   Optical amplitude in guide A
%                       N0(4)   Optical amplitude in guide B
%                       N0(5)   Relative phase between fields in A and B
%
%%  Returns
% 
%   Nout        4001 x 5 array containing the time evolution of variables
%
%                   Nout(:,1)   Carrier concentration in guide A
%                   Nout(:,2)   Carrier concentration in guide B
%                   Nout(:,3)   Optical amplitude in guide A
%                   Nout(:,4)   Optical amplitude in guide B
%                   Nout(:,5)   Relative phase between fields in A and B
%
%   tout        4001 x 1 array of corresponding time values
%
%%  Dependencies
%
%   This routine calls:
%
%       <singleSlab.html singleSlab> - calculates the coupling coefficient
%       <coupled1D.html coupled1D> - the model rate equations
%
%%

    % Flag to plot graphs
    plotgraphs = false;
    no_initial = true;

    % Check for flag to plot graphs
    if (nargin > 8)

        if (varargin{1} > 0)
            
            plotgraphs = true;
            
        end

    end
    
    % Check for intial values
    if (nargin > 9)

        N0 = varargin{2};
        
        sz = size(N0);
        
        if ((sz(1) ~= 5)||(sz(2)~=1))
            
            error('Initial values are not given in a 5 x 1 array')
            
        end
        
        no_initial = false;

    end

    if (QA < 0)
        error('eta1 cannot be negative')
    end

    if (QB < 0)
        error('eta2 cannot be negative')
    end

    % Extract waveguide parameters
    k0 = param.k0;
    n1 = param.n1;
    n2 = param.n2;

    % Set additional required parameters
    param.QA = QA;
    param.QB = QB;
    param.etaAB = etaAB;
    param.etaBA = etaBA;
    param.theta = theta;
    param.DW = DW;
    
    
    % Set local variables to report
    yn = param.yn;
    kp = param.kp;
    aH = param.aH;
    theta = param.theta;

    runstr = 'Asymmetric Pair (coupling coefficients set, not calculated)'; 

    % Output parameters 
    disp(' ');
    disp(datestr(now));
    disp(' ');
    disp(runstr);
    disp(' ');
    disp('Guide parameters:');
    disp(['k0 = ' num2str(k0) ' - free-space wavevector (rad/micron)']);
    disp(['n1 = ' num2str(n1) ' - refractive index in guides']);
    disp(['n2 = ' num2str(n2) ' - refractive index outside guides']);
    disp(['etaAB = ' num2str(etaAB) ' - Amplitude of coupling coefficient of B laser in dYA/dt']);
    disp(['etaBA = ' num2str(etaBA) ' - Amplitude of coupling coefficient of A laser in dYB/dt']);
    disp(['theta = ' num2str(theta) ' - coupling coefficient (argument)']);
    disp(['DW = ' num2str(DW) ' - frequency detuning']);

    disp(' ');
    disp('General parameters:');
    disp(['kp = ' num2str(kp) ' - the cavity loss rate (ns^-1)']);
    disp(['aH = ' num2str(aH) ' - linewidth enhancement factor']); 
    disp(['yn = ' num2str(yn) ' - recombination rate (ns^-1)']);
    disp(' ');
    disp('Individual guide parameters:');
    disp(['QA = ' num2str(QA) ' - total pump power in guide (1)']);   
    disp(['QB = ' num2str(QB) ' - total pump power in guide (2)']);
    disp(' '); 
    disp(['Simulation time = ' num2str(tsim) '/yn = ' num2str(tsim/yn) ' ns']);

    if (no_initial)
        % Set default initial conditions
        N0 = zeros(5,1);
        %
        %   Carrier concentrations:
        %       MA = N0(1);         % Carrier concentration in guide A
        %       MB = N0(2);         % Carrier concentration in guide A
        %   Optical fields:
        %       YA = N0(3);         % Amplitude in guide A
        %       YB = N0(4);         % Amplitude in guide B
        %       phi = N0(5);        % Relative phase between fields in A and B

        MA = 0.0;   % Guide 1
        MB = 0.0;   % Guide 2

        % Steady state solutions
        % dM = 0.000001;
        % MS = 1.0;
        % MA = MS + dM;   % Guide 1
        % MB = MS + dM;   % Guide 2

        IA = 1E-4;          % Initial signal power symmetric mode 
        IB = 1E-4;          % Initial signal power anti-symmetric mode 
        YA = sqrt(IA);      % symmetric component of light 
        YB = sqrt(IB);      % anti-symmetric component of light 

        % Steady state solutions
        % dA = 0.000001;
        % YAS = real(sqrt(QA - 1));
        % YBS = real(sqrt(QB - 1));
        % YA = YAS + dA;   % Guide 1
        % YB = YBS + dA;   % Guide 2

        phi = 0.001;        % Phase 

        N0(1) = MA;         % Carrier concentration in guide A
        N0(2) = MB;         % Carrier concentration in guide B
        N0(3) = YA;     	% Amplitude in guide A
        N0(4) = YB;     	% Amplitude in guide B
        N0(5) = phi;        % Relative phase between fields in A and B
        
    end

    % Time span (yn = 1/tau, where tau is the lifetime)
    maxt = tsim/yn;
    mint = 0.0;
    npts = 4001; 
    dt = (maxt - mint)/(npts - 1.0);

    tspan = mint:dt:maxt;

    odefun = @(t, N) asymPair(t, N, param); % Anonymous handle to function

    reltol = 1E-6;
    options = odeset('RelTol', reltol);

    % Runge-Kutta implementation
    [tout, Nout] = ode45(odefun, tspan, N0, options);    

    % Output values
    MAt = Nout(:,1);
    MBt = Nout(:,2);
    YAt = Nout(:,3);
    YBt = Nout(:,4);
    phit = Nout(:,5);

    % Test derivatives at end of calculation
    Nt = transpose(Nout(end,:));
    dN = asymPair(maxt, Nt, param);

    dMAdt = dN(1);
    dMBdt = dN(2);
    dYAdt = dN(3);
    dYBdt = dN(4);
    dphidt = dN(5);

    % Output results
    disp(' ');
    disp('At end of simulation:');
    disp(['N(1) = ' num2str(MAt(end))]);
    disp(['N(2) = ' num2str(MBt(end))]);
    disp(['A_{1} = ' num2str(YAt(end))]);
    disp(['A_{2} = ' num2str(YBt(end))]);
    disp(['phi = ' num2str(phit(end))]);
    disp(' ');

    disp('Derivatives:');
    disp(['dN1/dt = ' num2str(dMAdt)]);
    disp(['dN2/dt = ' num2str(dMBdt)]);
    disp(['dA1/dt = ' num2str(dYAdt)]);
    disp(['dA2/dt = ' num2str(dYBdt)]);
    disp(['dphi/dt = ' num2str(dphidt)]);


	if plotgraphs

        % Plot solution
        lw = 1.5; % linewidth

        % Plot carriers 
        figure;
        hold on;
        plot(tout, MAt, 'LineWidth', lw);
        plot(tout, MBt, 'LineWidth', lw);
        title(['Carriers: QA = ' num2str(QA) ', QB = ' num2str(QB) ' (coupled)']);
        ylabel('Carrier concentration');
        xlabel('Simulation time (1/\gamma)');
        legend('N^{(1)}', 'N^{(2)}');
        grid on;

        IA = YAt.*YAt;
        IB = YBt.*YBt;

        % Plot intensities
        figure;
        hold on;
        plot(tout, IA, 'LineWidth', lw);
        plot(tout, IB, 'LineWidth', lw);
        title(['Intensities: QA = ' num2str(QA) ', QB = ' num2str(QB) ' (coupled)']);

        ylabel('Optical intensity');
        xlabel('Simulation time (1/\gamma)');
        legend('I_{1}','I_{2}');
        grid on;

        % Plot phase
        figure;
        hold on;
        plot(tout, phit, 'LineWidth', lw);
        title(['Phase: eta1 = ' num2str(QA) ', eta2 = ' num2str(QB)]);
        ylabel('Relative phase');
        xlabel('Simulation time (1/\gamma)');
        %ylim([-2*pi 2*pi]);
        grid on;

	end

end






