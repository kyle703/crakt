#  TODOs

# Alpha Release

## Session View

- [x] **Remove Debug UUID from Header**  
  - Replace with gym name, session date, or "Active Session" label.

- [x] **Timer Styling**  
  - Make timer value bold and central.  
  - Reduce "Total Session Time" label size and weight.  
  - Ensure pause/stop buttons have at least 44x44pt tap targets with consistent padding.

- [x] **Group Timer and Counters**  
  - Place Tops/Tries counters in same visual card as timer with clear dividers.  
  - Add icons for each counter (trophy for tops, hand/attempt icon for tries).  
  - Animate counter increment.

- [x] **Route Type & Grade Buttons**  
  - Add selected/unselected state colors.  
  - Ensure tap target is at least 44x44pt.  
  - Implement modal/sheet for changing grade type if not frequently changed.

- [x] **Empty State Improvements**  
  - Add secondary "Climb On" button.  
  - Ensure proper spacing and visual hierarchy.  
  - Use consistent button styling.

- [x] **Pause/End Session Buttons**  
  - Increase tap targets to 44x44pt minimum.  
  - Ensure consistent button height and alignment.  
  - Use stronger color contrast for better accessibility.

- [x] **Route Type & Grade Selectors**  
  - Add hover/pressed states for better visual feedback.  
  - Ensure dropdown caret is properly aligned with text/icon.  
  - Improve selected/unselected state styling.

- [ ] **Logged Route Card Styling**  
  - Use consistent padding inside the green route card.  
  - Align delete (trash) icon vertically to match card content.  
  - Make "4b" label size consistent with grade picker at bottom.

- [ ] **Logged Route Card Timers**  
  - Use same font style/size for "Total Time on Route" and "Rest Time" labels and values.  
  - Ensure labels are left-aligned and values right-aligned.  
  - Add subtle divider between the two time rows.

- [ ] **Route Outcome Buttons (Fall, Send, Topped, Flash)**  
  - Increase vertical padding for better tap comfort.  
  - Align icons and text consistently across all four buttons.  
  - Apply consistent corner radius and border thickness.

- [ ] **Log It Button**  
  - Ensure it has a full-width tappable area within the card.  
  - Maintain visual consistency with the primary CTA style used in other screens.

- [ ] **Empty State (No Routes Logged)**  
  - Center align empty state icon and text block.  
  - Add descriptive subtext encouraging action (“Start your climbing session by logging your first route”).  
  - Make “Log Your First Route” the primary button (blue) and “Climb On” secondary (outlined).  
  - Ensure buttons stack with consistent spacing on small screens.

- [ ] **Grade Selection Row**  
  - Ensure even horizontal spacing and consistent button sizes.  
  - Highlight selected grade with distinct color fill and bold text.  
  - Make the row horizontally scrollable if overflow occurs on small devices.

- [ ] **Prevent Accidental Navigation**  
  - Disable or confirm navigation when tapping other tabs during active session.  
  - Optionally replace tab bar with a persistent “Return to Session” banner if the user navigates away.



- [x] **Empty Route Logs State**  
  - Replace "No route logs yet!" with a CTA button: "Log your first route".  
  - Tapping CTA opens grade selector.  
  - Optional: add small illustration asset above text.

- [x] **Grade Selection Row Improvements**  
  - Space grade buttons evenly with consistent padding.  
  - Make selected grade visually distinct with color fill or border.  
  - Ensure buttons are at least 44x44pt and horizontally scrollable if overflow.

- [ ] **Disable Tab Navigation During Active Session**  
  - Replace tab bar with single "End Session" or "Session Summary" button while session is active.


## Home View
- [x] **Personalize Greeting**  
  - Show name and recent stat in subtitle.  
  - Fallback to generic copy if no data.  
  - Unit tests for both states.

- [x] **Recent Activities Feed: Layout Redesign**  
  - Convert to full-width tappable rows.  
  - Each row shows gym name, date, time, route and attempt counts when available.  
  - Divider and right chevron affordance.

- [x] **Recent Activities: Empty State**  
  - If no sessions, hide rows and show single CTA block with copy and button to Start Session.  
  - Analytics event logged.

- [x] **Hide Zero Metrics on Cards**  
  - Do not render "0 Routes | 0 Attempts".  
  - Replace with "No routes logged" only when session exists without routes.

