import { useState } from "react";
import { Document, Page, pdfjs } from "react-pdf";
import { ChevronLeft, ChevronRight, X, ZoomIn, ZoomOut } from "lucide-react";
import { Button } from "./ui/button";
import { Card } from "./ui/card";
import "react-pdf/dist/esm/Page/AnnotationLayer.css";
import "react-pdf/dist/esm/Page/TextLayer.css";

// Set up PDF.js worker
pdfjs.GlobalWorkerOptions.workerSrc = `//unpkg.com/pdfjs-dist@${pdfjs.version}/build/pdf.worker.min.mjs`;

interface PDFViewerProps {
  file: File | null;
  currentPage: number;
  onPageChange: (page: number) => void;
  onClose: () => void;
}

export function PDFViewer({ file, currentPage, onPageChange, onClose }: PDFViewerProps) {
  const [numPages, setNumPages] = useState<number>(0);
  const [scale, setScale] = useState<number>(1.0);

  function onDocumentLoadSuccess({ numPages }: { numPages: number }) {
    setNumPages(numPages);
  }

  const handlePreviousPage = () => {
    if (currentPage > 1) {
      onPageChange(currentPage - 1);
    }
  };

  const handleNextPage = () => {
    if (currentPage < numPages) {
      onPageChange(currentPage + 1);
    }
  };

  const handleZoomIn = () => {
    setScale((prev) => Math.min(prev + 0.2, 2.0));
  };

  const handleZoomOut = () => {
    setScale((prev) => Math.max(prev - 0.2, 0.6));
  };

  if (!file) {
    return (
      <div className="flex items-center justify-center h-full bg-muted">
        <p className="text-muted-foreground">No PDF file selected</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-muted">
      {/* Header */}
      <div className="flex items-center justify-between p-3 bg-card border-b">
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" onClick={handleZoomOut}>
            <ZoomOut className="size-4" />
          </Button>
          <span className="text-sm min-w-12 text-center">{Math.round(scale * 100)}%</span>
          <Button variant="ghost" size="icon" onClick={handleZoomIn}>
            <ZoomIn className="size-4" />
          </Button>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-sm">
            {currentPage} / {numPages || "?"}
          </span>
        </div>

        <Button variant="ghost" size="icon" onClick={onClose}>
          <X className="size-4" />
        </Button>
      </div>

      {/* PDF Content */}
      <div className="flex-1 overflow-auto flex items-start justify-center p-4">
        <Card className="inline-block shadow-lg">
          <Document
            file={file}
            onLoadSuccess={onDocumentLoadSuccess}
            loading={
              <div className="flex items-center justify-center p-8">
                <p className="text-muted-foreground">Loading PDF...</p>
              </div>
            }
            error={
              <div className="flex items-center justify-center p-8">
                <p className="text-destructive">Failed to load PDF</p>
              </div>
            }
          >
            <Page
              pageNumber={currentPage}
              scale={scale}
              renderTextLayer={true}
              renderAnnotationLayer={true}
              loading={
                <div className="w-80 h-96 flex items-center justify-center bg-muted">
                  <p className="text-muted-foreground">Loading page...</p>
                </div>
              }
            />
          </Document>
        </Card>
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between p-3 bg-card border-t">
        <Button
          variant="outline"
          size="sm"
          onClick={handlePreviousPage}
          disabled={currentPage <= 1}
        >
          <ChevronLeft className="size-4 mr-1" />
          Previous
        </Button>

        <div className="flex gap-2">
          <input
            type="number"
            min={1}
            max={numPages}
            value={currentPage}
            onChange={(e) => {
              const page = parseInt(e.target.value);
              if (page >= 1 && page <= numPages) {
                onPageChange(page);
              }
            }}
            className="w-16 px-2 py-1 text-center border rounded"
          />
          <span className="text-sm flex items-center">of {numPages}</span>
        </div>

        <Button
          variant="outline"
          size="sm"
          onClick={handleNextPage}
          disabled={currentPage >= numPages}
        >
          Next
          <ChevronRight className="size-4 ml-1" />
        </Button>
      </div>
    </div>
  );
}
