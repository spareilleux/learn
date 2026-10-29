/** Identify published Streeling department indexes and course leaves, independently of labels. */
export function streelingLinkIdentity(href, { baseUrl, pageUrl }) {
  if (!href) return null;
  let url;
  try {
    url = new URL(href, pageUrl);
  } catch {
    return null;
  }
  if (url.origin !== new URL(pageUrl).origin) return null;
  const base = new URL(baseUrl, pageUrl).pathname.replace(/\/$/, '');
  if (base && !url.pathname.startsWith(`${base}/`)) return null;
  const segments = url.pathname.slice(base.length).split('/').filter(Boolean);
  if (['en', 'fr', 'es'].includes(segments[0])) segments.shift();
  if (segments[0] !== 'streeling' || segments.length < 2 || segments.length > 3) return null;
  const [, department, course = null] = segments;
  if (course && !/^[a-z]+-\d{3}(?:-|$)/i.test(course)) return null;
  const excluded = ['index', 'overview', 'journal'];
  if (excluded.includes(department) || (course && excluded.includes(course))) return null;
  return { department, course };
}

/** Deduplicate repeated anchors (including locale variants) within one published navigation tree. */
export function countDepartmentCourses(hrefs, options) {
  const inventory = new Map();
  for (const href of hrefs) {
    const identity = streelingLinkIdentity(href, options);
    if (!identity) continue;
    if (!inventory.has(identity.department)) inventory.set(identity.department, new Set());
    if (identity.course) inventory.get(identity.department).add(identity.course);
  }
  return new Map([...inventory].map(([department, courses]) => [department, courses.size]));
}

function countLabel(count, lang) {
  if (lang.startsWith('fr')) return `${count} cours publié${count === 1 ? '' : 's'}`;
  if (lang.startsWith('es')) return `${count} curso${count === 1 ? '' : 's'} publicado${count === 1 ? '' : 's'}`;
  return `${count} published course${count === 1 ? '' : 's'}`;
}

export function updateStreelingNavCounts(root = document) {
  for (const navigation of root.querySelectorAll('[data-streeling-nav]')) {
    const document = navigation.ownerDocument;
    const options = { baseUrl: navigation.dataset.streelingBase || '/', pageUrl: document.baseURI };
    const counts = countDepartmentCourses(
      [...navigation.querySelectorAll('a[href]')].map((link) => link.getAttribute('href')),
      options,
    );
    for (const group of navigation.querySelectorAll('details')) {
      const departments = new Set(
        [...group.querySelectorAll('a[href]')]
          .filter((link) => link.closest('details') === group)
          .map((link) => streelingLinkIdentity(link.getAttribute('href'), options)?.department)
          .filter(Boolean),
      );
      if (departments.size !== 1) continue;
      const department = [...departments][0];
      const summary = group.querySelector(':scope > summary');
      const label = summary?.querySelector('.group-label');
      if (!label) continue;
      let badge = label.querySelector('[data-streeling-count]');
      if (!badge) {
        badge = document.createElement('span');
        badge.setAttribute('data-streeling-count', '');
        label.append(badge);
      }
      const count = counts.get(department) ?? 0;
      badge.textContent = `(${count})`;
      badge.setAttribute('aria-label', countLabel(count, document.documentElement.lang));
    }
  }
}

if (typeof document !== 'undefined') {
  updateStreelingNavCounts();
  document.addEventListener('astro:page-load', () => updateStreelingNavCounts());
}
