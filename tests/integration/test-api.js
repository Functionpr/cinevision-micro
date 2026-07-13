import axios from 'axios';
import { expect } from 'chai';

const baseUrl = process.env.BASE_URL || 'http://localhost:8080';
const client = axios.create({
  baseURL: baseUrl,
  validateStatus: () => true,
  timeout: 20000
});

before(function () {
  if (!process.env.BASE_URL && process.env.CI === 'true') {
    console.log('Skipping integration API tests in CI because BASE_URL is not configured.');
    this.skip();
  }
});

describe('CineVision critical API flow', function () {
  const password = 'Password123!';
  const email = `mocha-${Date.now()}@cinevision.local`;
  let token;
  let movie;

  it('registers a new user', async function () {
    const response = await client.post('/api/user/users/add', {
      customerName: 'Mocha Test User',
      email,
      phone: '0 555 333 44 55',
      password
    });

    expect([200, 201, 204]).to.include(response.status);
  });

  it('logs in and gets a JWT', async function () {
    const response = await client.post('/api/user/auth/login', {
      email,
      password
    });

    expect(response.status).to.equal(200);
    expect(response.data).to.have.property('token');
    token = response.data.token;
  });

  it('fetches displaying movies', async function () {
    const response = await client.get('/api/movie/movies/displayingMovies');

    expect(response.status).to.equal(200);
    expect(response.data).to.be.an('array').and.not.empty;
    movie = response.data[0];
  });

  it('fetches movie details', async function () {
    const response = await client.get(`/api/movie/movies/${movie.movieId}`);

    expect(response.status).to.equal(200);
    expect(response.data.movieId).to.equal(movie.movieId);
  });

  it('submits a ticket purchase request', async function () {
    const response = await client.post('/api/movie/payments/sendTicketDetail', {
      movieName: movie.movieName,
      saloonName: 'Integration Hall',
      movieDay: '2026-04-14',
      movieStartTime: '20:30',
      email,
      fullName: 'Mocha Test User',
      phone: '0 555 333 44 55',
      chairNumbers: 'C1 C2',
      token
    });

    expect([200, 201, 202, 204]).to.include(response.status);
  });
});
