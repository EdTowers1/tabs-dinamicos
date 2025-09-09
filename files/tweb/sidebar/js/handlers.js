/*
 handlers.js

 Sidebar UI handlers removed: project now uses a top navbar instead of the sidebar.
 Keep this file as a small safe stub to avoid 404s while templates still include it.

 Next cleanup options (manual):
 - remove the <script> include from files/tweb/tpl/libs.tpl
 - delete/or archive the sidebar JS and CSS files under files/tweb/sidebar/
 - remove _SidebarInit and any '.sidebar' references in files/tweb/tweb.js if no longer needed

 If you want, I can apply those removals too.
*/

;(function ($) {
  'use strict'

  // No-op stub: only log once if there are no .sidebar elements.
  $(function () {
    if ($('.sidebar').length === 0) {
      // eslint-disable-next-line no-console
      console.log('handlers.js: sidebar removed — running stub (no-op)')
      return
    }

    // If sidebar elements still present, do nothing to avoid side effects.
    // This keeps behavior safe and non-destructive.
    // eslint-disable-next-line no-console
    console.log('handlers.js: sidebar elements detected but handlers are disabled')
  })
})(jQuery)