- [x] **Primary CTA Placement**  
  - Move "Start a New Session" below Recent Activities.  
  - Maintain sticky visibility when scrolling.  
  - Haptic on tap.

- [x] **Lifetime Stats Card Tuning**  
  - Reduce visual weight and spacing.  
  - Ensure consistent padding and alignment.  
  - Cards remain tappable to open Stats tab.

- [ ] **Tab Bar Active State**  
  - Increase active label contrast and weight.  
  - Snapshot tests for light and dark mode.

- [ ] **Profile/Settings Button Hit Area**  
  - Increase to 44x44 pt minimum.  
  - Add content inset to match.  
  - UI test for tap reliability.

- [x] **Icon Unification**  
  - Replace custom icons with SF Symbols.  
  - Use consistent weight and size across stat cards.  
  - Verify in light and dark mode.

- [x] **Locale-aware Date and Time**  
  - Use DateFormatter with .medium styles.  
  - Example: "Jan 30, 5:07 AM" in US locale.  
  - Unit tests for multiple locales.

- [x] **Accessibility: VoiceOver Grouping**  
  - Combine icon, value, and label per stat into a single accessibility element with a clear label.  
  - Ordered traversal for header, activities, stats, CTA.

- [x] **Accessibility: Tap Targets and Fonts**  
  - Ensure all interactive elements meet 44x44 pt.  
  - Raise small subtitle fonts to 13–14 pt.  
  - Dynamic Type support verified.

- [x] **Section Visual Separation**  
  - Add subtle background tints or headers for "Recent Activities" and "Lifetime Stats".  
  - No functional changes.

- [x] **Empty Data Copy and Illustrations**  
  - Add friendly copy for first-time use.  
  - Optional lightweight illustration asset.  
  - Localizable strings.

- [x] **Analytics Instrumentation**  
  - Track taps on Recent Activity row, Start Session CTA, Stats cards, Profile.  
  - Track impressions of empty state.

- [x] **Theming and Dark Mode Audit**  
  - Validate colors for contrast.  
  - Update blue CTA color if needed to meet WCAG.

- [x] **Snapshot and UI Tests**  
  - Add snapshots for home variants: empty, some activity, long names, large text.  
  - UI tests for navigation from rows and CTA.

- [x] **Performance Pass**  
  - Ensure home screen loads in under 200 ms after data is available.  
  - Defer non-critical work to background.
    
    [x] Update Activity View
        Remove the action bar in favor of an action card that covers the majority of the screen.
        Make the background of the rounded card the color of the corresponding grade and add a grade badge to the header on the top right of the header add an icon delete button
        The body of the card should have the action buttons in a large 2x2 square 
        The top of the body should include the different attempt statuses
        Add a Total time on route timer as well as a current rest time
        At the bottom of the body there should be a wide log it button        


    [X] Metrics on sessions
        [X]  Fix hover on chart
        [X] Move to tiles with previews and NavLink to detail chart
        [x] Add line chart preview for histogram view
        
    [X] Add route detail list into Session Detail
    [X] Update Active Route selection
    [] Add timer to each route with splits per attempt
        - Time elapsed per attempt
        - Add a timer since last attempt
        - How to indicate rest vs actual climbing?
    
    [] Level of effort - not for alpha
        - (Hard, just right, soft) for the grade?  
        
    [] Sort Sessions by date 
    [] update route log timestamp format 
        - 1st attempt: hh:mm:ss
        - following: hh:mm:ss + elapsed_time

    [] bug: When changing grades with a climb selected, the grade stays selected for the next route. Clear the date on grade change and log the route if any attempts logged
        - Can't repro? 
    
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
    - Tile containing a metrics preview for each sesh
 
 
 ## Home/Session log 
 [X] Overview collection layout
 [X] Session collection item
 [X] Session details view
 [] Metrics on sessions
    - duration based: Avg time on route. Session time historical comparison
    - difficulty based: success rate per grade, highest difficulty, avg difficulty
 [] 
 
 
 
 # Circuit Grade Builder
 [] As a user, I would like the ability to change the color palette of the grade distribution visualizations
    - Handpicked pallete options
    - Apply different grade gradients with large vertical multi-slider where each point is the boundary for the grade
    - Dependent on creating a Settings View and adding a User concept
 
 
 # Database
 [X] Convert data model to SwiftData
 [X] Convert interface functions to SwiftData queries
 
 


## Grades
[] Apply gradient coloring to active/logged route grade bubble?
