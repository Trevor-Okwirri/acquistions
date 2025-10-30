import { slidingWindow } from '@arcjet/node';
import aj from '#config/arcjet.js';
import logger from '#config/logger.js';

const securityMiddleware = async (req, res, next) => {
  try {
    const role = req.user?.role || 'guest';

    let limit;
    let message;

    switch (role) {
      case 'admin':
        limit = 20;
        message =
          'Admin user rate limit exceeded (20 requests per minute). Slow down';
        break;
      case 'user':
        limit = 10;
        message =
          'User rate limit exceeded (10 requests per minute). Slow down';
        break;
      case 'guest':
      default:
        limit = 5;
        message =
          'Guest rate limit exceeded (5 requests per minute). Slow down';
        break;
    }

    const client = aj.withRule(
      slidingWindow({
        mode: 'LIVE',
        interval: '1m',
        max: limit,
        name: `${role}-rate-limit`,
      })
    );

    const decision = await client.protect(req);

    if (decision.isDenied() && decision.reason.isBot()) {
      logger.warn('Bot request blocked', {
        ip: req.ip,
        path: req.path,
        userAgent: req.get('User-Agent'),
      });

      return res
        .status(403)
        .send({
          error: 'Unauthorized',
          message: 'Automated requests are not allowed',
        });
    }

    if (decision.isDenied() && decision.reason.isShield()) {
      logger.warn('Shield blocked request', {
        ip: req.ip,
        path: req.path,
        userAgent: req.get('User-Agent'),
        method: req.method,
      });

      return res
        .status(403)
        .send({
          error: 'Unauthorized',
          message: 'Request blocked by security policy',
        });
    }

    if (decision.isDenied() && decision.reason.isRateLimit()) {
      logger.warn('Rate Limit exceeded', {
        ip: req.ip,
        path: req.path,
        userAgent: req.get('User-Agent'),
        method: req.method,
      });

      return res
        .status(403)
        .send({
          error: 'Unauthorized',
          message: 'Too many requests. ' + message,
        });
    }

    next();
  } catch (e) {
    console.error('Arcjet middleware error:', e);
    res
      .status(500)
      .json({
        error: 'Internal Server Error',
        message: 'Somethin went sout with security middleware',
      });
  }
};

export default securityMiddleware;
