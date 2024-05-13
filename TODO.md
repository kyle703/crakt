#  TODOs

# Alpha Release


    [] Metrics on sessions
        []  Fix hover on chart
        [X] Move to tiles with previews and NavLink to detail chart
        [x] Add line chart preview for histogram view
        
    [X] Add route detail list into Session Detail
    [] Update Active Route selection
    [] Add timer to each route with splits per attempt
    
    [] Level of effort 
        - (Hard, just right, soft) for the grade?  
        - 
    [] Sort Routes by date
    [] update route log timestamp format 
        - 1st attempt: hh:mm:ss
        - following: hh:mm:ss + elapsed_time

    [] bug: When changing grades with a climb selected, the grade stays selected for the next route. Clear the date on grade change and log the route if any attempts logged
    
    [] Apple developer license
    
 
 
 ----- Cut line ----- 
 
     [] TAGS!!! Route style tags
        
        
    ### Route Types
    - Slab
    - Overhang
    - Vertical
    - Dihedral
    - Roof

    ### Grip Types
    - Jugs
    - Crimps
    - Slopers
    - Pinches
    - Pockets

    ### Movement Styles
    - Dynamic
    - Static
    - Technical
    - Balancy
    - Powerful

    ### Texture
    - Textured
    - Smooth
    - Grippy
    - Slippery
    - Dual-tex


## Active Session View

 [X] Move climb/system menus to top
 [X] Have grade selector start with no selection
 [X] Modify "climb on" to next if there is an active session
 [X] Disable flash if not first attempt
 [X] Scroll route list to bottom on add
 [X] Connect active climb to session header counts
 [X] Connect session state to core data on exit
 [X] Modify to show send icons if it's active
 [x] Make climb on action button float on top 
 
 
 [X] Change action button options for bouldering vs ropes (no topped on boulders, just fall, send, flash)
    - standardize climb status enums
    
 [] Add Location to Session start
  - need to scrape a list of climbing gyms...
 [] Update grade system selector to use abbr text
 [] Undo/Redo


 ## Analytics
 
 ### Charts
 
 **Previews**: Each chart should have a preview mode so it can be used in other views


 P0: Session Overview: 
     - Pie charts
        - difficulty per route
        - hold slice to view distribution
        - annotations show grade, difficulty and 
        
     - Histograms:
        - Route difficulty by time
        - 
        
    - Bar Charts
        - Attempt status of grouped by route grade. Ordered ascending by normalized grade
        - Attempt status of each route. Ordered 
        
    - Line charts
      - difficulty of each route by attempt time. One mark per attempt
      - preview: route difficulty by route **order**. One bar per **route** 
      
      
 P2: Session History:
    - Metrics for sessions over time
    - Average normalized grade per session
    - Highest grade per climb
    - Median sends
     
 ## Session Detail
 Session Detail Metrics:
    - Tile containing a metrics preview for each se 
 
 
 ## Home/Session log 
 [X] Overview collection layout
 [X] Session collection item
 [X] Session details view
 [] Metrics on sessions
    - duration based: Avg time on route. Session time historical comparison
    - difficulty based: success rate per grade, highest difficulty, avg difficulty
 [] 
 
 
 
 # Styling
 [] As a user, I would like the ability to change the color palette of the grade distribution visualizations
    - Handpicked pallete options
    - Apply different grade gradients with large vertical multi-slider where each point is the boundary for the grade
    - Dependent on creating a Settings View and adding a User concept
 
 
 # Database
 [X] Convert data model to SwiftData
 [X] Convert interface functions to SwiftData queries
 
 


## Grades
[] Apply gradient coloring to active/logged route grade bubble?
