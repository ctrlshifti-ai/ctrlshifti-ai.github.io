(() => {
  const root = document.documentElement;

  function savedTheme() {
    try {
      return localStorage.getItem('theme');
    } catch (e) {
      return null;
    }
  }

  function saveTheme(theme) {
    try {
      localStorage.setItem('theme', theme);
    } catch (e) {}
  }

  function updateButton(button) {
    button.setAttribute('aria-pressed', root.dataset.theme === 'dark');
  }

  function toggleTheme(button) {
    const next = root.dataset.theme === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next;
    saveTheme(next);
    updateButton(button);
  }

  root.dataset.theme = savedTheme() ?? 'dark';

  document.addEventListener('DOMContentLoaded', () => {
    const button = document.querySelector('.theme-toggle');
    updateButton(button);
    button.addEventListener('click', () => toggleTheme(button));
  });
})();
