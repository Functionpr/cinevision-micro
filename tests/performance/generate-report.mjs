import fs from 'node:fs/promises';
import path from 'node:path';

const reportDir = process.env.REPORT_DIR || '/reports/performance';
const summaryPath = process.env.K6_SUMMARY_PATH || path.join(reportDir, 'k6-summary.json');
const reportPath = path.join(reportDir, 'performance-report.md');
const testDurationSeconds = Number(process.env.TEST_DURATION_SECONDS || 120);

function getMetric(summary, name) {
  return summary.metrics?.[name] || null;
}

function value(metric, key, fallback = 'n/a') {
  if (!metric?.values) {
    return fallback;
  }

  const metricValue = metric.values[key];
  return typeof metricValue === 'number' ? metricValue : fallback;
}

function formatNumber(input, digits = 2) {
  return typeof input === 'number' ? input.toFixed(digits) : 'n/a';
}

function throughput(counterMetric) {
  const count = value(counterMetric, 'count', null);
  if (typeof count !== 'number') {
    return 'n/a';
  }

  return `${formatNumber(count / testDurationSeconds, 2)} req/s`;
}

function percentage(rateMetric) {
  const rate = value(rateMetric, 'rate', null);
  return typeof rate === 'number' ? `${formatNumber(rate * 100, 2)}%` : 'n/a';
}

function recommendation(label, p95, errorRate) {
  if (typeof errorRate === 'number' && errorRate > 0.01) {
    return `${label}: investigate transient failures, container readiness timing, and downstream timeouts before raising load further.`;
  }

  if (typeof p95 === 'number' && p95 > 800) {
    return `${label}: p95 latency is high. Focus on JVM sizing, connection pooling, and reducing synchronous work on the request path.`;
  }

  if (typeof p95 === 'number' && p95 > 400) {
    return `${label}: latency is acceptable for local load testing but can improve with caching, smaller payloads, and faster downstream responses.`;
  }

  return `${label}: current latency is healthy for a local Docker stack. Keep watching tail latency as features and data volume grow.`;
}

async function main() {
  await fs.mkdir(reportDir, { recursive: true });

  const summary = JSON.parse(await fs.readFile(summaryPath, 'utf8'));

  const displayingDuration = getMetric(summary, 'displaying_movies_duration');
  const displayingErrors = getMetric(summary, 'displaying_movies_errors');
  const displayingRequests = getMetric(summary, 'displaying_movies_requests');

  const loginDuration = getMetric(summary, 'login_duration');
  const loginErrors = getMetric(summary, 'login_errors');
  const loginRequests = getMetric(summary, 'login_requests');

  const paymentDuration = getMetric(summary, 'payment_duration');
  const paymentErrors = getMetric(summary, 'payment_errors');
  const paymentRequests = getMetric(summary, 'payment_requests');

  const httpReqs = getMetric(summary, 'http_reqs');
  const httpFailed = getMetric(summary, 'http_req_failed');

  const lines = [
    '# CineVision Performance Report',
    '',
    `- Base URL: ${process.env.BASE_URL || 'http://api-gateway:8080'}`,
    `- Generated At: ${new Date().toISOString()}`,
    `- Load Profile: 50 virtual users for 2 minutes`,
    '',
    '## Overall Summary',
    '',
    `- Total HTTP throughput: ${formatNumber(value(httpReqs, 'rate', null), 2)} req/s`,
    `- Overall error rate: ${percentage(httpFailed)}`,
    '',
    '## Endpoint Metrics',
    '',
    '| Endpoint | p95 (ms) | p99 (ms) | Error Rate | Throughput |',
    '| --- | ---: | ---: | ---: | ---: |',
    `| GET /api/movie/movies/displayingMovies | ${formatNumber(value(displayingDuration, 'p(95)', null))} | ${formatNumber(value(displayingDuration, 'p(99)', null))} | ${percentage(displayingErrors)} | ${throughput(displayingRequests)} |`,
    `| POST /api/user/auth/login | ${formatNumber(value(loginDuration, 'p(95)', null))} | ${formatNumber(value(loginDuration, 'p(99)', null))} | ${percentage(loginErrors)} | ${throughput(loginRequests)} |`,
    `| POST /api/movie/payments/sendTicketDetail | ${formatNumber(value(paymentDuration, 'p(95)', null))} | ${formatNumber(value(paymentDuration, 'p(99)', null))} | ${percentage(paymentErrors)} | ${throughput(paymentRequests)} |`,
    '',
    '## Recommendations',
    '',
    `- ${recommendation('Displaying movies', value(displayingDuration, 'p(95)', null), value(displayingErrors, 'rate', null))}`,
    `- ${recommendation('Login', value(loginDuration, 'p(95)', null), value(loginErrors, 'rate', null))}`,
    `- ${recommendation('Ticket payment event publishing', value(paymentDuration, 'p(95)', null), value(paymentErrors, 'rate', null))}`,
    '- For more realistic production confidence, repeat the test with warm caches, larger datasets, and a remote SMTP sink disabled so MailHog does not absorb extra local resources.',
    '',
  ];

  await fs.writeFile(reportPath, `${lines.join('\n')}\n`, 'utf8');
}

await main();
