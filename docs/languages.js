// Language links work without JavaScript. Preserve an equivalent section when available.
for (const link of document.querySelectorAll('.language-link')) {
  link.addEventListener('click', () => {
    if (location.hash) {
      const target = new URL(link.href);
      target.hash = location.hash;
      link.href = target.href;
    }
  });
}
