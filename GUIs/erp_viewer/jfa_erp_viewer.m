function jfa_erp_viewer()
%demoBrowser: an example of using layouts to build a user interface
%
%   demoBrowser() opens a simple GUI that allows several of MATLAB's
%   built-in demos to be viewed. It aims to demonstrate how multiple
%   layouts can be used to create a good-looking user interface that
%   retains the correct proportions when resized. It also shows how to
%   hook-up callbacks to interpret user interaction.
%
%   See also: <a href="matlab:doc Layouts">Layouts</a>

%   Copyright 2010-2013 The MathWorks, Inc.

% Data is shared between all child functions by declaring the variables
% here (they become global to the function). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another. As the app
% grows, we might consider making these objects rather than structures.


%% Setup Data
pheightmin = 20;   % Height for minimized control panels 
pheightmax = 200;  % Height for maximized control panels

S.data = createData();

%% Setup GUI
S.gui  = createInterface( S.data );

%% Now update the GUI with the current data
updateInterface();
redrawDemo();








%% -----------------------------------------------------------------------%
    function data = createData()

        
        % Create the shared data-structure for this application


        % Load an example ERPSET
        ALLERP(1) = pop_loaderp(            ...
            'filename', 'S1_ERPs.erp'       , ...
            'filepath', './example_data/'   );
        ALLERP(2) = pop_loaderp(            ...
            'filename', 'S2_ERPs.erp'       , ...
            'filepath', './example_data/'   );
        
        
        data = struct( ...
            'ALLERP'            , ALLERP                , ...
            'SelectedPoints'    , ALLERP(1).pnts        , ...
            'SelectedBins'      , [1]                   , ...
            'SelectedChannels'  , [1]                   , ...
            'SelectedERPs'      , [1]                   ); %#ok<NBRAK>
        
        
    end % createData

%-------------------------------------------------------------------------%
    function gui = createInterface( data )
        % Create the user interface for the application and return a
        % structure of handles for global use.
        gui = struct();
        % Open a window and add some menus
        gui.Window = figure( ...
            'Name'              , 'New ERP Viewer'  , ...
            'NumberTitle'       , 'off'             , ...
            'MenuBar'           , 'none'            , ...
            'Toolbar'           , 'none'            , ...
            'HandleVisibility'  , 'off'             );
        
        
        %% Create Menu Bar Items
        % + File menu
        gui.FileMenu = uimenu( gui.Window, 'Label', 'File' );
        uimenu( gui.FileMenu, 'Label', 'Exit', 'Callback', @onExit );
        
        
        %% Arrange the main interface
        mainLayout = uix.HBoxFlex( 'Parent', gui.Window, 'Spacing', 3 );

        
        %% + Create the ERP view panel
        gui.controlPanel = uix.BoxPanel( ...
            'Parent'    , mainLayout );
        gui.ViewPanel = uix.BoxPanel( ...
            'Parent'    , mainLayout, ...
            'Title'     , 'Viewing: ???', ...
            'HelpFcn'   , @onDemoHelp );
        gui.ViewContainer = uicontainer( ...
            'Parent'    , gui.ViewPanel );        

        
        %% + Create the controls
        controlLayout = uix.VBox( ...
            'Parent'    , gui.controlPanel, ...
            'Padding'   , 3 , ...
            'Spacing'   , 3 );

        % + Adjust the main layout
        set( mainLayout, 'Widths', [-1,-2]  );
        
        
        measurementPanel  = uix.BoxPanel( ...
            'Title' , 'measurement'     , ...
            'Parent', controlLayout     ); %#ok<NASGU>
        scalesPanel       = uix.BoxPanel( ...
            'Title' , 'scales'          , ...
            'Parent', controlLayout     ); %#ok<NASGU>
        valuesPanel       = uix.BoxPanel(  ...
            'Title' , 'plot values'     , ...
            'Parent', controlLayout     ); %#ok<NASGU>
        colorPanel        = uix.BoxPanel( ...
            'Title', 'color'            , ...
            'Parent', controlLayout     ); %#ok<NASGU>
        
        
        
        %% Add 2 Horizontal Button Boxes
        %         hbox = uix.HButtonBox( ...
        %             'Parent', controlLayout, ...
        %             'Spacing', 10, ...
        %             'Padding', 1 );
        %         gui.CancelButton = uicontrol( ...
        %             'Style', 'PushButton', ...
        %             'Parent', hbox, ...
        %             'String', 'Cancel' );
        %         gui.MeasurementToolButton = uicontrol( ...
        %             'Style', 'PushButton', ...
        %             'Parent', hbox, ...
        %             'String', 'Measurement Tool' );
        

                

        
        
        
        % Make the Panel list fill the space
        panelHeights = zeros([1 length(controlLayout.Contents)])+pheightmax;
        set( controlLayout, 'Heights', panelHeights ); 
        
        % + Create the view
        p = gui.ViewContainer;
        gui.ViewAxes = axes( 'Parent', p );
        
        
        
        %% Hook up the minimize callback function: `MinimizeFcn`
        for panelIndex = 1:length(controlLayout.Children)
            if(strcmpi(controlLayout.Children(panelIndex).Type, 'uipanel'))
                set( controlLayout.Children(panelIndex), 'MinimizeFcn', ...
                    {@nMinimize, panelIndex} );
            end
        end
        
        
    end % createInterface

