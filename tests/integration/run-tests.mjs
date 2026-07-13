import fs from 'node:fs/promises';
import path from 'node:path';

const baseUrl = process.env.BASE_URL || 'http://api-gateway:8080';
const mailhogUrl = process.env.MAILHOG_URL || 'http://mailhog:8025';
const reportDir = process.env.REPORT_DIR || '/reports/integration';
const reportPath = path.join(reportDir, 'integration-report.md');

const results = [];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function ensureReportDir() {
  await fs.mkdir(reportDir, { recursive: true });
}

async function requestJson(url, { method = 'GET', body, headers = {}, timeoutMs = 20000 } = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, {
      method,
      headers: {
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...headers,
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });

    const text = await response.text();
    let data = null;

    if (text) {
      try {
        data = JSON.parse(text);
      } catch {
        data = text;
      }
    }

    return { response, data };
  } finally {
    clearTimeout(timeout);
  }
}

async function withRetries(label, fn, attempts = 8, delayMs = 5000) {
  let lastError;

  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < attempts) {
        await sleep(delayMs);
      }
    }
  }

  throw new Error(`${label} failed after ${attempts} attempts: ${lastError?.message || 'unknown error'}`);
}

async function runStep(name, fn) {
  const startedAt = Date.now();

  try {
    const detail = await fn();
    results.push({
      name,
      status: 'PASS',
      durationMs: Date.now() - startedAt,
      detail,
    });
    return detail;
  } catch (error) {
    results.push({
      name,
      status: 'FAIL',
      durationMs: Date.now() - startedAt,
      detail: error.message,
    });
    throw error;
  }
}

async function waitForEmail(recipient, subjectContains, movieName) {
  const timeoutAt = Date.now() + 45000;

  while (Date.now() < timeoutAt) {
    const { response, data } = await requestJson(`${mailhogUrl}/api/v2/messages`);
    if (response.ok && Array.isArray(data?.items)) {
      const match = data.items.find((item) => {
        const headers = item?.Content?.Headers || {};
        const toValues = headers.To || [];
        const subjectValues = headers.Subject || [];
        const body = item?.Content?.Body || '';

        return toValues.some((value) => value.includes(recipient))
          && subjectValues.some((value) => value.includes(subjectContains))
          && body.includes(movieName);
      });

      if (match) {
        return {
          subject: match.Content.Headers.Subject?.[0] || '',
          to: match.Content.Headers.To?.[0] || recipient,
        };
      }
    }

    await sleep(3000);
  }

  throw new Error(`No email for ${recipient} reached MailHog within 45 seconds.`);
}

async function writeReport(context = {}) {
  await ensureReportDir();

  const lines = [
    '# CineVision Integration Test Report',
    '',
    `- Base URL: ${baseUrl}`,
    `- MailHog URL: ${mailhogUrl}`,
    `- Generated At: ${new Date().toISOString()}`,
  ];

  if (context.userEmail) {
    lines.push(`- Test User: ${context.userEmail}`);
  }

  if (context.movieName) {
    lines.push(`- Displaying Movie Used: ${context.movieName}`);
  }

  lines.push('', '## Results', '');

  for (const result of results) {
    lines.push(`### ${result.status} - ${result.name}`);
    lines.push(`- Duration: ${result.durationMs} ms`);
    lines.push(`- Detail: ${typeof result.detail === 'string' ? result.detail : JSON.stringify(result.detail)}`);
    lines.push('');
  }

  const hasFailure = results.some((result) => result.status === 'FAIL');
  lines.push('## Summary', '');
  lines.push(hasFailure
    ? '- One or more critical flows failed. Check the failed step details above.'
    : '- All critical user flows completed successfully through the API gateway and MailHog.');
  lines.push('- Covered flows: register, login, JWT issuance, displaying movies, movie details, ticket purchase, email verification.');
  lines.push('');

  await fs.writeFile(reportPath, `${lines.join('\n')}\n`, 'utf8');
}

