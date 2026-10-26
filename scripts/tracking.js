// Sends Google Analytics (GA4) events for the actions we care about:
// resume printed/saved as PDF, email/phone clicked, LinkedIn and other links opened.
(() => {
  function track(eventName, details) {
    if (typeof gtag === 'function') {
      gtag('event', eventName, details || {});
    }
  }

  // Work out an event name from what kind of link was clicked.
  function eventForLink(link) {
    const href = link.getAttribute('href') || '';

    if (href.startsWith('mailto:')) {
      return 'email_click';
    }
    if (href.startsWith('tel:')) {
      return 'phone_click';
    }
    if (href.includes('linkedin.com')) {
      return 'linkedin_click';
    }
    if (link.hostname && link.hostname !== location.hostname) {
      return 'outbound_click';
    }
    return null;
  }

  document.addEventListener('click', (event) => {
    const link = event.target.closest('a');
    if (!link) {
      return;
    }
    const eventName = eventForLink(link);
    if (eventName) {
      track(eventName, { link_url: link.href });
    }
  });

  // Fires once when the footer scrolls into view, i.e. the visitor reached the end of the page.
  const footer = document.querySelector('footer');
  if (footer && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        track('read_to_end');
        observer.disconnect();
      }
    });
    observer.observe(footer);
  }

  // Fires for the "Print / Save as PDF" button and for Ctrl+P / browser menu printing.
  window.addEventListener('beforeprint', () => {
    track('resume_download');
  });
})();
