const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory data store
let items = [
  { id: 1, name: 'Kubernetes', type: 'Orchestrator' },
  { id: 2, name: 'Docker', type: 'Container Runtime' },
  { id: 3, name: 'Microservices', type: 'Architecture Pattern' }
];

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'backend-api'
  });
});

// Get all items
app.get('/api/items', (req, res) => {
  res.json({
    success: true,
    count: items.length,
    data: items
  });
});

// Get single item
app.get('/api/items/:id', (req, res) => {
  const item = items.find(i => i.id === parseInt(req.params.id));
  if (!item) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }
  res.json({ success: true, data: item });
});

// Create new item
app.post('/api/items', (req, res) => {
  const newItem = {
    id: items.length + 1,
    name: req.body.name || 'New Item',
    type: req.body.type || 'Unknown'
  };
  items.push(newItem);
  res.status(201).json({ success: true, data: newItem });
});

// Delete item
app.delete('/api/items/:id', (req, res) => {
  const index = items.findIndex(i => i.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }
  items.splice(index, 1);
  res.json({ success: true, message: 'Item deleted' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend API running on port ${PORT}`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});
