import http from 'k6/http';
import { check } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

const baseUrl = __ENV.BASE_URL || 'http://api-gateway:8080';

const displayingDuration = new Trend('displaying_movies_duration', true);
const displayingErrors = new Rate('displaying_movies_errors');
const displayingRequests = new Counter('displaying_movies_requests');

const loginDuration = new Trend('login_duration', true);
const loginErrors = new Rate('login_errors');
const loginRequests = new Counter('login_requests');

const paymentDuration = new Trend('payment_duration', true);
const paymentErrors = new Rate('payment_errors');
const paymentRequests = new Counter('payment_requests');

export const options = {
  vus: 50,
  duration: '2m',
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(95)', 'p(99)'],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    displaying_movies_errors: ['rate<0.05'],
    login_errors: ['rate<0.05'],
    payment_errors: ['rate<0.05'],
  },
};

export function setup() {
  const response = http.get(`${baseUrl}/api/movie/movies/displayingMovies`);
  const ok = check(response, {
    'setup: displaying movies returned 200': (res) => res.status === 200,
  });

  if (!ok) {
    throw new Error(`Setup failed while fetching displaying movies. Status: ${response.status}`);
  }

  const movies = response.json();

  if (!Array.isArray(movies) || movies.length === 0) {
    throw new Error('Setup failed because no displaying movies were returned.');
  }

  return {
    movie: movies[0],
  };
}

function randomEmail(prefix) {
  return `${prefix}-${__VU}-${__ITER}-${Date.now()}@cinevision.local`;
}

function recordMetric(durationMetric, errorMetric, requestMetric, response, description) {
  const passed = check(response, {
    [description]: (res) => res.status >= 200 && res.status < 300,
  });

  durationMetric.add(response.timings.duration);
  requestMetric.add(1);
  errorMetric.add(!passed);
}

export default function (data) {
  const roll = Math.random();

  if (roll < 0.6) {
    const response = http.get(`${baseUrl}/api/movie/movies/displayingMovies`, {
      tags: { endpoint: 'displayingMovies' },
    });
    recordMetric(displayingDuration, displayingErrors, displayingRequests, response, 'displaying movies status is 2xx');
    return;
  }

  if (roll < 0.9) {
    const response = http.post(
      `${baseUrl}/api/user/auth/login`,
      JSON.stringify({
        email: 'demo@cinevision.local',
        password: 'Demo123!',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { endpoint: 'login' },
      },
    );
    recordMetric(loginDuration, loginErrors, loginRequests, response, 'login status is 2xx');
    return;
  }

  const response = http.post(
    `${baseUrl}/api/movie/payments/sendTicketDetail`,
    JSON.stringify({
      movieName: data.movie.movieName,
      saloonName: 'Performance Hall',
      movieDay: '2026-04-07',
      movieStartTime: '20:30',
      email: randomEmail('load'),
      fullName: 'Load Test User',
      phone: '0 555 111 22 33',
      chairNumbers: 'B1 B2',
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { endpoint: 'sendTicketDetail' },
    },
  );
  recordMetric(paymentDuration, paymentErrors, paymentRequests, response, 'payment status is 2xx');
}

export function handleSummary(data) {
  const summaryPath = __ENV.K6_SUMMARY_PATH || '/reports/performance/k6-summary.json';

  return {
    [summaryPath]: JSON.stringify(data, null, 2),
    stdout: 'k6 load test completed.\n',
  };
}
