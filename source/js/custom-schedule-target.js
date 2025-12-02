document.addEventListener('DOMContentLoaded', function () {
  try {
    // Find navbar links that point to /schedule/
    var links = document.querySelectorAll('a.nav-link[href="/schedule/"]');
    if (!links || links.length === 0) return;
    links.forEach(function (a) {
      a.setAttribute('target', '_blank');
      a.setAttribute('rel', 'noopener noreferrer');
    });
  } catch (e) {
    // silent
    console.error('custom-schedule-target failed', e);
  }
});
