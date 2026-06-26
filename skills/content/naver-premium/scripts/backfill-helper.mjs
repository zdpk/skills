import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';

const DEFAULT_CONFIG = {
  datasetDir: path.join(os.homedir(), 'gdrive/.data/content/naver-premium'),
  channelKey: 'pangyonevergiveup__pangyobulpae',
  channelName: '세상의 모든 시장 이야기(판교불패)',
  channelUrl: 'https://contents.premium.naver.com/pangyonevergiveup/pangyobulpae',
  contentsUrl: 'https://contents.premium.naver.com/pangyonevergiveup/pangyobulpae/contents',
  expectedTotal: null,
};

function configWith(overrides = {}) {
  return { ...DEFAULT_CONFIG, ...overrides };
}

function ensureDir(filePath) {
  fs.mkdirSync(filePath, { recursive: true });
}

function atomicWriteText(filePath, text) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(`${filePath}.tmp`, text, 'utf8');
  fs.renameSync(`${filePath}.tmp`, filePath);
}

function sha256(text) {
  return crypto.createHash('sha256').update(text || '', 'utf8').digest('hex');
}

function slugTitle(title) {
  const slug = String(title || 'article')
    .normalize('NFKC')
    .replace(/[\u0000-\u001f]/g, ' ')
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 90);
  return slug || 'article';
}

function yamlScalar(value) {
  return JSON.stringify(value == null ? '' : String(value));
}

function yamlArray(values) {
  return `[${(values || []).map((value) => yamlScalar(value)).join(', ')}]`;
}

function parseKoreanDate(text, articleId) {
  const match = String(text || '').match(
    /(20\d{2})\.(\d{2})\.(\d{2})\.\s*(오전|오후)\s*(\d{1,2}):(\d{2})/,
  );
  if (!match && articleId && /^\d{6}/.test(articleId)) {
    const yy = Number(articleId.slice(0, 2));
    return `20${String(yy).padStart(2, '0')}-${articleId.slice(2, 4)}-${articleId.slice(
      4,
      6,
    )}T00:00:00+09:00`;
  }
  if (!match) return null;

  const [, year, month, day, meridiem, hourText, minute] = match;
  let hour = Number(hourText);
  if (meridiem === '오후' && hour < 12) hour += 12;
  if (meridiem === '오전' && hour === 12) hour = 0;
  return `${year}-${month}-${day}T${String(hour).padStart(2, '0')}:${minute}:00+09:00`;
}

function titleFromViewerText(viewerText, documentTitle, config) {
  const cleanDocumentTitle = String(documentTitle || '')
    .replace(/\s*:\s*네이버.*$/, '')
    .trim();
  if (
    cleanDocumentTitle &&
    cleanDocumentTitle !== config.channelName &&
    !cleanDocumentTitle.includes('전체 콘텐츠')
  ) {
    return cleanDocumentTitle;
  }

  const lines = String(viewerText || '')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
  const dateIndex = lines.findIndex((line) => /^20\d{2}\.\d{2}\.\d{2}\./.test(line));
  if (dateIndex > 0) return lines[dateIndex - 1];
  return cleanDocumentTitle || '';
}

function sanitizeHtml(html) {
  return String(html || '')
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, '');
}

function articleIdFromUrl(url) {
  const match = String(url || '').match(/\/contents\/([0-9a-zA-Z]+)/);
  return match ? match[1] : null;
}

function linksPath(config) {
  return path.join(config.datasetDir, 'tmp/naver-premium-discovered-links.json');
}

function currentBatchPath(config) {
  return path.join(config.datasetDir, 'tmp/naver-premium-current-batch.json');
}

export function readSavedIds(options = {}) {
  const config = configWith(options);
  const savedIds = new Set();
  const recordsDir = path.join(config.datasetDir, 'records');

  function walk(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const entryPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(entryPath);
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        const head = fs.readFileSync(entryPath, 'utf8').slice(0, 2000);
        const match = head.match(/\narticle_id:\s*['"]?([^'"\n]+)['"]?/);
        if (match) savedIds.add(match[1].trim());
      }
    }
  }

  walk(recordsDir);
  return savedIds;
}

export function loadDiscoveredArticles(options = {}) {
  const config = configWith(options);
  const filePath = linksPath(config);
  if (!fs.existsSync(filePath)) return [];

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const deduped = new Map();
  for (const article of data.articles || []) {
    if (article.article_id) deduped.set(article.article_id, article);
  }
  return Array.from(deduped.values()).sort((a, b) =>
    String(b.article_id).localeCompare(String(a.article_id)),
  );
}

