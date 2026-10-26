// Closes the "Download resume" menu after a choice or a click anywhere else on the page.
(() => {
  const menu = document.querySelector('.download-menu');
  if (!menu) {
    return;
  }

  document.addEventListener('click', (event) => {
    const clickedOption = event.target.closest('.download-options a');
    const clickedOutside = !menu.contains(event.target);
    if (clickedOption || clickedOutside) {
      menu.open = false;
    }
  });
})();
