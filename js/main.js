/* ============================================================
   IronClad Docs — Main JavaScript
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {
  initTabs();
  initCopyButtons();
  initSidebarNav();
  initMobileMenu();
  detectOS();
});

/* ---------- Tab switching ---------- */
function initTabs() {
  document.querySelectorAll('.tabs').forEach(tabGroup => {
    const buttons = tabGroup.querySelectorAll('.tab-btn');
    const panels  = tabGroup.querySelectorAll('.tab-panel');

    buttons.forEach(btn => {
      btn.addEventListener('click', () => {
        const target = btn.dataset.tab;
        buttons.forEach(b => b.classList.remove('active'));
        panels.forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        tabGroup.querySelector(`[data-panel="${target}"]`)?.classList.add('active');
      });
    });
  });
}

/* ---------- Copy to clipboard ---------- */
function initCopyButtons() {
  document.querySelectorAll('.copy-code-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const codeBlock = btn.closest('.code-block');
      const code = codeBlock?.querySelector('pre')?.textContent || '';
      navigator.clipboard.writeText(code.trim()).then(() => {
        const original = btn.innerHTML;
        btn.innerHTML = '✓ Copied';
        btn.classList.add('copied');
        setTimeout(() => {
          btn.innerHTML = original;
          btn.classList.remove('copied');
        }, 2000);
      });
    });
  });

  // Hero copy button
  document.querySelectorAll('.hero-install .copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const code = btn.closest('.hero-install')?.querySelector('.cmd')?.textContent || '';
      navigator.clipboard.writeText(code.trim()).then(() => {
        btn.textContent = '✓';
        setTimeout(() => { btn.textContent = '📋'; }, 1500);
      });
    });
  });
}

/* ---------- Sidebar scroll spy ---------- */
function initSidebarNav() {
  const links = document.querySelectorAll('.sidebar-section a[href^="#"]');
  const sections = [];

  links.forEach(link => {
    const id = link.getAttribute('href').slice(1);
    const el = document.getElementById(id);
    if (el) sections.push({ el, link });
  });

  if (!sections.length) return;

  const observer = new IntersectionObserver(
    entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          links.forEach(l => l.classList.remove('active'));
          const match = sections.find(s => s.el === entry.target);
          if (match) match.link.classList.add('active');
        }
      });
    },
    { rootMargin: '-80px 0px -60% 0px', threshold: 0 }
  );

  sections.forEach(s => observer.observe(s.el));
}

/* ---------- Mobile sidebar menu ---------- */
function initMobileMenu() {
  const toggle  = document.querySelector('.mobile-toggle');
  const sidebar = document.querySelector('.sidebar');
  const overlay = document.querySelector('.sidebar-overlay');

  if (!toggle || !sidebar) return;

  function openSidebar() {
    sidebar.classList.add('open');
    overlay?.classList.add('active');
  }
  function closeSidebar() {
    sidebar.classList.remove('open');
    overlay?.classList.remove('active');
  }

  toggle.addEventListener('click', () => {
    sidebar.classList.contains('open') ? closeSidebar() : openSidebar();
  });
  overlay?.addEventListener('click', closeSidebar);

  // Close sidebar on nav click (mobile)
  sidebar.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => {
      if (window.innerWidth <= 1024) closeSidebar();
    });
  });
}

/* ---------- OS auto-detection ---------- */
function detectOS() {
  const ua = navigator.userAgent.toLowerCase();
  let os = 'linux';

  if (ua.includes('win'))        os = 'windows';
  else if (ua.includes('mac'))   os = 'macos';

  // Activate the matching tab in the quick-install section
  const quickTabs = document.querySelector('#quick-install .tabs');
  if (!quickTabs) return;

  const tabMap = {
    linux:   'linux',
    macos:   'linux',   // macOS uses the same bash script
    windows: 'windows'
  };

  const target = tabMap[os] || 'linux';
  const btn = quickTabs.querySelector(`.tab-btn[data-tab="${target}"]`);
  if (btn) btn.click();
}