function writeDiscoveredArticles(articles, options = {}) {
  const config = configWith(options);
  const deduped = new Map();
  for (const article of articles) {
    if (article.article_id) deduped.set(article.article_id, article);
  }
  const payload = {
    updated: new Date().toISOString(),
    expected_total: config.expectedTotal,
    count: deduped.size,
    articles: Array.from(deduped.values()),
  };
  atomicWriteText(linksPath(config), JSON.stringify(payload, null, 2));
  return payload;
}

export async function collectVisibleLinks(tab, options = {}) {
  const config = configWith(options);
  const existing = loadDiscoveredArticles(config);
  const linkMap = new Map(existing.map((article) => [article.article_id, article]));
  const visibleLinks = await tab.playwright.evaluate(
    () =>
      Array.from(document.querySelectorAll('a[href*="/contents/"]')).map((anchor) => ({
        href: anchor.href,
        text: (anchor.innerText || anchor.textContent || '').trim(),
      })),
    undefined,
    { timeoutMs: 10000 },
  );

  const added = [];
  for (const link of visibleLinks) {
    const articleId = articleIdFromUrl(link.href);
    if (!articleId) continue;

    const existingArticle = linkMap.get(articleId) || {};
    if (!linkMap.has(articleId)) added.push(articleId);
    linkMap.set(articleId, {
      article_id: articleId,
      source_url: link.href,
      title: link.text || existingArticle.title || '',
    });
  }

  const payload = writeDiscoveredArticles(Array.from(linkMap.values()), config);
  return { added, count: payload.count };
}

export async function collectLinksByScrolling(tab, options = {}) {
  const config = configWith(options);
  const {
    startUrl = config.contentsUrl,
    maxScrolls = 30,
    scrollY = 5000,
    delayMs = 500,
  } = options;

  if (startUrl) {
    await tab.goto(startUrl);
    await tab.playwright.waitForLoadState({ state: 'domcontentloaded', timeoutMs: 30000 });
  }

  const steps = [];
  for (let i = 0; i < maxScrolls; i += 1) {
    const step = await collectVisibleLinks(tab, config);
    steps.push({ i, added: step.added.length, total: step.count });
    if (config.expectedTotal && step.count >= config.expectedTotal) break;
    await tab.cua.scroll({ x: 600, y: 650, scrollY, scrollX: 0 });
    await tab.playwright.waitForTimeout(delayMs);
  }
  return { count: loadDiscoveredArticles(config).length, steps };
}

async function extractCurrentArticle(tab, articleId, sourceUrl) {
  return await tab.playwright.evaluate(
    (arg) => {
      const viewer =
        document.querySelector('#_SE_VIEWER_CONTENT') ||
        document.querySelector('.se_viewer_content');
      const main = document.querySelector('.se-main-container');
      const viewerText = viewer ? viewer.innerText : '';
      const mainText = main ? main.innerText : '';
      const pageText = document.body ? document.body.innerText : '';
      const category =
        viewerText
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean)[0] || '';
      const locked = /구독|구매|잠김|로그인/.test(pageText) && (mainText || viewerText).length < 1000;

      return {
        article_id: arg.articleId,
        source_url: location.href || arg.sourceUrl,
        category_names: category ? [category] : [],
        page_text: pageText,
        viewer_text: viewerText,
        body_text: locked ? '' : viewerText || mainText || '',
        raw_html: viewer ? viewer.innerHTML : '',
        access: locked ? 'locked' : (viewerText || mainText).length > 500 ? 'subscriber' : 'error',
        document_title: document.title,
      };
    },
    { articleId, sourceUrl },
    { timeoutMs: 15000 },
  );
}