async function main() {
  const runId = Date.now();
  const userEmail = `integration-${runId}@cinevision.local`;
  const password = 'Password123!';
  const context = { userEmail };

  try {
    await runStep('Register a new user', async () => {
      const { response } = await withRetries('register user', async () => {
        const result = await requestJson(`${baseUrl}/api/user/users/add`, {
          method: 'POST',
          body: {
            customerName: 'Integration Test User',
            email: userEmail,
            phone: '0 555 123 45 67',
            password,
          },
        });

        if (![200, 201, 204].includes(result.response.status)) {
          throw new Error(`Expected 200/201/204, received ${result.response.status}.`);
        }

        return result;
      });

      return `HTTP ${response.status}`;
    });

    const loginResult = await runStep('Login and obtain a JWT', async () => {
      const { response, data } = await withRetries('login', async () => {
        const result = await requestJson(`${baseUrl}/api/user/auth/login`, {
          method: 'POST',
          body: {
            email: userEmail,
            password,
          },
        });

        if (result.response.status !== 200) {
          throw new Error(`Expected 200, received ${result.response.status}.`);
        }

        if (!result.data?.token) {
          throw new Error('JWT token was not returned.');
        }

        return result;
      });

      return {
        userId: data.userId,
        roles: data.roles,
        tokenPreview: `${data.token.slice(0, 24)}...`,
      };
    });

    const movies = await runStep('Fetch displaying movies', async () => {
      const { response, data } = await withRetries('fetch displaying movies', async () => {
        const result = await requestJson(`${baseUrl}/api/movie/movies/displayingMovies`);

        if (result.response.status !== 200) {
          throw new Error(`Expected 200, received ${result.response.status}.`);
        }

        if (!Array.isArray(result.data) || result.data.length === 0) {
          throw new Error('No displaying movies were returned.');
        }

        return result;
      });

      return {
        count: data.length,
        firstMovie: data[0].movieName,
        items: data,
      };
    });

    const firstMovie = movies.items[0];
    context.movieName = firstMovie.movieName;

    const detail = await runStep('Fetch movie details', async () => {
      const { response, data } = await withRetries('fetch movie details', async () => {
        const result = await requestJson(`${baseUrl}/api/movie/movies/${firstMovie.movieId}`);

        if (result.response.status !== 200) {
          throw new Error(`Expected 200, received ${result.response.status}.`);
        }

        if (!result.data?.movieId || result.data.movieId !== firstMovie.movieId) {
          throw new Error('Movie details did not match the selected displaying movie.');
        }

        return result;
      });

      return {
        movieId: data.movieId,
        movieName: data.movieName,
        categoryName: data.categoryName,
      };
    });

    await runStep('Purchase a ticket and publish the Kafka email event', async () => {
      const { response } = await withRetries('send ticket detail', async () => {
        const result = await requestJson(`${baseUrl}/api/movie/payments/sendTicketDetail`, {
          method: 'POST',
          body: {
            movieName: detail.movieName,
            saloonName: 'CineVision Central Hall',
            movieDay: new Date().toISOString().slice(0, 10),
            movieStartTime: '20:30',
            email: userEmail,
            fullName: 'Integration Test User',
            phone: '0 555 123 45 67',
            chairNumbers: 'A1 A2',
          },
        });

        if (![200, 201, 202, 204].includes(result.response.status)) {
          throw new Error(`Expected 200/201/202/204, received ${result.response.status}.`);
        }

        return result;
      });

      return `HTTP ${response.status}`;
    });

    await runStep('Verify the email reached MailHog', async () => {
      const emailResult = await waitForEmail(userEmail, 'Your CineVision ticket details', detail.movieName);
      return emailResult;
    });

    await writeReport({ ...context, loginUserId: loginResult.userId });
  } catch (error) {
    await writeReport(context);
    console.error(error.message);
    process.exitCode = 1;
  }
}

await main();
