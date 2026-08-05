Replace index.html, script.js, and content.js.

Root cause:
When Previous or Next was pressed while the dialog was already open, openWork() called dialog.showModal() again. Browsers throw an InvalidStateError when showModal() is called on an already-open dialog, interrupting video advancement.

Fix:
The dialog now calls showModal() only when it is not already open.

Build marker: video-advance-fix-20260804

index.html: f230c11cd59912f1207f436d16a31b0e8ab824d6c97d881d4a195de2ada39915
script.js: 91f24d2179766c6c1d4fee9f844d61f53cd149106d0b8fa92c8ecabbb8b8c377
content.js: d570c361d781a5c3eb2fd8031b8fd7540f8dc7cefaa57e0ae2d907796fb15239