function saveArticleRecord(article, options = {}) {
  const config = configWith(options);
  const publishedAt = parseKoreanDate(article.viewer_text || article.page_text || '', article.article_id);
  const fetchedAt = new Date().toISOString();
  const date = publishedAt ? publishedAt.slice(0, 10) : 'unknown-date';
  const year = date.slice(0, 4) || 'unknown';
  const month = date.slice(5, 7) || 'unknown';
  const title =
    titleFromViewerText(article.viewer_text, article.document_title, config) || article.article_id;
  const rawPath = `raw/${article.article_id}.html`;
  const recordPath = `records/${year}/${month}/${date}__${article.article_id}__${slugTitle(
    title,
  )}.md`;
  const body = article.access === 'locked' ? '' : article.body_text || '';
  const digest = sha256(body);
  const raw =
    `<!-- source_url: ${article.source_url}\n` +
    `article_id: ${article.article_id}\n` +
    `fetched_at: ${fetchedAt}\n` +
    `access: ${article.access} -->\n` +
    sanitizeHtml(article.raw_html || '');

  atomicWriteText(path.join(config.datasetDir, rawPath), raw);
  const markdown = [
    '---',
    'source: "naver-premium"',
    `channel_key: ${yamlScalar(config.channelKey)}`,
    `channel_name: ${yamlScalar(config.channelName)}`,
    `article_id: ${yamlScalar(article.article_id)}`,
    `title: ${yamlScalar(title)}`,
    `source_url: ${yamlScalar(article.source_url)}`,
    'category_ids: []',
    `category_names: ${yamlArray(article.category_names || [])}`,
    `published_at: ${yamlScalar(publishedAt || '')}`,
    `fetched_at: ${yamlScalar(fetchedAt)}`,
    `access: ${yamlScalar(article.access)}`,
    `content_sha256: ${yamlScalar(digest)}`,
    `raw_path: ${yamlScalar(rawPath)}`,
    '---',
    '',
    `# ${title}`,
    '',
    body,
  ].join('\n');
  atomicWriteText(path.join(config.datasetDir, recordPath), markdown);

  return {
    article_id: article.article_id,
    title,
    access: article.access,
    published_at: publishedAt,
    record_path: recordPath,
    raw_path: rawPath,
    text_len: body.length,
  };
}

export async function processNextArticles(tab, options = {}) {
  const config = configWith(options);
  const batchSize = options.batchSize ?? 10;
  const discoveredArticles = loadDiscoveredArticles(config);
  const savedIds = readSavedIds(config);
  const targets = discoveredArticles
    .filter((article) => !savedIds.has(article.article_id))
    .slice(0, batchSize);
  const results = [];
  const errors = [];

  for (const target of targets) {
    try {
      await tab.goto(target.source_url);
      await tab.playwright.waitForLoadState({ state: 'domcontentloaded', timeoutMs: 30000 });
      const extracted = await extractCurrentArticle(tab, target.article_id, target.source_url);
      results.push(saveArticleRecord(extracted, config));
    } catch (error) {
      errors.push({
        article_id: target.article_id,
        source_url: target.source_url,
        error: String(error && error.message ? error.message : error),
      });
    }

    atomicWriteText(
      currentBatchPath(config),
      JSON.stringify(
        { updated: new Date().toISOString(), batch_results: results, batch_errors: errors },
        null,
        2,
      ),
    );
  }

  return {
    attempted: targets.length,
    saved: results.length,
    errors,
    results,
    remaining_after: discoveredArticles.length - readSavedIds(config).size,
  };
}

function parseFrontmatter(markdown) {
  if (!markdown.startsWith('---\n')) throw new Error('missing frontmatter');
  const end = markdown.indexOf('\n---\n', 4);
  if (end < 0) throw new Error('unterminated frontmatter');
  const frontmatter = markdown.slice(4, end);
  const body = markdown.slice(end + '\n---\n'.length);
  const meta = {};

  for (const line of frontmatter.split('\n')) {
    const match = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!match) continue;
    const [, key, rawValue] = match;
    const value = rawValue.trim();
    if (value.startsWith('[')) {
      try {
        meta[key] = JSON.parse(value);
      } catch {
        meta[key] = [];
      }
    } else if (value.startsWith('"') || value.startsWith("'")) {
      try {
        meta[key] = JSON.parse(value);
      } catch {
        meta[key] = value.replace(/^['"]|['"]$/g, '');
      }
    } else if (value === '') {
      meta[key] = null;
    } else {
      meta[key] = value;
    }
  }
  return { meta, body };
}

function listMarkdownRecords(dir) {
  const records = [];
  function walk(current) {
    if (!fs.existsSync(current)) return;
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) walk(entryPath);
      if (entry.isFile() && entry.name.endsWith('.md')) records.push(entryPath);
    }
  }
  walk(dir);
  return records;
}

