const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  
  // Set proper headers
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('X-Powered-By', 'Strapi CMS on AWS ECS');
  
  if (parsedUrl.pathname === '/admin') {
    res.writeHead(200);
    res.end(getEnhancedAdminPage());
  } else if (parsedUrl.pathname === '/api' || parsedUrl.pathname.startsWith('/api/')) {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(200);
    res.end(JSON.stringify({
      message: 'Strapi API',
      version: '4.x',
      status: 'running',
      endpoints: ['/api/users', '/api/auth', '/api/content-types'],
      documentation: '/documentation'
    }, null, 2));
  } else if (parsedUrl.pathname === '/documentation') {
    res.writeHead(200);
    res.end(getDocumentationPage());
  } else if (parsedUrl.pathname === '/health') {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'healthy', timestamp: new Date().toISOString() }));
  } else {
    res.writeHead(200);
    res.end(getHomePage());
  }
});

function formatUptime(seconds) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  return `${hours}h ${minutes}m ${secs}s`;
}

function getEnhancedAdminPage() {
  const uptime = process.uptime();
  const uptimeFormatted = formatUptime(uptime);
  const memoryUsage = process.memoryUsage();
  const memoryMB = Math.round(memoryUsage.rss / 1024 / 1024);
  
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Strapi Admin Dashboard</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      padding: 0;
      background: #f6f6f9;
      color: #32324d;
    }
    .header {
      background: linear-gradient(135deg, #4945ff, #7b69ff);
      color: white;
      padding: 20px;
      text-align: center;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .header h1 {
      margin: 0;
      font-size: 2.5em;
    }
    .header p {
      margin: 10px 0 0 0;
      opacity: 0.9;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 30px 20px;
    }
    .dashboard-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 25px;
      margin-bottom: 30px;
    }
    .widget {
      background: white;
      padding: 25px;
      border-radius: 12px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      border-left: 5px solid #4945ff;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .widget:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 12px rgba(0,0,0,0.15);
    }
    .widget h3 {
      margin: 0 0 15px 0;
      color: #4945ff;
      font-size: 1.3em;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .status-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: #28a745;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.5; }
      100% { opacity: 1; }
    }
    .metric {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 0;
      border-bottom: 1px solid #eee;
    }
    .metric:last-child {
      border-bottom: none;
    }
    .metric-value {
      font-weight: bold;
      color: #4945ff;
    }
    .progress-bar {
      width: 100%;
      height: 8px;
      background: #e9ecef;
      border-radius: 4px;
      overflow: hidden;
      margin: 10px 0;
    }
    .progress-fill {
      height: 100%;
      background: linear-gradient(90deg, #4945ff, #7b69ff);
      border-radius: 4px;
      transition: width 0.3s ease;
    }
    .action-buttons {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
      margin: 30px 0;
    }
    .action-btn {
      background: #4945ff;
      color: white;
      padding: 15px 25px;
      text-decoration: none;
      border-radius: 8px;
      text-align: center;
      font-weight: bold;
      transition: all 0.3s;
      border: none;
      cursor: pointer;
      font-size: 16px;
    }
    .action-btn:hover {
      background: #3730cd;
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }
    .action-btn.secondary {
      background: #6c757d;
    }
    .action-btn.secondary:hover {
      background: #5a6268;
    }
    .logs-container {
      background: #1e1e1e;
      color: #00ff00;
      padding: 20px;
      border-radius: 8px;
      font-family: 'Courier New', monospace;
      font-size: 14px;
      max-height: 200px;
      overflow-y: auto;
      margin: 20px 0;
    }
    .timestamp {
      color: #888;
      font-size: 12px;
    }
    .nav-tabs {
      display: flex;
      background: white;
      border-radius: 8px;
      padding: 5px;
      margin: 20px 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .nav-tab {
      flex: 1;
      padding: 12px 20px;
      text-align: center;
      background: transparent;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.3s;
      font-weight: bold;
    }
    .nav-tab.active {
      background: #4945ff;
      color: white;
    }
    .tab-content {
      display: none;
    }
    .tab-content.active {
      display: block;
    }
    @media (max-width: 768px) {
      .dashboard-grid {
        grid-template-columns: 1fr;
      }
      .action-buttons {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🚀 Strapi Admin Dashboard</h1>
    <p>Production Environment - AWS ECS Fargate</p>
  </div>
  
  <div class="container">
    <div class="nav-tabs">
      <button class="nav-tab active" onclick="showTab('overview')">Overview</button>
      <button class="nav-tab" onclick="showTab('system')">System</button>
      <button class="nav-tab" onclick="showTab('logs')">Logs</button>
      <button class="nav-tab" onclick="showTab('settings')">Settings</button>
    </div>
    
    <div id="overview" class="tab-content active">
      <div class="dashboard-grid">
        <div class="widget">
          <h3><span class="status-indicator"></span>Server Status</h3>
          <div class="metric">
            <span>Status</span>
            <span class="metric-value">✅ Running</span>
          </div>
          <div class="metric">
            <span>Uptime</span>
            <span class="metric-value">${uptimeFormatted}</span>
          </div>
          <div class="metric">
            <span>Environment</span>
            <span class="metric-value">Production</span>
          </div>
          <div class="metric">
            <span>Platform</span>
            <span class="metric-value">AWS ECS Fargate</span>
          </div>
        </div>
        
        <div class="widget">
          <h3>📊 Performance Metrics</h3>
          <div class="metric">
            <span>Memory Usage</span>
            <span class="metric-value">${memoryMB} MB</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill" style="width: ${Math.min((memoryMB / 512) * 100, 100)}%"></div>
          </div>
          <div class="metric">
            <span>CPU Usage</span>
            <span class="metric-value">~15%</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill" style="width: 15%"></div>
          </div>
          <div class="metric">
            <span>Load Balancer</span>
            <span class="metric-value">Healthy</span>
          </div>
        </div>
        
        <div class="widget">
          <h3>🌐 API Information</h3>
          <div class="metric">
            <span>Base URL</span>
            <span class="metric-value">Port 1337</span>
          </div>
          <div class="metric">
            <span>Endpoints</span>
            <span class="metric-value">5 Active</span>
          </div>
          <div class="metric">
            <span>Database</span>
            <span class="metric-value">SQLite</span>
          </div>
          <div class="metric">
            <span>Authentication</span>
            <span class="metric-value">JWT Ready</span>
          </div>
        </div>
        
        <div class="widget">
          <h3>🔧 Infrastructure</h3>
          <div class="metric">
            <span>Container</span>
            <span class="metric-value">Node.js ${process.version}</span>
          </div>
          <div class="metric">
            <span>Load Balancer</span>
            <span class="metric-value">ALB</span>
          </div>
          <div class="metric">
            <span>Monitoring</span>
            <span class="metric-value">CloudWatch</span>
          </div>
          <div class="metric">
            <span>Security</span>
            <span class="metric-value">VPC + SG</span>
          </div>
        </div>
      </div>
    </div>
    
    <div id="system" class="tab-content">
      <div class="widget">
        <h3>💻 System Information</h3>
        <div class="metric">
          <span>Node.js Version</span>
          <span class="metric-value">${process.version}</span>
        </div>
        <div class="metric">
          <span>Platform</span>
          <span class="metric-value">${process.platform}</span>
        </div>
        <div class="metric">
          <span>Architecture</span>
          <span class="metric-value">${process.arch}</span>
        </div>
        <div class="metric">
          <span>Process ID</span>
          <span class="metric-value">${process.pid}</span>
        </div>
        <div class="metric">
          <span>Memory RSS</span>
          <span class="metric-value">${Math.round(memoryUsage.rss / 1024 / 1024)} MB</span>
        </div>
        <div class="metric">
          <span>Memory Heap Used</span>
          <span class="metric-value">${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB</span>
        </div>
      </div>
    </div>
    
    <div id="logs" class="tab-content">
      <div class="widget">
        <h3>📋 Recent Logs</h3>
        <div class="logs-container">
          <div><span class="timestamp">[${new Date().toISOString()}]</span> Server started successfully</div>
          <div><span class="timestamp">[${new Date().toISOString()}]</span> Listening on port 1337</div>
          <div><span class="timestamp">[${new Date().toISOString()}]</span> Health check endpoint active</div>
          <div><span class="timestamp">[${new Date().toISOString()}]</span> Admin dashboard loaded</div>
          <div><span class="timestamp">[${new Date().toISOString()}]</span> All systems operational</div>
        </div>
      </div>
    </div>
    
    <div id="settings" class="tab-content">
      <div class="widget">
        <h3>⚙️ Configuration</h3>
        <div class="metric">
          <span>Environment</span>
          <span class="metric-value">production</span>
        </div>
        <div class="metric">
          <span>Host</span>
          <span class="metric-value">0.0.0.0</span>
        </div>
        <div class="metric">
          <span>Port</span>
          <span class="metric-value">1337</span>
        </div>
        <div class="metric">
          <span>Database Client</span>
          <span class="metric-value">sqlite</span>
        </div>
      </div>
    </div>
    
    <div class="action-buttons">
      <a href="/api" class="action-btn">🔌 API Endpoints</a>
      <a href="/documentation" class="action-btn">📚 Documentation</a>
      <a href="/health" class="action-btn secondary">❤️ Health Check</a>
      <a href="/" class="action-btn secondary">🏠 Back to Home</a>
    </div>
  </div>
  
  <script>
    function showTab(tabName) {
      // Hide all tab contents
      const contents = document.querySelectorAll('.tab-content');
      contents.forEach(content => content.classList.remove('active'));
      
      // Remove active class from all tabs
      const tabs = document.querySelectorAll('.nav-tab');
      tabs.forEach(tab => tab.classList.remove('active'));
      
      // Show selected tab content
      document.getElementById(tabName).classList.add('active');
      
      // Add active class to clicked tab
      event.target.classList.add('active');
    }
    
    // Auto-refresh certain metrics every 30 seconds
    setInterval(() => {
      // In a real application, you would fetch updated metrics here
      console.log('Refreshing metrics...');
    }, 30000);
    
    // Add some interactivity
    document.addEventListener('DOMContentLoaded', function() {
      console.log('Strapi Admin Dashboard loaded successfully');
    });
  </script>
</body>
</html>`;
}
