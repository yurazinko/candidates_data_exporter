
import React, { useState, useEffect, useRef } from 'react';
import api from '../clients/api';
import { Button, CircularProgress, Box, Typography } from '@mui/material';

interface ExportResponse {
  filename: string;
  content: string;
}

type ExportStatus = 'loading' | 'success' | 'error' | 'preloading' | 'ready';

const STATUS_MAP: Record<ExportStatus, string> = {
  'preloading': 'Generating file in the background...',
  'ready': 'Ready to download!',
  'loading': 'Preparing download...',
  'success': 'Download complete!',
  'error': 'Error! Please try again later.'
};

const ExportPage: React.FC = () => {
  const [status, setStatus] = useState<ExportStatus>('preloading');
  const [error, setError] = useState<string | null>(null);

  const prefetchedExportRef = useRef<Promise<ExportResponse> | null>(null);

  const isProcessing = status === 'preloading' || status === 'loading';

  useEffect(() => {
    setStatus('preloading');
    setError(null);

    prefetchedExportRef.current = api.post<ExportResponse>('exports')
      .then(response => {
        setStatus('ready');
        return response.data;
      })
      .catch(err => {
        const msg = err.response?.data?.message || 'Failed to generate file during prefetch.';
        setError(msg);
        setStatus('error');
        return Promise.reject(err);
      });
  }, []);

  const downloadFile = (data: ExportResponse) => {
    const link = document.createElement('a');
    link.href = `data:text/csv;base64,${data.content}`;
    link.download = data.filename || 'candidates_export.csv';
    link.click();
  };

  const handleExport = async () => {
    setStatus('loading');
    setError(null);

    try {
      const data = await prefetchedExportRef.current;

      downloadFile(data);

      setStatus('success');
    } catch (err) {
      console.error("Download failed:", err);
      const msg = err.response?.data?.message || 'Export failed during download attempt.';
      setError(msg);
      setStatus('error');
    }
  };


  return (
    <Box sx={{ p: 3, border: '1px solid #ddd', borderRadius: '8px', maxWidth: 400, mx: 'auto', mt: 5 }}>
      <Typography variant="h5" gutterBottom>
        Export Candidates Data
      </Typography>
      <Typography variant="body1" sx={{ mt: 2 }}>
        Status:
        <Typography component="span" fontWeight="bold" sx={{ ml: 1 }}>
          {STATUS_MAP[status]}
        </Typography>
      </Typography>

      {isProcessing && (
        <Box sx={{ display: 'flex', alignItems: 'center', mt: 2, color: 'primary.main' }}>
          <CircularProgress size={24} sx={{ mr: 2 }} />
          <Typography variant="body1">
            Generation in progress...
          </Typography>
        </Box>
      )}

      <Button
        variant="contained"
        onClick={handleExport}
        disabled={isProcessing}
        color={status === 'success' ? "success" : "primary"}
        sx={{ mt: 3 }}
      >
        Download
      </Button>

      {error && (
        <Typography color="error" sx={{ mt: 2 }}>
          Error: {error}
        </Typography>
      )}
    </Box>
  );
};

export default ExportPage;