export function rebuildIndexes(options = {}) {
  const config = configWith(options);
  const now = new Date().toISOString();
  const articles = [];
  const errors = [];
  const seen = new Map();
  const recordsDir = path.join(config.datasetDir, 'records');

  for (const filePath of listMarkdownRecords(recordsDir).sort()) {
    const recordPath = path.relative(config.datasetDir, filePath).split(path.sep).join('/');
    try {
      const { meta, body } = parseFrontmatter(fs.readFileSync(filePath, 'utf8'));
      const articleId = String(meta.article_id || '').trim();
      if (!articleId) throw new Error('missing article_id');
      if (seen.has(articleId)) throw new Error(`duplicate article_id already seen in ${seen.get(articleId)}`);
      seen.set(articleId, recordPath);
      articles.push({
        source: meta.source || 'naver-premium',
        channel_key: meta.channel_key,
        channel_name: meta.channel_name,
        article_id: articleId,
        title: meta.title,
        source_url: meta.source_url,
        category_ids: meta.category_ids || [],
        category_names: meta.category_names || [],
        published_at: meta.published_at,
        fetched_at: meta.fetched_at,
        access: meta.access,
        content_sha256: meta.content_sha256 || sha256(body),
        raw_path: meta.raw_path || `raw/${articleId}.html`,
        record_path: recordPath,
        text_len: body.trim().length,
      });
    } catch (error) {
      errors.push({ record_path: recordPath, error: String(error && error.message ? error.message : error) });
    }
  }

  articles.sort((a, b) => {
    const keyA = `${a.published_at || ''}:${a.article_id || ''}`;
    const keyB = `${b.published_at || ''}:${b.article_id || ''}`;
    return keyB.localeCompare(keyA);
  });

  const byDate = {};
  const categories = {};
  const channels = {};
  for (const article of articles) {
    const date = String(article.published_at || '').slice(0, 10) || 'unknown';
    byDate[date] ||= [];
    byDate[date].push(article.article_id);

    for (const name of article.category_names.length ? article.category_names : ['uncategorized']) {
      categories[String(name)] ||= [];
      categories[String(name)].push(article.article_id);
    }

    const channelKey = article.channel_key || config.channelKey;
    channels[channelKey] ||= {
      channel_key: channelKey,
      channel_name: article.channel_name || config.channelName,
      channel_url: config.channelUrl,
      latest_published_at: article.published_at,
      article_count: 0,
    };
    channels[channelKey].article_count += 1;
    if (String(article.published_at || '') > String(channels[channelKey].latest_published_at || '')) {
      channels[channelKey].latest_published_at = article.published_at;
    }
  }

  const latest = articles[0] || null;
  const common = { version: 1, updated: now };
  atomicWriteText(
    path.join(config.datasetDir, 'index/articles.yaml'),
    toYaml({ ...common, articles, errors }),
  );
  atomicWriteText(
    path.join(config.datasetDir, 'index/channels.yaml'),
    toYaml({ ...common, channels: Object.values(channels) }),
  );
  atomicWriteText(
    path.join(config.datasetDir, 'index/categories.yaml'),
    toYaml({
      ...common,
      categories: Object.entries(categories)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([name, article_ids]) => ({ name, article_ids })),
    }),
  );
  atomicWriteText(path.join(config.datasetDir, 'index/by_date.yaml'), toYaml({ ...common, dates: byDate }));
  atomicWriteText(path.join(config.datasetDir, 'index/latest.yaml'), toYaml({ ...common, latest }));

  const rawCount = fs.existsSync(path.join(config.datasetDir, 'raw'))
    ? fs.readdirSync(path.join(config.datasetDir, 'raw')).filter((name) => name.endsWith('.html')).length
    : 0;
  atomicWriteText(
    path.join(config.datasetDir, 'state.yaml'),
    toYaml({
      version: 1,
      dataset_id: 'content/naver-premium',
      updated: now,
      latest_record_at: latest ? latest.published_at : null,
      latest_record_id: latest ? latest.article_id : null,
      cursor: latest ? { published_at: latest.published_at, article_id: latest.article_id } : null,
      stats: { records: articles.length, raw: rawCount, index_errors: errors.length },
    }),
  );

  return { articles: articles.length, raw: rawCount, errors: errors.length, latest };
}

function toYaml(value, indent = 0) {
  void indent;
  return `${JSON.stringify(value, null, 2)}\n`;
}

export function getProgress(options = {}) {
  const config = configWith(options);
  const discovered = loadDiscoveredArticles(config).length;
  const saved = readSavedIds(config).size;
  return { discovered, saved, remaining: discovered - saved };
}

function isCliRun() {
  return (
    typeof process !== 'undefined' &&
    process.argv &&
    process.argv[1] &&
    import.meta.url === new URL(`file://${process.argv[1]}`).href
  );
}

if (isCliRun()) {
  const command = process.argv[2] || 'progress';
  if (command === 'progress') {
    console.log(JSON.stringify(getProgress(), null, 2));
  } else if (command === 'rebuild-indexes') {
    console.log(JSON.stringify(rebuildIndexes(), null, 2));
  } else {
    console.error(`Unknown command: ${command}`);
    console.error('Usage: node scripts/backfill-helper.mjs [progress|rebuild-indexes]');
    process.exitCode = 2;
  }
}
