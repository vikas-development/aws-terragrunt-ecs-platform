const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Enterprise Multi-Environment Deployment Platform - Sample App',
    environment: process.env.ENVIRONMENT || 'unknown',
  });
});

// Health check endpoint — used by the ALB target group (Phase 5) and by
// the CI/CD smoke tests (Phase 10) to confirm the container is actually
// serving traffic, not just running.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});
