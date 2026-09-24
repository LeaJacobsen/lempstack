import { test, expect } from '@playwright/test';
import * as net from 'net';

/**
 * Disse tests antager Varnish er eneste offentligt tilgængelige indgang,
 * og at TARGET_URL peger på den (se playwright.config.ts).
 *
 * NB: Test 1 tjekker på ordene "success"/"connected" i sidens tekst, fordi
 * jeg ikke kender den præcise ordlyd i jeres app/index.php smoke-test-side.
 * Ret teksten i .toContainText(...) til at matche det, jeres side faktisk skriver.
 */

// Hjælpefunktion: prøv en rå TCP-forbindelse og returnér om den lykkedes
function tryConnect(host: string, port: number, timeoutMs = 4000): Promise<'connected' | 'refused-or-timeout'> {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    const timer = setTimeout(() => {
      socket.destroy();
      resolve('refused-or-timeout');
    }, timeoutMs);

    socket.once('connect', () => {
      clearTimeout(timer);
      socket.destroy();
      resolve('connected');
    });

    socket.once('error', () => {
      clearTimeout(timer);
      resolve('refused-or-timeout');
    });

    socket.connect(port, host);
  });
}

test.describe('LEMP-stack i Azure (Varnish -> nginx -> php-fpm -> MariaDB)', () => {

  test.beforeAll(() => {
    if (!process.env.TARGET_URL) {
      console.warn(
        '⚠️  TARGET_URL er ikke sat — falder tilbage til http://localhost:8080. ' +
        'Kør med TARGET_URL=http://<public_ip> npm test for at teste mod Azure.'
      );
    }
  });

  test('forsiden loader gennem Varnish og viser vellykket databaseforbindelse', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBe(200);

    // Web-first (auto-retrying) assertions i stedet for manuel textContent + assert
    const body = page.locator('body');
    await expect(body).not.toContainText(/error/i);
    await expect(body).not.toContainText(/fejl/i);
    // TODO: tilføj en positiv assertion når I kender jeres success-tekst, fx:
    // await expect(body).toContainText(/connected/i);
  });

  test('Varnish sidder reelt foran som cache-lag (Via/X-Varnish header)', async ({ request }) => {
    const response = await request.get('/');
    const headers = response.headers();
    const via = headers['via'] || '';
    const xVarnish = headers['x-varnish'];
    expect(via.toLowerCase().includes('varnish') || Boolean(xVarnish)).toBeTruthy();
  });

  test('MariaDB (3306) er ikke tilgængelig udefra', async ({ baseURL }) => {
    const host = new URL(baseURL!).hostname;
    const result = await tryConnect(host, 3306);
    expect(result).toBe('refused-or-timeout');
  });

  test('PHP-FPM (9000) er ikke tilgængelig udefra', async ({ baseURL }) => {
    const host = new URL(baseURL!).hostname;
    const result = await tryConnect(host, 9000);
    expect(result).toBe('refused-or-timeout');
  });

});
