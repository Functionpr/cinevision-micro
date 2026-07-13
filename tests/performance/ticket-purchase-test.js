import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '2m',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500']
  }
};

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  const email = `k6-${__VU}-${__ITER}-${Date.now()}@cinevision.local`;
  const password = 'Password123!';

  const registerResponse = http.post(`${baseUrl}/api/user/users/add`, JSON.stringify({
    customerName: 'k6 Test User',
    email,
    phone: '0 555 999 88 77',
    password
  }), {
    headers: { 'Content-Type': 'application/json' }
  });

  check(registerResponse, {
    'register succeeded': (res) => [200, 201, 204].includes(res.status)
  });

  const loginResponse = http.post(`${baseUrl}/api/user/auth/login`, JSON.stringify({
    email,
    password
  }), {
    headers: { 'Content-Type': 'application/json' }
  });

  check(loginResponse, {
    'login succeeded': (res) => res.status === 200,
    'login returned token': (res) => !!res.json('token')
  });

  const moviesResponse = http.get(`${baseUrl}/api/movie/movies/displayingMovies`);
  check(moviesResponse, {
    'movies fetched': (res) => res.status === 200
  });

  const movies = moviesResponse.json();
  const movie = Array.isArray(movies) && movies.length > 0 ? movies[0] : null;

  if (movie) {
    const purchaseResponse = http.post(`${baseUrl}/api/movie/payments/sendTicketDetail`, JSON.stringify({
      movieName: movie.movieName,
      saloonName: 'Performance Hall',
      movieDay: '2026-04-14',
      movieStartTime: '20:30',
      email,
      fullName: 'k6 Test User',
      phone: '0 555 999 88 77',
      chairNumbers: 'D1 D2'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });

    check(purchaseResponse, {
      'purchase request accepted': (res) => [200, 201, 202, 204].includes(res.status)
    });
  }

  sleep(1);
}
