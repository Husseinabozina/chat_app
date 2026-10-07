(() => {
  'use strict';
  const images = [
    ['chats', 'Chats home'],
    ['conversation', 'A conversation'],
    ['profile', 'Your profile'],
    ['splash', 'Launch screen'],
    ['sign-in', 'Sign in'],
    ['sign-up', 'Sign up — email redacted'],
    ['profile-setup', 'Complete your profile'],
    ['empty-state', 'Empty conversations'],
    ['people', 'Find people']
  ];
  const modal = document.querySelector('.lightbox');
  const fullImage = modal?.querySelector('.dialog-img');
  const title = modal?.querySelector('.dialog-title');
  const counter = modal?.querySelector('.dialog-counter');
  let currentIndex = 0;
  let previousFocus;

  function render(index) {
    currentIndex = (index + images.length) % images.length;
    const [slug, label] = images[currentIndex];
    fullImage.src = `site/assets/${slug}.webp`;
    fullImage.alt = label + ' — original Mingle simulator capture';
    title.textContent = label;
    counter.textContent = `${currentIndex + 1} of ${images.length} · Actual simulator capture`;
  }
  function close() {
    modal.close();
    document.body.classList.remove('dialog-open');
    if (previousFocus?.focus) previousFocus.focus();
  }
  document.querySelectorAll('[data-image]').forEach(button => {
    button.addEventListener('click', () => {
      previousFocus = button;
      const index = images.findIndex(([slug]) => slug === button.dataset.image);
      if (index === -1 || !modal?.showModal) return;
      render(index);
      modal.showModal();
      document.body.classList.add('dialog-open');
      modal.querySelector('.dialog-close').focus();
    });
  });
  modal?.querySelector('.dialog-close')?.addEventListener('click', close);
  modal?.querySelector('.dialog-prev')?.addEventListener('click', () => render(currentIndex - 1));
  modal?.querySelector('.dialog-next')?.addEventListener('click', () => render(currentIndex + 1));
  modal?.addEventListener('keydown', event => {
    if (event.key === 'ArrowLeft') render(currentIndex - 1);
    if (event.key === 'ArrowRight') render(currentIndex + 1);
  });
  modal?.addEventListener('close', () => {
    document.body.classList.remove('dialog-open');
    if (previousFocus?.focus) previousFocus.focus();
  });
  modal?.addEventListener('click', event => {
    if (event.target === modal) close();
  });

  // Prevent overlapping audio/video playback if both clips are opened.
  const videos = [...document.querySelectorAll('video')];
  videos.forEach(video => video.addEventListener('play', () => {
    videos.forEach(other => { if (other !== video) other.pause(); });
  }));
})();