%-------------------------------------------------------------------------%
    function updateInterface()
        % Update various parts of the interface in response to the GUI
        % being changed.
        
        % Update the list and menu to show the current demo
        %         set( gui.ListBox, 'Value', data.SelectedDemo );
        % Update the help button label
        %         demoName = data.DemoNames{ data.SelectedDemo };
        %         set( gui.HelpButton, 'String', ['Help for ',demoName] );
        % Update the view panel title
        %         set( gui.ViewPanel, 'Title', sprintf( 'Viewing: %s', demoName ) );
        % Untick all menus
        %         menus = get( gui.ViewMenu, 'Children' );
        %         set( menus, 'Checked', 'off' );
        % Use the name to work out which menu item should be ticked
        %         whichMenu = strcmpi( demoName, get( menus, 'Label' ) );
        %         set( menus(whichMenu), 'Checked', 'on' );
    end % updateInterface

%-------------------------------------------------------------------------%
    function redrawDemo()
        % Draw a demo into the axes provided
        
        % We first clear the existing axes ready to build a new one
        %         if ishandle( gui.ViewAxes )
        %             delete( gui.ViewAxes );
        %         end
        
        % Now copy the axes from the demo into our window and restore its
        % state.
        
        % Get rid of the demo figure
%         close( fig );
    end % redrawDemo



%-------------------------------------------------------------------------%
    function onExit( ~, ~ )
        % User wants to quit out of the application
        delete( gui.Window );
    end % onExit


%% JFA Adds

    function nMinimize( ~, ~, whichpanel )
        % A panel has been maximized/minimized
        allGUIControlPanels = S.gui.controlPanel.Children;
        currGUIControlPanel = S.gui.controlPanel.Children.Children(whichpanel);
        panelHeights   = get( allGUIControlPanels, 'Heights' );
        panelHeights   = flipud(panelHeights);
        %         pos = get( gui.Window, 'Position' );
        currGUIControlPanel.Minimized = ~currGUIControlPanel.Minimized;
        if currGUIControlPanel.Minimized
            panelHeights(whichpanel) = pheightmin;
        else
            panelHeights(whichpanel) = pheightmax;
        end
        panelHeights    = flipud(panelHeights);
        set( allGUIControlPanels, 'Heights', panelHeights );
        
        % Resize the figure, keeping the top stationary
        delta_height = pos(1,4) - sum( S.gui.controlPanel.Children.Heights );
        set( S.gui.Window, 'Position', pos(1,:) + [0 delta_height 0 -delta_height] );
    end % nMinimize

end % EOF