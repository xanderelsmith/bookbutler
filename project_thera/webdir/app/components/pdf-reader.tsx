import { X, ChevronLeft, ChevronRight, Bookmark, Settings, ZoomIn, ZoomOut } from "lucide-react";
import { Button } from "./ui/button";
import { Progress } from "./ui/progress";
import { useState } from "react";
import { Slider } from "./ui/slider";

interface PdfReaderProps {
  bookTitle: string;
  author: string;
  currentPage: number;
  totalPages: number;
  progress: number;
  onClose: () => void;
  onPageChange: (page: number) => void;
}

export function PdfReader({
  bookTitle,
  author,
  currentPage,
  totalPages,
  progress,
  onClose,
  onPageChange,
}: PdfReaderProps) {
  const [showControls, setShowControls] = useState(true);
  const [brightness, setBrightness] = useState(100);
  const [fontSize, setFontSize] = useState(16);

  const handlePrevPage = () => {
    if (currentPage > 1) {
      onPageChange(currentPage - 1);
    }
  };

  const handleNextPage = () => {
    if (currentPage < totalPages) {
      onPageChange(currentPage + 1);
    }
  };

  return (
    <div className="fixed inset-0 bg-white z-50 flex flex-col">
      {/* Header */}
      {showControls && (
        <div className="bg-white border-b border-gray-200 p-4 animate-in slide-in-from-top">
          <div className="flex items-center justify-between mb-2">
            <Button variant="ghost" size="icon" onClick={onClose}>
              <X className="size-5" />
            </Button>
            <div className="flex gap-2">
              <Button variant="ghost" size="icon">
                <Bookmark className="size-5" />
              </Button>
              <Button variant="ghost" size="icon">
                <Settings className="size-5" />
              </Button>
            </div>
          </div>
          <div className="text-center">
            <h2 className="font-semibold text-gray-900 text-sm truncate">{bookTitle}</h2>
            <p className="text-xs text-gray-600">{author}</p>
          </div>
          <div className="mt-3">
            <Progress value={progress} className="h-1" />
            <div className="flex justify-between text-xs text-gray-600 mt-1">
              <span>Page {currentPage} of {totalPages}</span>
              <span>{progress}%</span>
            </div>
          </div>
        </div>
      )}

      {/* PDF Content Area */}
      <div 
        className="flex-1 overflow-auto bg-gray-50 p-4"
        onClick={() => setShowControls(!showControls)}
        style={{ 
          filter: `brightness(${brightness}%)`,
          fontSize: `${fontSize}px`,
          lineHeight: 1.6
        }}
      >
        <div className="max-w-2xl mx-auto bg-white shadow-lg p-8 min-h-full">
          {/* Simulated PDF Content */}
          <h1 className="text-2xl font-bold mb-4">Chapter {Math.floor((currentPage - 1) / 15) + 1}</h1>
          <p className="mb-4 text-gray-700">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
          </p>
          <p className="mb-4 text-gray-700">
            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
          </p>
          <p className="mb-4 text-gray-700">
            Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.
          </p>
          <p className="mb-4 text-gray-700">
            Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.
          </p>
          <p className="text-gray-700">
            Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.
          </p>
          
          <div className="mt-8 pt-4 border-t border-gray-200 text-center text-sm text-gray-500">
            Page {currentPage}
          </div>
        </div>
      </div>

      {/* Bottom Controls */}
      {showControls && (
        <div className="bg-white border-t border-gray-200 p-4 animate-in slide-in-from-bottom">
          <div className="flex items-center justify-between gap-4 mb-3">
            <Button 
              variant="outline" 
              size="icon"
              onClick={handlePrevPage}
              disabled={currentPage === 1}
            >
              <ChevronLeft className="size-5" />
            </Button>
            
            <div className="flex-1">
              <input
                type="range"
                min="1"
                max={totalPages}
                value={currentPage}
                onChange={(e) => onPageChange(parseInt(e.target.value))}
                className="w-full"
              />
            </div>

            <Button 
              variant="outline" 
              size="icon"
              onClick={handleNextPage}
              disabled={currentPage === totalPages}
            >
              <ChevronRight className="size-5" />
            </Button>
          </div>

          <div className="flex items-center justify-center gap-6">
            <div className="flex items-center gap-2">
              <ZoomOut className="size-4 text-gray-600" />
              <span className="text-xs text-gray-600">A</span>
            </div>
            <Slider
              value={[fontSize]}
              onValueChange={(value) => setFontSize(value[0])}
              min={12}
              max={24}
              step={1}
              className="w-24"
            />
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-gray-600">A</span>
              <ZoomIn className="size-4 text-gray-600" />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
