(() => {
  'use strict';
  const controls = [...document.querySelectorAll('[data-preview]')];
  const panels = [...document.querySelectorAll('[data-pane]')];
  if (controls.length !== 3 || panels.length !== 3) return;

  function select(screen, focus = false) {
    const selected = controls.find(button => button.dataset.preview === screen);
    if (!selected) return;
    controls.forEach(button => {
      const active = button === selected;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    panels.forEach(panel => {
      const active = panel.dataset.pane === screen;
      panel.hidden = !active;
      panel.classList.toggle('active', active);
    });
    if (focus) selected.focus();
  }

  controls.forEach((button, index) => {
    button.addEventListener('click', () => select(button.dataset.preview));
    button.addEventListener('keydown', event => {
      if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
      event.preventDefault();
      const offset = event.key === 'ArrowDown' ? 1 : -1;
      const next = (index + offset + controls.length) % controls.length;
      select(controls[next].dataset.preview, true);
    });
  });
  select('chats');
})();
